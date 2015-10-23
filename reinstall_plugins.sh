rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android
[ -n "$(uname | grep 'Darwin')" ] && cordova platform add https://github.com/apache/cordova-ios.git

cordova plugin add cordova-plugin-crosswalk-webview
cordova plugin add https://github.com/apache/cordova-plugin-wkwebview-engine.git

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

cordova plugin add https://github.com/fathens/Cordova-Plugin-Crashlytics.git --variable API_KEY=$FABRIC_API_KEY

# Create Icons and Splash Screens
ionic resources
