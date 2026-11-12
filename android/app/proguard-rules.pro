# Règles R8 (optimiseur de la version release).

# WorkManager (utilisé par le SDK Google Mobile Ads) crée sa base Room par
# réflexion : la classe générée WorkDatabase_Impl doit être conservée, sinon
# l'application plante au démarrage (« Failed to create an instance of
# androidx.work.impl.WorkDatabase »).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
