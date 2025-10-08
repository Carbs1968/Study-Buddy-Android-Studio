/* eslint-disable max-len, object-curly-spacing, operator-linebreak */

import os from "os";
import path from "path";
import { promises as fs } from "fs";
import { spawn } from "child_process";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import OpenAI, { toFile } from "openai";

initializeApp();

const TAG = "StudyBuddy";
const TRANSCRIPTS_DIR = "transcripts";

/**
 * Parse a Firebase Storage download URL into an object path like
 * "recordings/foo.m4a".
 *
 * @param {string} url The Firebase Storage download URL.
 * @return {string|null} The decoded object path, or null if it can’t be parsed.
 */
function parseStoragePath(url: string): string | null {
  try {
    const i = url.indexOf("/o/");
    if (i < 0) return null;
    const rest = url.substring(i + 3);
    const end = rest.indexOf("?");
    const encoded = end >= 0 ? rest.substring(0, end) : rest;
    const decoded = decodeURIComponent(encoded);
    return decoded || null;
  } catch {
    return null;
  }
}

/**
 * Save transcript text to
 *   gs://<default-bucket>/transcripts/<id>.txt
 *
 * @param {string} id Recording document ID (used as filename).
 * @param {string} text Transcript text to write.
 * @return {Promise<string>} Resolves to the object path that was written.
 */
async function saveTranscriptText(id: string, text: string): Promise<string> {
  const bucket = getStorage().bucket();
  const objectPath = `${TRANSCRIPTS_DIR}/${id}.txt`;
  const file = bucket.file(objectPath);
  await file.save(text, {
    resumable: false,
    contentType: "text/plain; charset=utf-8",
    metadata: { cacheControl: "no-store" },
  });
  return objectPath;
}

/** Lazily resolve ffmpeg binary path from ffmpeg-static (optional). */
let ffmpegPath: string | null = null;
/**
 * Resolve the ffmpeg path once; if unavailable, return null (we’ll fall back).
 * @return {Promise<string|null>} ffmpeg binary path or null if not installed.
 */
async function getFfmpegPath(): Promise<string | null> {
  if (ffmpegPath !== null) return ffmpegPath;
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const mod = await import("ffmpeg-static");
    // some bundlers export default, some export the path directly
    ffmpegPath =
      (mod as unknown as { default?: string }).default ||
      ((mod as unknown) as string);
    logger.info(
      JSON.stringify({ tag: TAG, message: "ffmpeg-static resolved", ffmpegPath }),
    );
    return ffmpegPath;
  } catch (e) {
    logger.warn(
      JSON.stringify({
        tag: TAG,
        message: "ffmpeg-static not available; will fall back to original audio",
        error: (e as { message?: string })?.message || String(e),
      }),
    );
    ffmpegPath = null;
    return null;
  }
}

/**
 * Convert an input audio file (m4a/aac) into 16 kHz mono WAV in /tmp.
 *
 * @param {string} inputPath Absolute path to the source audio file.
 * @return {Promise<string>} Absolute path to the converted WAV file.
 */
