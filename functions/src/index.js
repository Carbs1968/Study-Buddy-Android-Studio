const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFile } = require("child_process");
const ffmpegPath = require("ffmpeg-static");

const OpenAI = require("openai");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { defineSecret } = require("firebase-functions/params");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

initializeApp();

const REGION = "us-central1";
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const CHAT_MODEL = "gpt-4o-mini";
const TRANSCRIPT_TYPE = "transcript";
const SUPPORTED_OUTPUT_TYPES = new Set(["summary", "notes", "quiz"]);
const AUDIO_RETENTION_DAYS_AFTER_TRANSCRIPT = 5;
const AUDIO_CLEANUP_BATCH_LIMIT = 100;
const OPENAI_AUDIO_SAFE_LIMIT_BYTES = 20 * 1024 * 1024;
const AUDIO_CHUNK_SECONDS = 10 * 60;
const CLASS_STUDY_GUIDE_TRANSCRIPT_CHAR_LIMIT = 60000;

const db = getFirestore();
const storage = getStorage();

function now() {
  return FieldValue.serverTimestamp();
}

function audioDeleteAfterDate() {
  const date = new Date();
  date.setDate(date.getDate() + AUDIO_RETENTION_DAYS_AFTER_TRANSCRIPT);
  return date;
}

function trimOrEmpty(value) {
  return typeof value === "string" ? value.trim() : "";
}

function resolveSessionId(job) {
  return trimOrEmpty(job.sessionId) || trimOrEmpty(job.recordingId);
}

function timestampValuesEqual(left, right) {
  if (!left && !right) return true;
  if (!left || !right) return false;
  if (typeof left.isEqual === "function") return left.isEqual(right);
  if (
    typeof left.toMillis === "function" &&
    typeof right.toMillis === "function"
  ) {
    return left.toMillis() === right.toMillis();
  }
  return left === right;
}

function sessionDocumentPath(uid, sessionId) {
  return `users/${uid}/sessions/${sessionId}`;
}

function statusFieldForType(type) {
  return `${type}Status`;
}

function timestampMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return typeof value === "number" ? value : 0;
}

function latestAiJobSortValue(snapshot) {
  const job = snapshot.data() || {};
  return timestampMillis(job.completedAt) || timestampMillis(job.updatedAt);
}

function safeTmpAudioPath(jobId, audioStoragePath) {
  const audioFileName = path.basename(audioStoragePath) || "audio-file";
  const safeFileName = audioFileName.replace(/[^a-zA-Z0-9._-]/g, "_");
  return path.join(os.tmpdir(), `${jobId}-${Date.now()}-${safeFileName}`);
}

function safeTmpChunkDir(jobId) {
  return path.join(os.tmpdir(), `${jobId}-${Date.now()}-audio-chunks`);
}

function openAiClient() {
  return new OpenAI({ apiKey: OPENAI_API_KEY.value() });
}

function localFileSizeBytes(localPath) {
  return fs.statSync(localPath).size;
}

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    execFile(ffmpegPath, args, (error, stdout, stderr) => {
      if (error) {
        const message =
          `ffmpeg failed: ${error.message}. stderr: ${stderr || "<empty>"}`;
        reject(new Error(message));
        return;
      }

      resolve({ stdout, stderr });
    });
  });
}

async function splitAudioIntoChunks(localAudioPath, chunkDir) {
  fs.mkdirSync(chunkDir, { recursive: true });

  const chunkPattern = path.join(chunkDir, "chunk-%03d.mp3");

  await runFfmpeg([
    "-y",
    "-i",
    localAudioPath,
    "-vn",
    "-ac",
    "1",
    "-ar",
    "16000",
    "-b:a",
    "48k",
    "-f",
    "segment",
    "-segment_time",
    String(AUDIO_CHUNK_SECONDS),
    "-reset_timestamps",
    "1",
    chunkPattern,
  ]);

  const chunks = fs
    .readdirSync(chunkDir)
    .filter((fileName) => fileName.endsWith(".mp3"))
    .sort()
    .map((fileName) => path.join(chunkDir, fileName));

  if (!chunks.length) {
    throw new Error("Audio chunking did not create any chunk files.");
  }

  return chunks;
}

async function transcribeSingleAudioFile(localAudioPath) {
  const transcription = await openAiClient().audio.transcriptions.create({
    file: fs.createReadStream(localAudioPath),
    model: "whisper-1",
  });

  return trimOrEmpty(transcription && transcription.text);
}

