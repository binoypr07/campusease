import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.campusease"
    compileSdk = 34
    ndkVersion = "26.1.10909125"

    signingConfigs {
        create("release") {
            val props = Properties()
            props.load(file("release-key.properties").inputStream())

            storeFile = file(props["storeFile"]!!)
            storePassword = props["storePassword"].toString()
            keyAlias = props["keyAlias"].toString()
            keyPassword = props["keyPassword"].toString()
        }
    }

    defaultConfig {
        applicationId = "com.example.campusease"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
