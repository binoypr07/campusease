
// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                lint {
                    abortOnError = false
                    checkReleaseBuilds = false
                }
            }
        }
    }
}

