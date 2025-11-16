import java.util.Properties
import java.io.FileInputStream

// Load key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ---- Resolve version from Flutter/ pubspec.yaml ----
var resolvedVersionName: String = "1.0.0"
var resolvedVersionCode: Int = 1

run {
    val fromPropsName = (project.properties["flutterVersionName"] as String?)
        ?: (project.properties["FLUTTER_BUILD_NAME"] as String?)
    val fromPropsCodeStr = (project.properties["flutterVersionCode"] as String?)
        ?: (project.properties["FLUTTER_BUILD_NUMBER"] as String?)
    if (fromPropsName != null && fromPropsCodeStr != null) {
        resolvedVersionName = fromPropsName
        resolvedVersionCode = fromPropsCodeStr.toInt()
    } else {
        val pubspec = rootProject.file("../pubspec.yaml")
        if (pubspec.exists()) {
            val line = pubspec.readLines().firstOrNull { it.trim().startsWith("version:") }
            val versionLine = line?.substringAfter("version:")?.trim()
            val parts = versionLine?.split("+")
            resolvedVersionName = parts?.getOrNull(0) ?: "1.0.0"
            resolvedVersionCode = parts?.getOrNull(1)?.toIntOrNull() ?: 1
        }
    }
}
println("📦 Using versionName=$resolvedVersionName  versionCode=$resolvedVersionCode")
// ---- End version resolution ----

android {
    namespace = "com.carbs.studybuddy.study_buddy"

    compileSdk = 36

    defaultConfig {
        applicationId = "com.carbs.studybuddy.study_buddy"
        minSdk = 24
        targetSdk = 35

        versionCode = resolvedVersionCode
        versionName = resolvedVersionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                val alias = keystoreProperties["keyAlias"]?.toString()
                    ?: throw GradleException("Missing keyAlias in key.properties")
                val keyPass = keystoreProperties["keyPassword"]?.toString()
                    ?: throw GradleException("Missing keyPassword in key.properties")
                val storePath = keystoreProperties["storeFile"]?.toString()
                    ?: throw GradleException("Missing storeFile in key.properties")
                val storePass = keystoreProperties["storePassword"]?.toString()
                    ?: throw GradleException("Missing storePassword in key.properties")

                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(storePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug { }
    }



    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            // excludes += setOf("META-INF/*")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}

gradle.projectsEvaluated {
    tasks.named("assembleDebug") {
        doLast {
            val apkFile = file("$buildDir/outputs/apk/debug/app-debug.apk")
            val flutterApkDir = file("$rootDir/../build/app/outputs/flutter-apk")
            if (apkFile.exists()) {
                flutterApkDir.mkdirs()
                apkFile.copyTo(file("$flutterApkDir/app-debug.apk"), overwrite = true)
            }
        }
    }
}

// Copy the release AAB to Flutter's expected location as well
gradle.projectsEvaluated {
    tasks.named("bundleRelease") {
        doLast {
            val aabFile = file("$buildDir/outputs/bundle/release/app-release.aab")
            val flutterAabDir = file("$rootDir/../build/app/outputs/bundle/release")
            if (aabFile.exists()) {
                flutterAabDir.mkdirs()
                aabFile.copyTo(file("$flutterAabDir/app-release.aab"), overwrite = true)
            }
        }
    }
}