async function transcribeAudioFile(localAudioPath, progressCallback) {
  const originalSizeBytes = localFileSizeBytes(localAudioPath);

  if (originalSizeBytes <= OPENAI_AUDIO_SAFE_LIMIT_BYTES) {
    const text = await transcribeSingleAudioFile(localAudioPath);
    return {
      text,
      chunked: false,
      originalSizeBytes,
      chunkCount: 1,
    };
  }

  const chunkDir = safeTmpChunkDir(path.basename(localAudioPath));
  const chunks = await splitAudioIntoChunks(localAudioPath, chunkDir);
  const transcriptParts = [];

  try {
    for (let index = 0; index < chunks.length; index += 1) {
      const chunkPath = chunks[index];
      const chunkSizeBytes = localFileSizeBytes(chunkPath);

      if (chunkSizeBytes > OPENAI_AUDIO_SAFE_LIMIT_BYTES) {
        throw new Error(
          `Audio chunk ${index + 1} is still too large for transcription ` +
            `(${chunkSizeBytes} bytes).`,
        );
      }

      if (typeof progressCallback === "function") {
        await progressCallback({
          chunkIndex: index + 1,
          chunkCount: chunks.length,
          chunkSizeBytes,
        });
      }

      const chunkText = await transcribeSingleAudioFile(chunkPath);
      if (chunkText) {
        transcriptParts.push(chunkText);
      }
    }

    return {
      text: trimOrEmpty(transcriptParts.join("\n\n")),
      chunked: true,
      originalSizeBytes,
      chunkCount: chunks.length,
    };
  } finally {
    try {
      fs.rmSync(chunkDir, { recursive: true, force: true });
    } catch (cleanupError) {
      console.warn(`Failed to clean up audio chunk dir '${chunkDir}'.`, cleanupError);
    }
  }
}

async function writeAiJobError(jobRef, errorCode, message, extra = {}) {
  await jobRef.set(
    {
      status: "error",
      errorCode,
      error: message,
      errorMessage: message,
      updatedAt: now(),
      ...extra,
    },
    { merge: true },
  );
}

async function writeSessionError(sessionRef, type, errorCode, message) {
  await sessionRef.set(
    {
      [statusFieldForType(type)]: "error",
      [`${type}ErrorCode`]: errorCode,
      [`${type}ErrorMessage`]: message,
      updatedAt: now(),
    },
    { merge: true },
  );
}

function jsonParseError(message) {
  const error = new Error(message);
  error.code = "openai-json-parse-failed";
  return error;
}

function parseJsonContent(content) {
  const text = trimOrEmpty(content);
  if (!text) {
    throw jsonParseError("OpenAI returned an empty JSON response.");
  }

  try {
    return JSON.parse(text);
  } catch (error) {
    throw jsonParseError(`OpenAI returned invalid JSON: ${error.message}.`);
  }
}

function promptForType(type, transcriptText) {
  const basePrompt =
    "Use the transcript to create useful student study material. " +
    "Return valid JSON only. Do not include Markdown or extra text.";

  switch (type) {
    case "summary":
      return {
        system:
          `${basePrompt} The JSON must be exactly: ` +
          `{"summary":"<concise student-friendly lecture summary>"}.`,
        user: `Transcript:\n${transcriptText}`,
      };
    case "notes":
      return {
        system:
          `${basePrompt} The JSON must be exactly: ` +
          `{"notes":[{"heading":"<section heading>","bullets":["<bullet 1>","<bullet 2>"]}]}.`,
        user: `Transcript:\n${transcriptText}`,
      };
    case "quiz":
      return {
        system:
          `${basePrompt} The JSON must be exactly: ` +
          `{"questions":[{"question":"<question>","choices":["A","B","C","D"],"answer":"<correct choice text or letter>","explanation":"<brief explanation>"}]}.`,
        user: `Transcript:\n${transcriptText}`,
      };
    default:
      throw new Error(`Unsupported OpenAI output type '${type}'.`);
  }
}

