plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")    // Firebase 플러그인 추가
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.project1"
        minSdk = 23
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
    // Firebase BoM: 버전 관리를 위해 플랫폼 의존성으로 선언
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Firebase Analytics (필요에 따라 주석 해제)
    implementation("com.google.firebase:firebase-analytics")

    // 추가 필요시 Firebase 모듈 예시:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
}

