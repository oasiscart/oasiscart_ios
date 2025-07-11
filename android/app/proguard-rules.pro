# --- Flutter Stripe SDK Protection ---

# Keep required Stripe Android SDK classes
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep required classes for Push Provisioning (fixes your error)
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Flutter core
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Kotlin metadata (used in Stripe SDK and Flutter plugins)
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Gson (used by stripe_sdk for JSON parsing)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# For AndroidX and core libraries
-dontwarn androidx.**

# Optional: Prevent removal of @JavascriptInterface (if using WebView)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Razorpay (from your previous rules)
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }

# Disable R8 method inlining (optional, for debug readability)
-optimizations !method/inlining/*

# Keep payment callbacks if used
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
