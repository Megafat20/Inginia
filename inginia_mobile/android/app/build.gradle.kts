plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.inginia.niger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.inginia.niger"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors
    flavorDimensions += "role"
    productFlavors {
        create("client") {
            dimension = "role"
            applicationId = "com.inginia.niger.client"
        }
        create("prestataire") {
            dimension = "role"
            applicationId = "com.inginia.niger.prestataire"
        }
    }

    // Build types
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // -------------------------------
    // Core library desugaring
    // -------------------------------
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // tes autres dépendances Flutter ou natives ici...
}

flutter {
    source = "../.."
}