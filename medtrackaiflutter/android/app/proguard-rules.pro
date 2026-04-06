# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }

# Firebase Crashlytics & Analytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Standard Proguard Rules for Android
-dontwarn android.support.**
-dontwarn androidx.**

# Keep GSON and JSON symbols for API parsing
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Keep Flutter and Firebase essentials
-keep class io.flutter.plugin.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
