plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // use org.jetbrains.kotlin.android instead of kotlin-android
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // apply here WITHOUT version
}

android {
    namespace = "com.example.fleet_management"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14033849"


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.fleet_management"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))

    // Firebase SDKs you need
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}
