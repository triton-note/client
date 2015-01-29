rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android ios

# Default plugins
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.camera
cordova plugin add org.apache.cordova.splashscreen

cordova plugin add com.ionic.keyboard

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="751407064903894" --variable APP_NAME="TritonNote"
# Google Maps
cordova plugin add plugin.google.maps --variable API_KEY_FOR_IOS='AIzaSyBbBpBdB0rQQPsvd1Xv1QW_vftXxsgDYr4' --variable API_KEY_FOR_ANDROID='AIzaSyDYNGDBMUgZsnAzFZ4-uZB4VQuSxEfe1Lg'
# Merging support-v4 from Facebook and GoogleMaps dependency
SUPPORT_V4_FB=platforms/android/com.phonegap.plugins.facebookconnect/*FacebookLib/libs/android-support-v4.jar
SUPPORT_V4=platforms/android/libs/android-support-v4.jar
[ -n "$(diff $SUPPORT_V4 $SUPPORT_V4_FB 2>/dev/null)" ] && cp -vf $SUPPORT_V4_FB $SUPPORT_V4

# Aid for bug of Http
cordova plugin add https://github.com/sawatani/Cordova-plugin-okhttp.git
# Crash Report
cordova plugin add https://github.com/sawatani/Cordova-plugin-acra.git --variable MAIL_TO='devel+triton_note-crash@fathens.org' --variable TOAST_TEXT='Crash Report Sent'