function validateGeneratedOutput(type, output) {
  if (!output || typeof output !== "object" || Array.isArray(output)) {
    throw jsonParseError("OpenAI JSON response must be an object.");
  }

  if (type === "summary") {
    if (!trimOrEmpty(output.summary)) {
      throw jsonParseError("OpenAI JSON response is missing summary text.");
    }
    return { summary: output.summary };
  }

  if (type === "notes") {
    if (!Array.isArray(output.notes)) {
      throw jsonParseError("OpenAI JSON response is missing notes array.");
    }
    return { notes: output.notes };
  }

  if (type === "quiz") {
    if (!Array.isArray(output.questions)) {
      throw jsonParseError("OpenAI JSON response is missing questions array.");
    }
    return { questions: output.questions };
  }

  return output;
}

async function generateOpenAiOutput(type, transcriptText) {
  const prompt = promptForType(type, transcriptText);
  const completion = await openAiClient().chat.completions.create({
    model: CHAT_MODEL,
    messages: [
      { role: "system", content: prompt.system },
      { role: "user", content: prompt.user },
    ],
    response_format: { type: "json_object" },
    temperature: 0.2,
  });

  const content =
    completion.choices &&
    completion.choices[0] &&
    completion.choices[0].message &&
    completion.choices[0].message.content;

  return validateGeneratedOutput(type, parseJsonContent(content));
}

function classStudyGuidePrompt(className, transcriptText) {
  return {
    system:
      "Create a concise but useful study guide for students using only the " +
      "provided class recording transcripts. Do not invent facts. Return valid " +
      "JSON only, with exactly this shape: " +
      "{\"title\":\"<title>\",\"overview\":\"<overview>\"," +
      "\"keyTopics\":[{\"title\":\"<topic>\",\"summary\":\"<summary>\"}]," +
      "\"studySections\":[{\"heading\":\"<heading>\",\"bullets\":[\"<bullet>\"]}]," +
      "\"reviewQuestions\":[{\"question\":\"<question>\",\"answer\":\"<answer>\"}]," +
      "\"sourceSummary\":{\"sessionCount\":<number>}}.",
    user: `Class: ${className || "Class"}\n\nTranscripts:\n${transcriptText}`,
  };
}

function validateClassStudyGuideOutput(output) {
  if (!output || typeof output !== "object" || Array.isArray(output)) {
    throw jsonParseError("OpenAI JSON response must be an object.");
  }

  if (!trimOrEmpty(output.title)) {
    throw jsonParseError("Class study guide response is missing title.");
  }
  if (!trimOrEmpty(output.overview)) {
    throw jsonParseError("Class study guide response is missing overview.");
  }
  if (!Array.isArray(output.keyTopics)) {
    throw jsonParseError("Class study guide response is missing keyTopics array.");
  }
  if (!Array.isArray(output.studySections)) {
    throw jsonParseError(
      "Class study guide response is missing studySections array.",
    );
  }
  if (!Array.isArray(output.reviewQuestions)) {
    throw jsonParseError(
      "Class study guide response is missing reviewQuestions array.",
    );
  }
  if (!output.sourceSummary || typeof output.sourceSummary !== "object") {
    throw jsonParseError("Class study guide response is missing sourceSummary.");
  }

  return {
    title: output.title,
    overview: output.overview,
    keyTopics: output.keyTopics,
    studySections: output.studySections,
    reviewQuestions: output.reviewQuestions,
    sourceSummary: output.sourceSummary,
  };
}

async function generateClassStudyGuideOutput(className, transcriptText) {
  const prompt = classStudyGuidePrompt(className, transcriptText);
  const completion = await openAiClient().chat.completions.create({
    model: CHAT_MODEL,
    messages: [
      { role: "system", content: prompt.system },
      { role: "user", content: prompt.user },
    ],
    response_format: { type: "json_object" },
    temperature: 0.2,
  });

  const content =
    completion.choices &&
    completion.choices[0] &&
    completion.choices[0].message &&
    completion.choices[0].message.content;

  return validateClassStudyGuideOutput(parseJsonContent(content));
}

function errorCodeForGenerationFailure(type, error) {
  return error && error.code ? error.code : `${type}-generation-failed`;
}