async function convertToWav16kMono(inputPath: string): Promise<string> {
  const bin = await getFfmpegPath();
  if (!bin) {
    throw new Error("ffmpeg binary not found (ffmpeg-static).");
  }
  const outPath = path.join(
    os.tmpdir(),
    `${path.basename(inputPath, path.extname(inputPath))}.16kmono.wav`,
  );

  const args = [
    "-y",
    "-i",
    inputPath,
    "-ac",
    "1", // mono
    "-ar",
    "16000", // 16kHz
    "-sample_fmt",
    "s16", // 16-bit PCM
    outPath,
  ];

  await new Promise<void>((resolve, reject) => {
    const p = spawn(bin, args, { stdio: "inherit" });
    p.on("error", reject);
    p.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exited with code ${code}`));
    });
  });

  return outPath;
}

/**
 * Segment an audio file into N pieces using ffmpeg's segment muxer.
 * Returns absolute paths of the produced segment files (same dir as input).
 * If ffmpeg is unavailable, throws; caller should fall back.
 *
 * @param {string} inputPath Absolute path to the source audio file.
 * @param {number} [segmentSeconds=600] Segment duration in seconds (default 10 min).
 * @return {Promise<string[]>} Absolute paths of the produced segment files.
 */
async function segmentAudio(inputPath: string, segmentSeconds = 600): Promise<string[]> {
  const bin = await getFfmpegPath();
  if (!bin) throw new Error("ffmpeg not available for segmentation");
  const dir = path.dirname(inputPath);
  const base = path.basename(inputPath, path.extname(inputPath));
  const outPattern = path.join(dir, `${base}.part-%03d${path.extname(inputPath)}`);

  const args = [
    "-y",
    "-i", inputPath,
    "-f", "segment",
    "-segment_time", `${segmentSeconds}`,
    "-reset_timestamps", "1",
    outPattern,
  ];

  await new Promise<void>((resolve, reject) => {
    const p = spawn(bin, args, { stdio: "inherit" });
    p.on("error", reject);
    p.on("close", (code) => code === 0 ? resolve() : reject(new Error(`ffmpeg segment exited ${code}`)));
  });

  // Collect produced files (conservative: list part-000..part-999)
  const outFiles: string[] = [];
  for (let i = 0; i < 1000; i++) {
    const pth = path.join(dir, `${base}.part-${i.toString().padStart(3, "0")}${path.extname(inputPath)}`);
    try {
      // eslint-disable-next-line no-await-in-loop
      const st = await fs.stat(pth);
      if (st.isFile() && st.size > 0) outFiles.push(pth);
    } catch {
      break;
    }
  }
  return outFiles;
}

/**
 * Transcribe a single audio chunk with OpenAI (expects a small chunk).
 *
 * @param {OpenAI} openai An initialized OpenAI client.
 * @param {Buffer} bytes Audio bytes for this chunk.
 * @param {string} name A filename for the upload (helps OpenAI determine type).
 * @return {Promise<string>} Transcript text for this chunk.
 */
async function transcribeChunk(openai: OpenAI, bytes: Buffer, name: string): Promise<string> {
  const r = await openai.audio.transcriptions.create({
    model: "gpt-4o-mini-transcribe",
    file: await toFile(bytes, name),
  });
  return typeof r === "string" ? r : (r.text || "");
}

/**
 * Callable used by the app to fetch the (private) transcript text.
 * Requires a signed-in user; verifies the user owns the recording.
 * data: { recordingId: string }
 */
export const getTranscriptText = onCall(
  { cors: true, secrets: ["OPENAI_API_KEY"] },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }

    const recordingId = (req.data?.recordingId as string) || "";
    if (!recordingId) {
      throw new HttpsError("invalid-argument", "recordingId is required");
    }

    // Verify ownership in Firestore
    const db = getFirestore();
    const recSnap = await db.collection("recordings").doc(recordingId).get();
    if (!recSnap.exists) {
      throw new HttpsError("not-found", "Recording not found.");
    }
    const rec = recSnap.data() || {};
    if (rec.uid !== uid) {
      throw new HttpsError("permission-denied", "Not your recording.");
    }

    // Read private transcript object
    const objectPath = `${TRANSCRIPTS_DIR}/${recordingId}.txt`;
    const bucket = getStorage().bucket();
    const file = bucket.file(objectPath);
    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("not-found", "Transcript not found for this recording.");
    }

    const [buf] = await file.download();
    const text = buf.toString("utf8");
    return { text };
  },
);

/**
 * Callable used by the app to fetch an AI job's JSON output.
 * Requires a signed-in user; verifies the user owns the recording.
 * data: { recordingId: string, type: "summary"|"notes"|"quiz" }
 */
export const getAiJobOutput = onCall(
  { cors: true, secrets: ["OPENAI_API_KEY"] },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }

    const recordingId = (req.data?.recordingId as string) || "";
    const type = (req.data?.type as string) || "";
    if (!recordingId) {
      throw new HttpsError("invalid-argument", "recordingId is required");
    }
    if (!["summary", "notes", "quiz"].includes(type)) {
      throw new HttpsError("invalid-argument", "type must be summary|notes|quiz");
    }

    // Verify ownership in Firestore
    const db = getFirestore();
    const recRef = db.collection("recordings").doc(recordingId);
    const recSnap = await recRef.get();
    if (!recSnap.exists) {
      throw new HttpsError("not-found", "Recording not found.");
    }
    const rec = (recSnap.data() || {}) as { uid?: string } & Record<string, unknown>;
    if (rec.uid !== uid) {
      throw new HttpsError("permission-denied", "Not your recording.");
    }

    // Path stored on the recording, e.g. aiSummaryPath / aiNotesPath / aiQuizPath
    const cap = type[0].toUpperCase() + type.slice(1);
    const pathField = `ai${cap}Path`;
    const objectPath = (rec[pathField] as string | undefined) || "";
    if (!objectPath) {
      throw new HttpsError("not-found", `No ${type} output available.`);
    }

    // Download JSON from Storage and return parsed payload
    const bucket = getStorage().bucket();
    const file = bucket.file(objectPath);
    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("not-found", `${type} output file not found in Storage.`);
    }

    const [buf] = await file.download();
    let data: unknown;
    try {
      data = JSON.parse(buf.toString("utf8"));
    } catch {
      // Return raw string if it wasn't valid JSON for some reason
      data = { raw: buf.toString("utf8") };
    }

    // Include preview if stored
    const previewField = `ai${cap}Preview`;
    const preview = (rec[previewField] as string | undefined) || null;

    return { type, recordingId, path: objectPath, preview, data };
  },
);

/**
 * Firestore trigger: when a recording moves to "pending", we:
 * 1) set status to "processing"
 * 2) download audio from Storage
 * 3) (attempt) convert to 16k mono WAV using ffmpeg (fallback to original on failure)
 * 4) transcribe via OpenAI (now chunked for long lectures, with fallback)
 * 5) save transcript to Storage
 * 6) update Firestore with preview + status "done"
 */
export const onTranscriptRequested = onDocumentUpdated(
  {
    document: "recordings/{id}",
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["OPENAI_API_KEY"],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const before = snap.before.data() || {};
    const after = snap.after.data() || {};

    const prev = (before.transcriptStatus || "none") as string;
    const curr = (after.transcriptStatus || "none") as string;
    if (prev === curr) return;
    if (curr !== "pending") return;

    const docId = snap.after.id;
    const filename = (after.filename || after.name || "audio.m4a") as string;

    // Resolve Storage object path
    let objectPath = (after.storagePath || "") as string;
    if (!objectPath) {
      const storageUrl = (after.storageUrl || "") as string;
      objectPath = parseStoragePath(storageUrl) || "";
    }
    if (!objectPath) {
      objectPath = `recordings/${filename}`;
    }

    // Flip to processing immediately (server time)
    await snap.after.ref.update({
      transcriptStatus: "processing",
      transcriptLastUpdated: FieldValue.serverTimestamp(),
    });

    logger.info(
      JSON.stringify({
        tag: `${TAG}:onTranscriptRequested`,
        message: "Pending → processing",
        docId,
        hasStorageUrl: !!after.storageUrl,
        hasDriveFileId: !!after.driveFileId,
        objectPath,
      }),
    );

    // Download audio from Storage
    const bucket = getStorage().bucket();
    const audioFile = bucket.file(objectPath);
    const [exists] = await audioFile.exists();
    if (!exists) {
      await snap.after.ref.update({
        transcriptStatus: "error",
        transcriptError: "Audio file not found in Storage.",
        transcriptLastUpdated: FieldValue.serverTimestamp(),
      });
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onTranscriptRequested`,
          docId,
          objectPath,
          error: "Audio not found",
        }),
      );
      return;
    }

    const [audioBytes] = await audioFile.download();
    logger.info(
      JSON.stringify({
        tag: `${TAG}:onTranscriptRequested`,
        docId,
        message: "Downloaded audio",
        bytes: audioBytes.length,
      }),
    );

    // Prepare local temp file
    const tmpIn = path.join(os.tmpdir(), `${docId}.m4a`);
    await fs.writeFile(tmpIn, audioBytes);

    // Attempt segmentation into ~10-minute parts. If segmentation fails or yields no parts,
    // fall back to the original single-file path list with just [tmpIn].
    let parts: string[] = [];
    try {
      parts = await segmentAudio(tmpIn, 600); // 600s = 10 minutes
      if (parts.length === 0) parts = [tmpIn];
      logger.info(JSON.stringify({ tag: `${TAG}:onTranscriptRequested`, docId, message: "Segmentation complete", parts: parts.length }));
    } catch (e) {
      const errMsg = (e as { message?: string })?.message || String(e);
      logger.warn(JSON.stringify({ tag: `${TAG}:onTranscriptRequested`, docId, message: "Segmentation unavailable; using single-shot", error: errMsg }));
      parts = [tmpIn];
    }

    // Transcribe each part sequentially; convert each to 16k mono WAV to be safe; if conversion fails, use original bytes.
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    let transcriptText = "";

    for (let idx = 0; idx < parts.length; idx++) {
      const partPath = parts[idx];
      let bytesForOpenAI: Buffer;
      let nameForOpenAI = path.basename(partPath);
      try {
        const wavPath = await convertToWav16kMono(partPath);
        const wavBytes = await fs.readFile(wavPath);
        bytesForOpenAI = wavBytes;
        nameForOpenAI = path.basename(wavPath);
        await fs.rm(wavPath, { force: true });
      } catch (convErr) {
        const fallbackBytes = await fs.readFile(partPath);
        bytesForOpenAI = fallbackBytes;
      }

      // Add simple time markers based on segment index (10 min windows)
      const startSec = idx * 600;
      const endSec = (idx + 1) * 600;
      const fmt = (s: number) => {
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const hh = h > 0 ? `${h.toString().padStart(2, "0")}:` : "";
        return `${hh}${m.toString().padStart(2, "0")}:${sec.toString().padStart(2, "0")}`;
      };

      try {
        const piece = await transcribeChunk(openai, bytesForOpenAI, nameForOpenAI);
        transcriptText += `\n[${fmt(startSec)}–${fmt(endSec)}]\n${piece}\n`;
        logger.info(JSON.stringify({ tag: `${TAG}:onTranscriptRequested`, docId, message: "Chunk transcribed", index: idx, chars: piece.length }));
      } catch (err) {
        const msg =
          (err as { message?: string })?.message ||
          `OpenAI transcription failed for chunk ${idx}`;
        await snap.after.ref.update({
          transcriptStatus: "error",
          transcriptError: msg,
          transcriptLastUpdated: FieldValue.serverTimestamp(),
        });
        logger.error(JSON.stringify({ tag: `${TAG}:onTranscriptRequested`, docId, error: msg, chunk: idx }));
        // cleanup temp files before returning
        try {
          for (const p of parts) await fs.rm(p, { force: true });
          await fs.rm(tmpIn, { force: true });
        } catch {
          // noop: best-effort cleanup
        }
        return;
      }
    }

    // Cleanup temp pieces
    try {
      for (const p of parts) {
        if (p !== tmpIn) await fs.rm(p, { force: true });
      }
      await fs.rm(tmpIn, { force: true });
    } catch {
      // noop: best-effort cleanup
    }

    // Save full transcript and update Firestore (single canonical path)
    const objectPathTxt = await saveTranscriptText(docId, transcriptText);
    const preview = transcriptText.substring(0, 500);

    await snap.after.ref.update({
      transcriptStatus: "done",
      transcriptLastUpdated: FieldValue.serverTimestamp(),
      transcriptPreview: preview,
      transcriptPath: objectPathTxt,
    });

    logger.info(
      JSON.stringify({
        tag: `${TAG}:onTranscriptRequested`,
        docId,
        message: "Saved transcript & updated doc",
        transcriptPath: objectPathTxt,
      }),
    );
  },
);

