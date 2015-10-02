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
#cordova plugin add https://github.com/sarriaroman/FabricPlugin

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="$FACEBOOK_APP_ID" --variable APP_NAME="$FACEBOOK_APP_NAME"

# Customized org.apache.cordova.file for GOOGLE_PHOTOS
cordova plugin add https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos

# Create Icons and Splash Screens
ionic resources

# Preparing cordova
cordova prepare
