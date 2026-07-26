# The printing plugin reaches Android's print framework through reflection in
# places, and shrinking would otherwise strip classes it looks up by name.
-keep class net.nfet.flutter.printing.** { *; }
-keep class android.print.** { *; }
-keep class android.printservice.** { *; }