/** ---------- AI JOBS (Summary / Notes / Quiz) ---------- */

/**
 * Read transcript text from Storage for a recording.
 * @param {string} recordingId recording document id
 * @return {Promise<string>} transcript text
 */
async function readTranscriptText(recordingId: string): Promise<string> {
  const bucket = getStorage().bucket();
  const file = bucket.file(`${TRANSCRIPTS_DIR}/${recordingId}.txt`);
  const [exists] = await file.exists();
  if (!exists) {
    throw new Error("Transcript file not found.");
  }
  const [buf] = await file.download();
  return buf.toString("utf8");
}

/**
 * Remove markdown code fences and parse JSON safely.
 * @param {string} raw model output
 * @return {any} parsed object
 */
function safeParseJson(raw: string): unknown {
  let s = raw.trim();
  if (s.startsWith("```")) {
    const first = s.indexOf("\n");
    const lastFence = s.lastIndexOf("```");
    if (first >= 0 && lastFence > first) {
      s = s.substring(first + 1, lastFence).trim();
    }
  }
  return JSON.parse(s);
}

/**
 * Build a strict system prompt that forbids hallucinations and enforces JSON.
 * @param {string} jobType "summary"|"notes"|"quiz"
 * @return {string} system message
 */
function systemPrompt(jobType: "summary" | "notes" | "quiz"): string {
  return [
    "You are an extractive academic assistant.",
    "Use ONLY the provided transcript text.",
    "If the transcript lacks information, set the corresponding JSON field to null or an empty list.",
    "Never invent facts, names, equations, or examples not present in the transcript.",
    "Output MUST be a single valid JSON object that conforms to the requested schema.",
    `Task: ${jobType}`,
  ].join(" ");
}

