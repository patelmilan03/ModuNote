# R8 keep rules for release builds. Flutter's Gradle plugin and the Firebase /
# Google sign-in / flutter_sound plugins ship their own consumer rules, so this
# file starts empty on purpose. If a release build crashes with
# ClassNotFound / NoSuchMethod, add the missing -keep rule here.