exports.onAiJobCreated = onDocumentCreated(
  {
    document: "aiJobs/{jobId}",
    region: REGION,
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const job = snapshot.data() || {};
    const jobRef = snapshot.ref;
    const jobId = event.params.jobId;
    const uid = trimOrEmpty(job.uid);
    const type = trimOrEmpty(job.type);
    const sessionId = resolveSessionId(job);

    if (!uid) {
      await writeAiJobError(jobRef, "missing-uid", "AI job is missing required uid.");
      return;
    }

    if (!sessionId) {
      await writeAiJobError(
        jobRef,
        "missing-session-id",
        "AI job is missing required sessionId or recordingId.",
      );
      return;
    }

    if (type !== TRANSCRIPT_TYPE && !SUPPORTED_OUTPUT_TYPES.has(type)) {
      await writeAiJobError(
        jobRef,
        "unsupported-ai-job-type",
        `Unsupported AI job type '${type || "<empty>"}'.`,
      );
      return;
    }

    const sessionPath = sessionDocumentPath(uid, sessionId);
    const sessionRef = db.doc(sessionPath);
    const sessionSnapshot = await sessionRef.get();

    if (!sessionSnapshot.exists) {
      await writeAiJobError(
        jobRef,
        "session-not-found",
        `Session document not found at ${sessionPath}.`,
        { sessionPath },
      );
      return;
    }

    const session = sessionSnapshot.data() || {};

    if (type === TRANSCRIPT_TYPE) {
      const audioStoragePath = trimOrEmpty(session.audioStoragePath);

      if (!audioStoragePath) {
        const message =
          "Session is missing audioStoragePath; Firebase Storage audio cannot be checked.";
        await writeAiJobError(jobRef, "missing-audio-storage-path", message, {
          sessionPath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "missing-audio-storage-path",
          message,
        );
        return;
      }

      const [audioExists] = await storage.bucket().file(audioStoragePath).exists();

      if (!audioExists) {
        const message =
          `Audio file was not found in Firebase Storage at '${audioStoragePath}'.`;
        await writeAiJobError(jobRef, "audio-storage-object-not-found", message, {
          sessionPath,
          audioStoragePath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "audio-storage-object-not-found",
          message,
        );
        return;
      }

      const localAudioPath = safeTmpAudioPath(jobId, audioStoragePath);
      const startedAt = now();

      await jobRef.set(
        {
          status: "running",
          startedAt,
          updatedAt: startedAt,
        },
        { merge: true },
      );

      await sessionRef.set(
        {
          transcriptStatus: "processing",
          sessionStatus: "processing",
          updatedAt: startedAt,
        },
        { merge: true },
      );

      try {
        await storage.bucket().file(audioStoragePath).download({
          destination: localAudioPath,
        });

        const transcriptionResult = await transcribeAudioFile(
          localAudioPath,
          async ({ chunkIndex, chunkCount, chunkSizeBytes }) => {
            await sessionRef.set(
              {
                transcriptStatus: "processing",
                transcriptChunkCount: chunkCount,
                transcriptChunksCompleted: chunkIndex - 1,
                transcriptCurrentChunkSizeBytes: chunkSizeBytes,
                updatedAt: now(),
              },
              { merge: true },
            );

            await jobRef.set(
              {
                transcriptChunkCount: chunkCount,
                transcriptChunksCompleted: chunkIndex - 1,
                transcriptCurrentChunkSizeBytes: chunkSizeBytes,
                updatedAt: now(),
              },
              { merge: true },
            );
          },
        );

        const transcriptText = transcriptionResult.text;
        if (!transcriptText) {
          throw new Error("OpenAI returned an empty transcription response.");
        }

        const timestamp = now();

        await sessionRef.set(
          {
            transcriptStatus: "done",
            sessionStatus: "ready",
            transcriptText,
            transcriptUpdatedAt: timestamp,
            transcriptErrorCode: null,
            transcriptErrorMessage: null,
            transcriptWasChunked: transcriptionResult.chunked,
            transcriptChunkCount: transcriptionResult.chunkCount,
            transcriptChunksCompleted: transcriptionResult.chunkCount,
            transcriptOriginalAudioSizeBytes: transcriptionResult.originalSizeBytes,
            audioDeletionStatus: "scheduled",
            audioDeleteAfter: audioDeleteAfterDate(),
            audioDeletedAt: null,
            updatedAt: timestamp,
          },
          { merge: true },
        );

        await jobRef.set(
          {
            status: "done",
            output: { text: transcriptText },
            sessionPath,
            audioStoragePath,
            transcriptWasChunked: transcriptionResult.chunked,
            transcriptChunkCount: transcriptionResult.chunkCount,
            transcriptOriginalAudioSizeBytes: transcriptionResult.originalSizeBytes,
            completedAt: timestamp,
            updatedAt: timestamp,
          },
          { merge: true },
        );
      } catch (error) {
        const errorMessage =
          error && error.message ? error.message : String(error);
        const message =
          `Audio download or OpenAI transcription failed for '${audioStoragePath}': ${errorMessage}`;
        await writeAiJobError(jobRef, "transcription-failed", message, {
          sessionPath,
          audioStoragePath,
        });
        await writeSessionError(
          sessionRef,
          TRANSCRIPT_TYPE,
          "transcription-failed",
          message,
        );
      } finally {
        try {
          if (fs.existsSync(localAudioPath)) {
            fs.unlinkSync(localAudioPath);
          }
        } catch (cleanupError) {
          console.warn(
            `Failed to clean up temporary audio file '${localAudioPath}'.`,
            cleanupError,
          );
        }
      }
      return;
    }

    const transcriptText = trimOrEmpty(session.transcriptText);
    if (session.transcriptStatus !== "done" || !transcriptText) {
      const message =
        `Cannot create ${type} output because transcriptStatus is not done or transcriptText is empty.`;
      await writeAiJobError(jobRef, "transcript-not-ready", message, {
        sessionPath,
      });
      await writeSessionError(sessionRef, type, "transcript-not-ready", message);
      return;
    }

    const startedAt = now();

    await jobRef.set(
      {
        status: "running",
        startedAt,
        updatedAt: startedAt,
      },
      { merge: true },
    );

    await sessionRef.set(
      {
        [statusFieldForType(type)]: "processing",
        updatedAt: startedAt,
      },
      { merge: true },
    );

    try {
      const output = await generateOpenAiOutput(type, transcriptText);
      const timestamp = now();

      await sessionRef.set(
        {
          [statusFieldForType(type)]: "done",
          [`${type}Output`]: output,
          updatedAt: timestamp,
        },
        { merge: true },
      );

      await jobRef.set(
        {
          status: "done",
          output,
          sessionPath,
          completedAt: timestamp,
          updatedAt: timestamp,
        },
        { merge: true },
      );

      console.log(`Completed OpenAI ${type} job ${jobId} for ${sessionPath}.`);
    } catch (error) {
      const errorMessage =
        error && error.message ? error.message : String(error);
      const message =
        `OpenAI ${type} generation failed for ${sessionPath}: ${errorMessage}`;
      const errorCode = errorCodeForGenerationFailure(type, error);

      await writeAiJobError(jobRef, errorCode, message, { sessionPath });
      await writeSessionError(sessionRef, type, errorCode, message);
    }
  },
);

exports.onTranscriptRequested = onDocumentUpdated(
  { document: "users/{uid}/sessions/{sessionId}", region: REGION },
  async (event) => {
    const afterSnapshot = event.data && event.data.after;
    if (!afterSnapshot) return;

    const session = afterSnapshot.data() || {};
    const transcribeRequested = session.transcribeRequested === true;
    const transcriptPending = session.transcriptStatus === "pending";
    const audioStoragePath = trimOrEmpty(session.audioStoragePath);

    if (transcribeRequested && transcriptPending && !audioStoragePath) {
      await afterSnapshot.ref.set(
        {
          transcriptStatus: "error",
          transcriptErrorCode: "missing-audio-storage-path",
          transcriptErrorMessage:
            "transcribeRequested is true but audioStoragePath is missing; no AI job was created.",
          updatedAt: now(),
        },
        { merge: true },
      );
    }
  },
);

exports.getTranscriptText = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const recordingId = trimOrEmpty(request.data && request.data.recordingId);
  if (!recordingId) {
    throw new HttpsError("invalid-argument", "recordingId is required.");
  }

  const sessionSnapshot = await db
    .doc(sessionDocumentPath(request.auth.uid, recordingId))
    .get();

  if (!sessionSnapshot.exists) {
    return { text: "" };
  }

  const session = sessionSnapshot.data() || {};
  return {
    text: typeof session.transcriptText === "string" ? session.transcriptText : "",
  };
});

