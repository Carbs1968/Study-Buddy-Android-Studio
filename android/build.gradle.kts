// Root Gradle (Kotlin DSL) for the Android project

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services Gradle plugin for Firebase
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}