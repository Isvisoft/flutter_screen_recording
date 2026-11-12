# Compatibilidad y validación de Android

La configuración utiliza AGP 9.1.1, Kotlin 2.4.21, Gradle 9.3.1 y bytecode Java/Kotlin 17. Se necesita JDK 17 o posterior para ejecutar Gradle y Flutter 3.44 o posterior para que Flutter aplique Kotlin a los plugins migrados cuando la app utiliza el modo de compatibilidad.

El plugin ya no aplica `kotlin-android` directamente. Utiliza `kotlin.compilerOptions` y permite que AGP o Flutter configure Kotlin según la app anfitriona. La app debe resolver una versión compatible de AGP/Kotlin; el wrapper de una biblioteca no sustituye al de la app.

El ejemplo mantiene `android.builtInKotlin=false` y `android.newDsl=false` porque `flutter_foreground_task` 9.1.0 todavía aplica el plugin Kotlin antiguo. Se ha confirmado que esa dependencia falla al habilitar Kotlin integrado. Para activar `android.builtInKotlin=true` en una app se necesita Flutter 3.47 o posterior y migrar también sus dependencias. Flutter también advierte de que `shared_preferences_android` aplica el plugin Kotlin antiguo. El modo de compatibilidad genera avisos de obsolescencia y deberá revisarse antes de AGP 10.

## Dependencias

- Maven Central sustituye a JCenter en ambos bloques de repositorios.
- Kotlin aporta automáticamente `kotlin-stdlib`; se elimina la declaración antigua `kotlin-stdlib-jdk7`.
- El POM de `com.github.HBiSoft:HBRecorder:2.0.5` responde desde JitPack. No se ha confirmado un fallo de resolución. Se retira porque el código Android no utiliza HBRecorder: la grabación usa `MediaRecorder` y `MediaProjection`. El changelog ya recogía su retirada en 1.0.2.
- Se eliminan los repositorios JitPack y Volcengine, innecesarios para las dependencias restantes. AppCompat permanece en 1.6.0.

## Comprobaciones reproducibles

Desde `example`, con Flutter y el SDK Android configurados:

```sh
flutter pub get
cd android
./gradlew help --stacktrace
./gradlew :flutter_screen_recording:dependencies --configuration debugRuntimeClasspath
cd ..
flutter build apk --debug
```

El wrapper (`gradlew` y su JAR) está ignorado en este repositorio. Si todavía no existe, Flutter lo genera durante la preparación de Android; también puede utilizarse una instalación de Gradle 9.3.1 para ejecutar primero `gradle -p android help`.

## Resultado de la validación (12 de noviembre de 2026)

Entorno: Flutter 3.47.1, Dart 3.13.1, OpenJDK 21 y SDK Android con plataformas 35/36.

- `gradle -p example/android help --stacktrace`: correcto con Gradle 9.3.1, tras retirar `android.enableR8` del ejemplo, una opción eliminada de AGP.
- `:flutter_screen_recording:dependencies --configuration debugRuntimeClasspath`: correcto; selecciona `kotlin-stdlib:2.4.21`, sin HBRecorder ni dependencias sin resolver.
- `ANDROID_HOME=/opt/android-sdk flutter build apk --debug`, desde `example`: correcto; genera `build/app/outputs/flutter-apk/app-debug.apk`.
- `gradle -p flutter_screen_recording/android help`: correcto también con Kotlin integrado en la configuración aislada de la biblioteca (no equivale a compilar una app con todas sus dependencias en ese modo).
- Bytecode de `FlutterScreenRecordingPlugin.class`: versión mayor 61, correspondiente a JVM 17.
- Pruebas de inicio, parada y guardado con/sin audio: **pendientes**. `adb devices -l` no devuelve dispositivos; no hay emulador ni `/dev/kvm` en el entorno. La compilación no demuestra el funcionamiento de la grabación.

## Pruebas en dispositivo

Estas comprobaciones requieren Android y no se sustituyen por una compilación correcta:

| Caso | Procedimiento | Resultado requerido |
| --- | --- | --- |
| Sin audio | Pulsar `Record Screen`, aceptar la captura, esperar al menos cinco segundos y pulsar `Stop Record`. | El inicio devuelve `true`, la parada devuelve una ruta no vacía y el MP4 se abre, contiene imagen y carece de pista de audio. |
| Con audio | Conceder permiso de micrófono, pulsar `Record Screen & audio`, aceptar la captura, hablar durante cinco segundos y detener. | El MP4 se guarda, se abre y reproduce tanto imagen como audio del micrófono. |
| Segundo ciclo | Repetir ambos casos tras detener la grabación anterior. | La grabación vuelve a iniciarse y el servicio se detiene al finalizar. |

Comprobar el archivo antes de iniciar la siguiente grabación: el ejemplo reutiliza el nombre `Title`. La ruta devuelta corresponde a la caché de la aplicación; no implica una exportación a la galería. Registrar versión de Android, modelo, permisos concedidos y resultado de cada caso.

## Referencias

- [Requisitos de AGP 9.1.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes).
- [Migración de plugins Flutter a Kotlin integrado](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors).
- [Configuración de la app y versiones mínimas de Flutter](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers).