/**
 * Build the user prompt that includes the transcript and the schema for the job.
 * @param {string} jobType "summary"|"notes"|"quiz"
 * @param {string} transcript plain transcript text
 * @param {Record<string, unknown>} _recMeta minimal recording metadata
 * @return {string} user content
 */
function userPrompt(
  jobType: "summary" | "notes" | "quiz",
  transcript: string,
  _recMeta: Record<string, unknown>, // kept for future use; underscore silences unused-var
): string {
  void _recMeta;
  const common = [
    "TRANSCRIPT (verbatim):",
    "<<<TRANSCRIPT_START>>>",
    transcript,
    "<<<TRANSCRIPT_END>>>",
    "",
  ].join("\n");

  if (jobType === "summary") {
    return [
      common,
      "Return JSON with schema:",
      `{
  "title": string|null,           // from transcript, or null
  "abstract": string,             // 3–6 sentences, extractive/faithful
  "key_points": string[],         // 5–12 bullets from transcript
  "terms": string[]               // glossary terms if explicitly present
}`,
    ].join("\n");
  }

  if (jobType === "notes") {
    return [
      common,
      "Return JSON with schema:",
      `{
  "outline": [
    {
      "heading": string,
      "bullets": string[]          // bullet points quoted or paraphrased faithfully
    }
  ],
  "equations": string[],          // equations exactly as they appear, or []
  "references": string[]          // sources/figures mentioned explicitly, or []
}`,
    ].join("\n");
  }

  // quiz
  return [
    common,
    "Return JSON with schema:",
    `{
  "questions": [
    {
      "type": "mcq"|"short"|"true_false",
      "prompt": string,           // faithful to transcript
      "choices": string[]|null,   // only for mcq
      "answer": string|boolean,   // ground-truth strictly from transcript
      "rationale": string|null    // cite wording from transcript if helpful
    }
  ]
}`,
  ].join("\n");
}

