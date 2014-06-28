rm -rf platforms/*
rm -rf plugins/*

cordova platform add android ios

# Default plugins
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.camera

cordova plugin add org.apache.cordova.file-transfer
cordova plugin add org.apache.cordova.geolocation

# Ionic Keyboard
cordova plugin add https://github.com/driftyco/ionic-plugins-keyboard.git

# Google Maps
cordova plugin add plugin.google.maps --variable API_KEY_FOR_IOS='AIzaSyBbBpBdB0rQQPsvd1Xv1QW_vftXxsgDYr4' --variable API_KEY_FOR_ANDROID='AIzaSyDYNGDBMUgZsnAzFZ4-uZB4VQuSxEfe1Lg'

# Facebook connect
cordova plugin add https://github.com/phonegap/phonegap-facebook-plugin.git --variable APP_ID="751407064903894" --variable APP_NAME="TritonNote"
(cd platforms/android/ && android update project -p . -l FacebookLib) # Add as library
(cd platforms/android/FacebookLib && android update lib-project -p . && ant instrument) # Make gen
