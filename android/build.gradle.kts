// Top-level build file where you can add configuration options common to all sub-projects/modules.
import org.gradle.api.Project

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Only needed for Google services plugin
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Required by Flutter
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