/**
 * Produce a short preview string for UI from the JSON payload.
 * @param {"summary"|"notes"|"quiz"} jobType type
 * @param {unknown} data parsed json
 * @return {string} preview
 */
function makePreview(jobType: "summary" | "notes" | "quiz", data: unknown): string {
  try {
    if (jobType === "summary") {
      const d = data as { abstract?: string; key_points?: string[] };
      const abs = (d.abstract || "").toString();
      return abs.substring(0, 200);
    }
    if (jobType === "notes") {
      const d = data as { outline?: Array<{ heading?: string; bullets?: string[] }> };
      const n = (d.outline || []).length;
      return `Outline sections: ${n}`;
    }
    const d = data as { questions?: unknown[] };
    const n = (d.questions || []).length;
    return `Questions: ${n}`;
  } catch {
    return "";
  }
}

/**
 * Write JSON payload to Cloud Storage at
 * ai/{recordingId}/{type}/{jobId}.json
 *
 * @param {string} recordingId recording id
 * @param {"summary"|"notes"|"quiz"} jobType job type
 * @param {string} jobId aiJobs doc id
 * @param {unknown} jsonObj parsed json payload
 * @return {Promise<string>} object path written
 */
async function saveAiJson(
  recordingId: string,
  jobType: "summary" | "notes" | "quiz",
  jobId: string,
  jsonObj: unknown,
): Promise<string> {
  const bucket = getStorage().bucket();
  const objectPath = `ai/${recordingId}/${jobType}/${jobId}.json`;
  const file = bucket.file(objectPath);
  await file.save(JSON.stringify(jsonObj, null, 2), {
    resumable: false,
    contentType: "application/json; charset=utf-8",
    metadata: { cacheControl: "no-store" },
  });
  return objectPath;
}

/**
 * Trigger on new AI job. Expects docs in collection "aiJobs" with:
 * { type: "summary"|"notes"|"quiz", recordingId: string, uid: string,
 *   status: "pending", createdAt: string }
 */
