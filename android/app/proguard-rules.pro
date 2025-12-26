# Stripe ProGuard Rules
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.stripe.android.view.PaymentMethodsActivity
-dontwarn com.stripe.android.view.AddPaymentMethodActivity
-dontwarn com.stripe.android.view.PaymentFlowActivity
