rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android ios

# Default plugins
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.camera
cordova plugin add org.apache.cordova.splashscreen

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="$FACEBOOK_APP_ID" --variable APP_NAME="$FACEBOOK_APP_NAME"
# Google Maps
cordova plugin add plugin.google.maps --variable API_KEY_FOR_IOS="$GOOGLE_API_KEY_FOR_IOS" --variable API_KEY_FOR_ANDROID="$GOOGLE_API_KEY_FOR_ANDROID"
# Merging support-v4 from Facebook and GoogleMaps dependency
SUPPORT_V4_FB=platforms/android/com.phonegap.plugins.facebookconnect/*FacebookLib/libs/android-support-v4.jar
SUPPORT_V4=platforms/android/libs/android-support-v4.jar
[ -n "$(diff $SUPPORT_V4 $SUPPORT_V4_FB 2>/dev/null)" ] && cp -vf $SUPPORT_V4_FB $SUPPORT_V4

# Aid for bug of Http
cordova plugin add https://github.com/sawatani/Cordova-plugin-okhttp.git
# Crash Report
cordova plugin add https://github.com/sawatani/Cordova-plugin-acra.git --variable MAIL_TO="devel+$ACRA_APP_NAME-crash@fathens.org" --variable TOAST_TEXT='Crash Report Sent'
cat platforms/android/AndroidManifest.xml | awk '/<application/ { sub(">", " android:name=\"org.fathens.cordova.acra.AcraApplication\">"); print $0} !/<application/ { print $0 }'
