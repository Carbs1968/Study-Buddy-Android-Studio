plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // Must match your app id
    namespace = "com.carbs.studybuddy.study_buddy"

    compileSdk = 35

    defaultConfig {
        applicationId = "com.carbs.studybuddy.study_buddy"
        minSdk = 23
        targetSdk = 35

        versionCode = (project.findProperty("flutterVersionCode") as String?)?.toInt() ?: 1
        versionName = project.findProperty("flutterVersionName") as String? ?: "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug { /* defaults */ }
    }

    // Align Java/Kotlin toolchains
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