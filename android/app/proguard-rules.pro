# ==============================================================================
# ProGuard & R8 Optimization Rules for OWRITE Flutter Application
# ==============================================================================

# --- Flutter Engine & Embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Flutter Local Notifications & Background Services ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class dev.flutter.plugins.workmanager.** { *; }
-dontwarn dev.flutter.plugins.workmanager.**
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# --- Flutter Deferred Components & Google Play Core ---
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# --- AndroidX & Window Manager ---
-keep class androidx.window.** { *; }
-dontwarn androidx.window.**
-keep class androidx.lifecycle.** { *; }

# --- Firebase & Google Play Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Flutter InAppWebView ---
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# --- TensorFlow / Native ML (If used) ---
-keep class com.tflite.** { *; }
-dontwarn com.tflite.**

# --- Networking & HTTP (Dio / OkHttp) ---
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# --- Desugaring & Java 8+ Standard Libraries ---
-dontwarn java.lang.invoke.**
-dontwarn java.lang.module.**