exports.requestClassStudyGuide = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const academicYearId = trimOrEmpty(request.data && request.data.academicYearId);
  const semesterId = trimOrEmpty(request.data && request.data.semesterId);
  const classId = trimOrEmpty(request.data && request.data.classId);

  if (!academicYearId) {
    throw new HttpsError("invalid-argument", "academicYearId is required.");
  }
  if (!semesterId) {
    throw new HttpsError("invalid-argument", "semesterId is required.");
  }
  if (!classId) {
    throw new HttpsError("invalid-argument", "classId is required.");
  }

  const uid = request.auth.uid;
  const classPath =
    `users/${uid}/academicYears/${academicYearId}` +
    `/semesters/${semesterId}/classes/${classId}`;
  const classRef = db.doc(classPath);
  const classSnapshot = await classRef.get();

  if (!classSnapshot.exists) {
    throw new HttpsError("not-found", "Class not found.");
  }

  const sessionsSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("sessions")
    .where("academicYearId", "==", academicYearId)
    .where("semesterId", "==", semesterId)
    .where("classId", "==", classId)
    .where("transcriptStatus", "==", "done")
    .get();

  const eligibleSessionCount = sessionsSnapshot.docs.filter((doc) => {
    const session = doc.data() || {};
    return Boolean(trimOrEmpty(session.transcriptText));
  }).length;

  const classData = classSnapshot.data() || {};
  const className = trimOrEmpty(classData.className);

  if (eligibleSessionCount === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No completed transcripts are available for this class.",
    );
  }

  const requestResult = await db.runTransaction(async (transaction) => {
    const transactionClassSnapshot = await transaction.get(classRef);
    if (!transactionClassSnapshot.exists) {
      throw new HttpsError("not-found", "Class not found.");
    }

    const transactionClassData = transactionClassSnapshot.data() || {};
    const contentSnapshot = {
      recordingsLastChangedAt: transactionClassData.lastRecordingAt || null,
      materialsLastChangedAt: transactionClassData.lastMaterialAt || null,
      includedRecordings: true,
      includedMaterials: false,
    };
    const existingStatus = trimOrEmpty(
      transactionClassData.classStudyGuideStatus,
    );
    const latestStudyGuideRequestId = trimOrEmpty(
      transactionClassData.latestStudyGuideRequestId,
    );
    const storedContentSnapshot =
      transactionClassData.classStudyGuideContentSnapshot || {};

    if (
      ["validated", "queued", "running"].includes(existingStatus) &&
      latestStudyGuideRequestId &&
      timestampValuesEqual(
        storedContentSnapshot.recordingsLastChangedAt,
        contentSnapshot.recordingsLastChangedAt,
      )
    ) {
      return {
        reused: true,
        status: existingStatus,
        requestId: latestStudyGuideRequestId,
      };
    }

    const timestamp = FieldValue.serverTimestamp();
    const requestRef = db.collection("classStudyGuideRequests").doc();
    transaction.set(requestRef, {
      uid,
      type: "classStudyGuide",
      source: "recordings",
      academicYearId,
      semesterId,
      classId,
      classPath,
      className,
      status: "validated",
      eligibleSessionCount,
      contentSnapshot,
      createdAt: timestamp,
      updatedAt: timestamp,
    });
    transaction.set(classRef, {
      classStudyGuideStatus: "validated",
      latestStudyGuideRequestId: requestRef.id,
      classStudyGuideUpdatedAt: timestamp,
      classStudyGuideSource: "recordings",
      classStudyGuideEligibleSessionCount: eligibleSessionCount,
      classStudyGuideContentSnapshot: contentSnapshot,
    }, { merge: true });

    return {
      reused: false,
      status: "validated",
      requestId: requestRef.id,
    };
  });

  return {
    ok: true,
    status: requestResult.status,
    reused: requestResult.reused,
    requestId: requestResult.requestId,
    eligibleSessionCount,
    className,
    academicYearId,
    semesterId,
    classId,
  };
});

