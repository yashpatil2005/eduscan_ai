# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Keep all classes in your app package
-keep class com.example.eduscan_ai.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Comprehensive rules for Google ML Kit Vision (which is a sub-dependency)
-keep public class com.google.mlkit.vision.** { *; }
-keep public class com.google.android.gms.vision.** { *; }

-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }

-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }

-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.mlkit.common.model.** { *; }

# Keep common Flutter plugin classes
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.permissionhandler.** { *; }
-keep class io.flutter.plugins.share.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Google Sign-In specific rules
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.signin.internal.** { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInAccount { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInOptions { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInResult { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient$ConnectionCallbacks { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient$OnConnectionFailedListener { *; }

# Additional Google Sign-In rules for release builds
-keep class com.google.android.gms.common.api.Status { *; }
-keep class com.google.android.gms.common.api.Result { *; }
-keep class com.google.android.gms.common.api.Api { *; }
-keep class com.google.android.gms.common.api.GoogleApi { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient$ConnectionCallbacks { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient$OnConnectionFailedListener { *; }
-keep class com.google.android.gms.common.api.Scope { *; }
-keep class com.google.android.gms.common.api.SignInAccount { *; }
-keep class com.google.android.gms.common.api.GoogleSignIn { *; }
-keep class com.google.android.gms.common.api.GoogleSignInClient { *; }
-keep class com.google.android.gms.common.api.GoogleSignInAccount { *; }
-keep class com.google.android.gms.common.api.GoogleSignInOptions { *; }
-keep class com.google.android.gms.common.api.GoogleSignInResult { *; }
-keep class com.google.android.gms.common.api.GoogleSignInStatusCodes { *; }

# Keep all Google Play Services classes
-keep class com.google.android.gms.** { *; }

# Keep JSON serialization classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all classes with @Keep annotation
-keep class * {
    @androidx.annotation.Keep *;
}
