// android/settings.gradle.kts

pluginManagement {
    // Locate the Flutter SDK from local.properties
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }
        val p = props.getProperty("flutter.sdk")
        require(p != null) { "flutter.sdk not set in local.properties" }
        p
    }

    // Let Flutter inject its build logic
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // Where Gradle should look for *plugins*
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Optional: Flutter’s mirrored artifacts
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

// The Flutter loader must be applied in *settings* (not build.gradle.kts)
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

// Only include the app module
include(":app")