# ─── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Pocket Guardian Native Code ─────────────────────────────────────────────
-keep class com.example.pocket_guardian.** { *; }

# ─── Sensors Plus ─────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.sensors.** { *; }

# ─── Geolocator ──────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ─── Camera Plugin ────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.camera.** { *; }

# ─── Android Alarm Manager Plus ───────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# ─── Local Auth ───────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }

# ─── Flutter Secure Storage ───────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── HTTP / Networking ────────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ─── General Android ─────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ─── Prevent stripping of error stack traces ─────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
