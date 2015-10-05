rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android
[ -n "$(uname | grep 'Darwin')" ] && cordova platform add ios

cordova plugin add cordova-plugin-crosswalk-webview

# Default plugins
cordova plugin add cordova-plugin-device
cordova plugin add cordova-plugin-console
cordova plugin add cordova-plugin-camera
cordova plugin add cordova-plugin-splashscreen
cordova plugin add cordova-plugin-statusbar
cordova plugin add cordova-plugin-geolocation
cordova plugin add cordova-plugin-whitelist

cordova plugin add phonegap-plugin-push

# Customized org.apache.cordova.file for GOOGLE_PHOTOS
cordova plugin add https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos

cordova plugin add https://github.com/sawatani/Cordova-Plugin-Crashlytics.git#feature/android

# Create Icons and Splash Screens
ionic resources

# Preparing cordova
cordova prepare
