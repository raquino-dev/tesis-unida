import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val hasFirebaseConfiguration = file("google-services.json").exists()
if (hasFirebaseConfiguration) {
    pluginManager.apply("com.google.gms.google-services")
    pluginManager.apply("com.google.firebase.crashlytics")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseKeyAlias = if (hasKeystoreProperties) {
    keystoreProperties["keyAlias"] as String?
} else {
    System.getenv("PLAY_UPLOAD_KEY_ALIAS")
}
val releaseKeyPassword = if (hasKeystoreProperties) {
    keystoreProperties["keyPassword"] as String?
} else {
    System.getenv("PLAY_UPLOAD_KEY_PASSWORD")
}
val releaseStoreFile = if (hasKeystoreProperties) {
    keystoreProperties["storeFile"] as String?
} else {
    System.getenv("PLAY_UPLOAD_STORE_FILE")
}
val releaseStorePassword = if (hasKeystoreProperties) {
    keystoreProperties["storePassword"] as String?
} else {
    System.getenv("PLAY_UPLOAD_STORE_PASSWORD")
}
val hasReleaseSigning = listOf(
    releaseKeyAlias,
    releaseKeyPassword,
    releaseStoreFile,
    releaseStorePassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "com.tesis.finanzasinteligentes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tesis.finanzasinteligentes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
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
