import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mucciologianfranco.android_news"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion // Temporarily commented out

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mucciologianfranco.android_news"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing configuration loading from key.properties
    signingConfigs {
        create("release") {
            val props = Properties()
            val keyPropsFile = rootProject.file("key.properties")
            if (keyPropsFile.exists()) {
                keyPropsFile.inputStream().use { props.load(it) }
                val storeFilePath = props.getProperty("storeFile")
                if (storeFilePath != null) {
                    storeFile = file(storeFilePath)
                }
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            } else {
                println("[Gradle] WARNING: key.properties non trovato. La build release fallirà senza keystore.")
            }
        }
    }

    buildTypes {
        release {
            // Usa la firma release configurata sopra
            signingConfig = signingConfigs.getByName("release")
            // Disabilita minify e shrink per prima release
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // Abilita Impeller per rendering performante
            ndk.debugSymbolLevel = "full"
        }
    }
}

// Forza la versione di desugar_jdk_libs richiesta dai plugin
configurations.all {
    resolutionStrategy {
        force("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AndroidX Core per il supporto edge-to-edge
    implementation("androidx.core:core-ktx:1.15.0")
    // Core library desugaring per Java 8+ APIs (richiesto >= 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Google Play Billing Library (In-App Purchases)
    implementation("com.android.billingclient:billing:7.0.0")
    // Google Mobile Ads SDK (AdMob)
    implementation("com.google.android.gms:play-services-ads:23.0.0")
}
