plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.periodtracking.lunatrack.luna_track"
    compileSdk = 35 // ✅ Use a valid SDK version

    defaultConfig {
        applicationId = "com.periodtracking.lunatrack.luna_track"
        minSdk = 23 // ✅ Firebase plugins & most tools require at least 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true // Enable R8 or ProGuard
            isShrinkResources = true // Shrink unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    // Add required dependencies here when needed
}
