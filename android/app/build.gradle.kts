import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// prod 签名信息：本地从 android/key.properties 读取，
// CI 由 workflow 用 GitHub Secrets 还原出同名文件。
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val hasProdKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.ricky.sweet_crush"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ricky.sweet_crush"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasProdKeystore) {
            create("prod") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            // 开发变体：原包名 + debug 签名，可与 prod 共存安装
            applicationId = "com.ricky.sweet_crush"
            manifestPlaceholders["appLabel"] = "Sweet Crush Dev"
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "env"
            // SEO 关键词包名（sweet candy / match 3 / puzzle，Play 未占用）
            applicationId = "com.sweetcandy.match3.puzzle"
            manifestPlaceholders["appLabel"] = "Sweet Crush"
            // 无 prod 密钥时回退 debug 签名，保证任何人都能构建
            signingConfig = if (hasProdKeystore) {
                signingConfigs.getByName("prod")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        release {
            // 签名由 flavor 决定（dev=debug 签名，prod=正式签名）
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
