plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Get enableHcpp from gradle property (default: true for HCPP mode)
val enableHcpp: String = project.findProperty("enableHcpp")?.toString() ?: "true"

android {
    namespace = "dev.fluttercon.hcpp_demo"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.fluttercon.hcpp_demo"
        // HCPP requires API 34+ for SurfaceControl APIs
        minSdk = 34
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inject the HCPP toggle into manifest
        manifestPlaceholders["enableHcpp"] = enableHcpp
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
