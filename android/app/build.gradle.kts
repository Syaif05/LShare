plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.syaifulloh.lshare"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications and other Java 8+ APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.syaifulloh.lshare"
        // Minimum SDK 21 sesuai PRD (Android 5.0)
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications (Java 8+ core library desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
