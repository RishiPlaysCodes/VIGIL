# Vigil ProGuard Rules
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Vigil app classes
-keep class com.vigil.app.** { *; }

# Keep Google Play Services Location
-keep class com.google.android.gms.location.** { *; }

# Keep Camera2 classes
-keep class androidx.camera.** { *; }

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