export const onAiJobCreated = onDocumentCreated(
  { document: "aiJobs/{id}", secrets: ["OPENAI_API_KEY"] },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const jobId = snap.id;
    const job = (snap.data() || {}) as {
      type?: "summary" | "notes" | "quiz";
      recordingId?: string;
      uid?: string;
      status?: string;
    };

    const jobType = job.type;
    const recordingId = job.recordingId;
    if (!jobType || !recordingId) {
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onAiJobCreated`,
          jobId,
          error: "Missing job.type or job.recordingId",
        }),
      );
      await snap.ref.update({
        status: "error",
        error: "Missing job.type or job.recordingId",
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }
    if (job.status && job.status !== "pending") {
      // Only process fresh/pending jobs
      return;
    }

    // Mark processing
    await snap.ref.update({
      status: "processing",
      updatedAt: FieldValue.serverTimestamp(),
    });

    const db = getFirestore();
    const recRef = db.collection("recordings").doc(recordingId);
    const recSnap = await recRef.get();
    if (!recSnap.exists) {
      const msg = "Recording not found.";
      await snap.ref.update({
        status: "error",
        error: msg,
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onAiJobCreated`,
          jobId,
          recordingId,
          error: msg,
        }),
      );
      return;
    }

    // Bump recording status to processing (non-breaking for your UI).
    const recStatusField =
      jobType === "summary"
        ? "summaryStatus"
        : jobType === "notes"
          ? "notesStatus"
          : "quizStatus";
    await recRef.update({
      [recStatusField]: "processing",
      [`${recStatusField}Updated`]: FieldValue.serverTimestamp(),
    });

    // Load transcript
    let transcript = "";
    try {
      transcript = await readTranscriptText(recordingId);
    } catch (e) {
      const msg = (e as { message?: string })?.message || "Transcript missing.";
      await snap.ref.update({
        status: "error",
        error: msg,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await recRef.update({
        [recStatusField]: "error",
        [`${recStatusField}Updated`]: FieldValue.serverTimestamp(),
      });
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onAiJobCreated`,
          jobId,
          recordingId,
          error: msg,
        }),
      );
      return;
    }

    // Generate with OpenAI (JSON only, zero temperature)
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const sys = systemPrompt(jobType as "summary" | "notes" | "quiz");
    const usr = userPrompt(jobType as "summary" | "notes" | "quiz", transcript, recSnap.data() || {});

    let modelJson: unknown;
    try {
      const resp = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: sys },
          { role: "user", content: usr },
        ],
        temperature: 0,
        response_format: { type: "json_object" },
      });
      const raw = resp.choices?.[0]?.message?.content?.trim() || "{}";
      modelJson = safeParseJson(raw);
    } catch (e) {
      const msg =
        (e as { message?: string })?.message || "OpenAI generation failed.";
      await snap.ref.update({
        status: "error",
        error: msg,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await recRef.update({
        [recStatusField]: "error",
        [`${recStatusField}Updated`]: FieldValue.serverTimestamp(),
      });
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onAiJobCreated`,
          jobId,
          recordingId,
          error: msg,
        }),
      );
      return;
    }

    // Save JSON to Storage
    let outPath = "";
    try {
      outPath = await saveAiJson(recordingId, jobType, jobId, modelJson);
    } catch (e) {
      const msg =
        (e as { message?: string })?.message || "Failed to write AI output.";
      await snap.ref.update({
        status: "error",
        error: msg,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await recRef.update({
        [recStatusField]: "error",
        [`${recStatusField}Updated`]: FieldValue.serverTimestamp(),
      });
      logger.error(
        JSON.stringify({
          tag: `${TAG}:onAiJobCreated`,
          jobId,
          recordingId,
          error: msg,
        }),
      );
      return;
    }

    // Preview + finalize statuses
    const preview = makePreview(jobType, modelJson);

    await snap.ref.update({
      status: "done",
      outputPath: outPath,
      preview,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await recRef.update({
      [recStatusField]: "done",
      [`${recStatusField}Updated`]: FieldValue.serverTimestamp(),
      // Optional, additive pointers (won’t break your UI):
      [`ai${jobType[0].toUpperCase()}${jobType.slice(1)}Path`]: outPath,
      [`ai${jobType[0].toUpperCase()}${jobType.slice(1)}Preview`]: preview,
    });

    logger.info(
      JSON.stringify({
        tag: `${TAG}:onAiJobCreated`,
        jobId,
        recordingId,
        type: jobType,
        outputPath: outPath,
      }),
    );
  },
);
