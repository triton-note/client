rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova platform add android
[ -n "$(uname | grep 'Darwin')" ] && cordova platform add ios

# Default plugins
cordova plugin add org.apache.cordova.device
cordova plugin add org.apache.cordova.console
cordova plugin add org.apache.cordova.camera
cordova plugin add org.apache.cordova.splashscreen
cordova plugin add org.apache.cordova.statusbar
cordova plugin add org.apache.cordova.geolocation

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="$FACEBOOK_APP_ID" --variable APP_NAME="$FACEBOOK_APP_NAME"
# Google Maps
cordova plugin add plugin.google.maps --variable API_KEY_FOR_IOS="$GOOGLE_API_KEY_FOR_IOS" --variable API_KEY_FOR_ANDROID="$GOOGLE_API_KEY_FOR_ANDROID"
# Merging support-v4 from Facebook and GoogleMaps dependency
SUPPORT_V4_FB=platforms/android/com.phonegap.plugins.facebookconnect/*FacebookLib/libs/android-support-v4.jar
SUPPORT_V4=platforms/android/libs/android-support-v4.jar
[ -n "$(diff $SUPPORT_V4 $SUPPORT_V4_FB 2>/dev/null)" ] && cp -vf $SUPPORT_V4_FB $SUPPORT_V4

# Customized org.apache.cordova.file for GOOGLE_PHOTOS
cordova plugin add https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos
cordova plugin add https://github.com/sawatani/Cordova-plugin-photo
# Crash Report
cordova plugin add https://github.com/sawatani/Cordova-plugin-acra.git --variable TOAST_TEXT='Crash Report Sent' --variable URL="$ACRA_URL" --variable USERNAME="$ACRA_USERNAME" --variable PASSWORD="$ACRA_PASSWORD"

mod_ANDROID_XML() {
	file=platforms/android/AndroidManifest.xml
	cat $file | awk "$1" > $file.tmp && (
		diff $file $file.tmp
		mv -vf $file.tmp $file
	)
}
mod_ANDROID_XML '/<application/ { sub(">", " android:name=\"org.fathens.cordova.acra.AcraApplication\">") } { print $0 }'

# Create Icons and Splash Screens
ionic resources
