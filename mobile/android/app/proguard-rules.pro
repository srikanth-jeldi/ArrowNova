# Room creates generated databases by reflection. R8 full mode must retain
# their no-argument constructors (WorkManager initializes before Flutter).
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
