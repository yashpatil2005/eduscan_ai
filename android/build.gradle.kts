buildscript {
    // Defines a modern, stable Kotlin version for the project.
    val kotlin_version by extra("1.9.23") 
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Uses a modern, stable Android Gradle Plugin version compatible with Gradle 8.4+
        classpath("com.android.tools.build:gradle:8.4.1") 
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.4.1")
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
