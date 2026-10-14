group = "com.linkxin.cgm_sdk"
version = "0.1.0"

// version vs. App（android/settings.gradle.kts）Be consistent：AGP 8.9.3 / Kotlin 2.1.0 / Java 11。
buildscript {
    val kotlinVersion = "2.1.0"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.linkxin.cgm_sdk"

    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin", "src/main/java")
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    defaultConfig {
        minSdk = 28
        // .so Depend on JNI Reflective writeback GlucoseValue，host on R8 time class name/Field names cannot be confused
        consumerProguardFiles("consumer-rules.pro")
    }
}

dependencies {
    // GlucoseValue.java use @Keep
    implementation("androidx.annotation:annotation:1.9.1")
}