exports.onClassStudyGuideRequestCreated = onDocumentCreated(
  {
    document: "classStudyGuideRequests/{requestId}",
    region: REGION,
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const requestRef = snapshot.ref;
    const requestId = event.params.requestId;
    const claimResult = await db.runTransaction(async (transaction) => {
      const requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        return { claimed: false };
      }

      const currentRequest = requestSnapshot.data() || {};
      if (currentRequest.status !== "validated") {
        return { claimed: false };
      }

      const startedAt = now();
      transaction.set(requestRef, {
        status: "running",
        startedAt,
        updatedAt: startedAt,
      }, { merge: true });

      return {
        claimed: true,
        request: currentRequest,
        startedAt,
      };
    });

    if (!claimResult.claimed) return;

    const request = claimResult.request || {};
    const startedAt = claimResult.startedAt;

    const uid = trimOrEmpty(request.uid);
    const academicYearId = trimOrEmpty(request.academicYearId);
    const semesterId = trimOrEmpty(request.semesterId);
    const classId = trimOrEmpty(request.classId);
    const classPath = trimOrEmpty(request.classPath);
    const className = trimOrEmpty(request.className);
    const eligibleSessionCount = request.eligibleSessionCount;
    const contentSnapshot = request.contentSnapshot || {};
    let classRef = null;

    try {
      if (!uid) throw Object.assign(new Error("Request is missing uid."), {
        code: "missing-uid",
      });
      if (!academicYearId) {
        throw Object.assign(new Error("Request is missing academicYearId."), {
          code: "missing-academic-year-id",
        });
      }
      if (!semesterId) {
        throw Object.assign(new Error("Request is missing semesterId."), {
          code: "missing-semester-id",
        });
      }
      if (!classId) throw Object.assign(new Error("Request is missing classId."), {
        code: "missing-class-id",
      });
      if (!classPath) {
        throw Object.assign(new Error("Request is missing classPath."), {
          code: "missing-class-path",
        });
      }
      if (typeof eligibleSessionCount !== "number" || eligibleSessionCount <= 0) {
        throw Object.assign(
          new Error("Request has no eligible completed transcript sessions."),
          { code: "no-completed-transcripts" },
        );
      }

      const expectedClassPath =
        `users/${uid}/academicYears/${academicYearId}` +
        `/semesters/${semesterId}/classes/${classId}`;
      if (classPath !== expectedClassPath) {
        throw Object.assign(new Error("Request classPath does not match class IDs."), {
          code: "class-path-mismatch",
        });
      }

      classRef = db.doc(classPath);
      await classRef.set({
        classStudyGuideStatus: "running",
        classStudyGuideUpdatedAt: startedAt,
        latestStudyGuideRequestId: requestId,
      }, { merge: true });

      const sessionsSnapshot = await db
        .collection("users")
        .doc(uid)
        .collection("sessions")
        .where("academicYearId", "==", academicYearId)
        .where("semesterId", "==", semesterId)
        .where("classId", "==", classId)
        .where("transcriptStatus", "==", "done")
        .get();

      const sessions = sessionsSnapshot.docs
        .map((doc) => {
          const data = doc.data() || {};
          return {
            sessionId: doc.id,
            topicName:
              trimOrEmpty(data.topicName) ||
              trimOrEmpty(data.topic) ||
              "Untitled session",
            createdAt: data.createdAt || null,
            transcriptText: trimOrEmpty(data.transcriptText),
          };
        })
        .filter((session) => session.transcriptText)
        .sort((left, right) => {
          const createdCmp =
            timestampMillis(left.createdAt) - timestampMillis(right.createdAt);
          if (createdCmp !== 0) return createdCmp;
          return left.sessionId.localeCompare(right.sessionId);
        });

      if (!sessions.length) {
        throw Object.assign(
          new Error("No completed transcripts are available for this class."),
          { code: "no-completed-transcripts" },
        );
      }

      const transcriptCharCount = sessions.reduce(
        (total, session) => total + session.transcriptText.length,
        0,
      );
      if (transcriptCharCount > CLASS_STUDY_GUIDE_TRANSCRIPT_CHAR_LIMIT) {
        throw Object.assign(
          new Error(
            "Class transcripts are too large to generate a study guide in v1.",
          ),
          { code: "too-much-transcript-text" },
        );
      }

      const sourceSessions = sessions.map((session) => ({
        sessionId: session.sessionId,
        topicName: session.topicName,
        createdAt: session.createdAt,
      }));
      const transcriptText = sessions
        .map((session, index) => (
          `Session ${index + 1}: ${session.topicName}\n` +
          `Transcript:\n${session.transcriptText}`
        ))
        .join("\n\n---\n\n");
      const output = await generateClassStudyGuideOutput(className, transcriptText);
      const completedAt = now();
      const guideRef = classRef.collection("studyGuides").doc();
      const guidePath = `${classPath}/studyGuides/${guideRef.id}`;

      await guideRef.set({
        uid,
        type: "classStudyGuide",
        source: "recordings",
        academicYearId,
        semesterId,
        classId,
        classPath,
        requestId,
        className,
        status: "done",
        contentSnapshot,
        eligibleSessionCount,
        includedSessionCount: sessions.length,
        omittedSessionCount: 0,
        sourceSessions,
        output,
        createdAt: completedAt,
        updatedAt: completedAt,
        completedAt,
      });
      await requestRef.set({
        status: "done",
        guideId: guideRef.id,
        guidePath,
        completedAt,
        updatedAt: completedAt,
      }, { merge: true });
      await classRef.set({
        classStudyGuideStatus: "done",
        latestStudyGuideId: guideRef.id,
        latestStudyGuideRequestId: requestId,
        classStudyGuideUpdatedAt: completedAt,
        classStudyGuideErrorCode: null,
        classStudyGuideErrorMessage: null,
      }, { merge: true });
    } catch (error) {
      const errorCode =
        error && error.code ? error.code : "class-study-guide-generation-failed";
      const errorMessage = error && error.message ? error.message : String(error);
      const timestamp = now();

      await requestRef.set({
        status: "error",
        errorCode,
        errorMessage,
        updatedAt: timestamp,
      }, { merge: true });
      if (classRef) {
        await classRef.set({
          classStudyGuideStatus: "error",
          classStudyGuideErrorCode: errorCode,
          classStudyGuideErrorMessage: errorMessage,
          classStudyGuideUpdatedAt: timestamp,
        }, { merge: true });
      }
    }
  },
);

