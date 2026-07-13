# Flutter rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Keep application entry points
-keep class com.metamorphosisgym.** { *; }

# Keep Dart/Flutter generated code
-keep class **.R
-keep class **.R$* { *; }
