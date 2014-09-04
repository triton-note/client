rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android ios

# Default plugins
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.camera
cordova plugin add org.apache.cordova.splashscreen

cordova plugin add org.apache.cordova.file-transfer
cordova plugin add org.apache.cordova.geolocation

# Ionic Keyboard
cordova plugin add https://github.com/driftyco/ionic-plugins-keyboard.git

# Google+ connect
cordova plugin add https://github.com/sawatani/Cordova-GooglePlus.git --variable IOS_CLIENT_ID='945048561360-k8admbvmnc16qkj69s5f6kj154holr7p.apps.googleusercontent.com'

# Facebook connect
cordova plugin add https://github.com/sawatani/phonegap-facebook-plugin.git --variable APP_ID="751407064903894" --variable APP_NAME="TritonNote"
(cd platforms/android/ && android update project -p . -l FacebookLib) # Add as library
(cd platforms/android/FacebookLib && android update lib-project -p . && ant instrument) # Make gen

# Google Maps
cordova plugin add https://github.com/wf9a5m75/phonegap-googlemaps-plugin.git --variable API_KEY_FOR_IOS='AIzaSyBbBpBdB0rQQPsvd1Xv1QW_vftXxsgDYr4' --variable API_KEY_FOR_ANDROID='AIzaSyDYNGDBMUgZsnAzFZ4-uZB4VQuSxEfe1Lg'

# Remove confliction with platforms/android/FacebookLib/libs/android-support-v4.jar
(cd platforms/android && [ -e libs/android-support-v4.jar ] && cp -vf FacebookLib/libs/android-support-v4.jar libs/)

# Aid to bug of Http
cordova plugin add https://github.com/sawatani/Cordova-plugin-okhttp.git

# Crash Report
cordova plugin add https://github.com/sawatani/Cordova-plugin-acra.git --variable MAIL_TO='devel+triton_note-crash@fathens.org' --variable TOAST_TEXT='Crash Report Sent'