exports.getAiJobOutput = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const requestedType = trimOrEmpty(request.data && request.data.type);
  const sessionId =
    trimOrEmpty(request.data && request.data.sessionId) ||
    trimOrEmpty(request.data && request.data.recordingId);

  if (!sessionId) {
    throw new HttpsError(
      "invalid-argument",
      "sessionId or recordingId is required.",
    );
  }

  if (!requestedType) {
    throw new HttpsError("invalid-argument", "type is required.");
  }

  const querySnapshot = await db
    .collection("aiJobs")
    .where("uid", "==", request.auth.uid)
    .where("sessionId", "==", sessionId)
    .where("type", "==", requestedType)
    .where("status", "==", "done")
    .get();

  if (querySnapshot.empty) {
    return {
      data: null,
      jobId: null,
      sessionId,
      type: requestedType,
    };
  }

  const [jobSnapshot] = querySnapshot.docs.sort(
    (left, right) => latestAiJobSortValue(right) - latestAiJobSortValue(left),
  );
  const job = jobSnapshot.data() || {};

  return {
    data: job.output || null,
    jobId: jobSnapshot.id,
    sessionId,
    type: requestedType,
  };
});

exports.cleanupTranscribedAudio = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "America/Merida",
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const snapshot = await db
      .collectionGroup("sessions")
      .where("transcriptStatus", "==", "done")
      .where("audioDeletionStatus", "==", "scheduled")
      .where("audioDeleteAfter", "<=", new Date())
      .limit(AUDIO_CLEANUP_BATCH_LIMIT)
      .get();

    if (snapshot.empty) {
      console.log("No transcribed audio files ready for cleanup.");
      return;
    }

    for (const doc of snapshot.docs) {
      const session = doc.data() || {};
      const audioStoragePath = trimOrEmpty(session.audioStoragePath);

      if (!audioStoragePath) {
        await doc.ref.set(
          {
            audioDeletionStatus: "skipped",
            audioDeletionErrorCode: "missing-audio-storage-path",
            audioDeletionErrorMessage:
              "Audio cleanup skipped because audioStoragePath is missing.",
            updatedAt: now(),
          },
          { merge: true },
        );
        continue;
      }

      try {
        const file = storage.bucket().file(audioStoragePath);
        const [exists] = await file.exists();

        if (exists) {
          await file.delete();
        }

        await doc.ref.set(
          {
            audioDeletionStatus: "deleted",
            audioDeletedAt: now(),
            audioDownloadUrl: null,
            updatedAt: now(),
          },
          { merge: true },
        );

        console.log(`Deleted transcribed audio file: ${audioStoragePath}`);
      } catch (error) {
        const message = error && error.message ? error.message : String(error);

        await doc.ref.set(
          {
            audioDeletionStatus: "error",
            audioDeletionErrorCode: "audio-delete-failed",
            audioDeletionErrorMessage: message,
            updatedAt: now(),
          },
          { merge: true },
        );

        console.error(`Failed to delete audio file '${audioStoragePath}'.`, error);
      }
    }
  },
);
