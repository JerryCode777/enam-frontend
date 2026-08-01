import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciales de la clave de subida. Viven en android/key.properties, que
// está fuera del repositorio junto con el propio keystore: una clave de firma
// en el control de versiones deja que cualquiera con acceso al código publique
// actualizaciones en nombre de la app.
//
// Si el archivo no existe —una clonación limpia, la máquina de otra persona—
// el build de release falla con un mensaje claro en vez de firmar con la clave
// de depuración, que es lo que hacía antes y que Play Store rechaza.
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "pe.jakstech.enam_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pe.jakstech.enam_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // RNF-09: Android 8.0 (API 26) o superior.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val alias = keyProperties.getProperty("keyAlias")
            if (alias != null) {
                keyAlias = alias
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = keyProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties se falla en seco. Firmar con la clave de
            // depuración produce un APK que Play Store rechaza, y descubrirlo
            // al subir cuesta más que descubrirlo al compilar.
            require(keyProperties.getProperty("keyAlias") != null) {
                "Falta android/key.properties: sin él no se puede firmar el " +
                    "build de release. Pídelo a quien tenga el keystore."
            }
            signingConfig = signingConfigs.getByName("release")
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
