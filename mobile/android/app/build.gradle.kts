import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.exists()) releasePropertiesFile.inputStream().use { load(it) }
}
val releaseDefines = (project.findProperty("dart-defines") as? String).orEmpty()
    .split(",").filter { it.isNotBlank() }
    .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
val storeRelease = releaseDefines.contains("STORE_RELEASE=true")
if (storeRelease && !releasePropertiesFile.exists()) {
    throw GradleException("Store releases require android/key.properties and the upload keystore.")
}

android {
    namespace = "com.epitomehub.arrownova"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    val dartDefines = (project.findProperty("dart-defines") as? String).orEmpty()
        .split(",").filter { it.isNotBlank() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    val liveAds = dartDefines.contains("LIVE_ADS=true")

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.epitomehub.arrownova"
        manifestPlaceholders["admobAppId"] = if (liveAds)
            "ca-app-pub-9061518700917881~3462287102"
        else "ca-app-pub-3940256099942544~3347511713"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releasePropertiesFile.exists()) {
            create("upload") {
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
                storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Keep sideload test builds compatible; Play bundles use the upload key.
            signingConfig = signingConfigs.getByName(if (storeRelease) "upload" else "debug")
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

dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
