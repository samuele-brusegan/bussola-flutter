# Nel flavor fdroid le librerie Google Play Services sono escluse da Gradle
# (configurations fdroid*). geolocator gestisce il NoClassDefFoundError e
# ricade su LocationManager; queste regole silenziano solo i missing-class
# di R8 per le classi GMS referenziate ma mai eseguite.
-dontwarn com.google.android.gms.**
-dontnote com.google.android.gms.**
