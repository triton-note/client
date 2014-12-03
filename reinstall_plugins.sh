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
cordova plugin add com.ionic.keyboard

# Google Maps
cordova plugin add plugin.google.maps --variable API_KEY_FOR_IOS='AIzaSyBbBpBdB0rQQPsvd1Xv1QW_vftXxsgDYr4' --variable API_KEY_FOR_ANDROID='AIzaSyDYNGDBMUgZsnAzFZ4-uZB4VQuSxEfe1Lg'

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="751407064903894" --variable APP_NAME="TritonNote"

# Aid for bug of Http
cordova plugin add https://github.com/sawatani/Cordova-plugin-okhttp.git

# Crash Report
cordova plugin add https://github.com/sawatani/Cordova-plugin-acra.git --variable MAIL_TO='devel+triton_note-crash@fathens.org' --variable TOAST_TEXT='Crash Report Sent'
