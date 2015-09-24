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

# Facebook connect
cordova plugin add https://github.com/Wizcorp/phonegap-facebook-plugin.git --variable APP_ID="$FACEBOOK_APP_ID" --variable APP_NAME="$FACEBOOK_APP_NAME"
find platforms/android/ -name 'build.gradle' | while read file
do
	cat <<EOF > $(dirname $file)/build-extras.gradle
configurations {
    all*.exclude group: 'com.android.support', module: 'support-v4'
    all*.exclude group: 'com.android.support', module: 'support-v13'
}
EOF
done

# Customized org.apache.cordova.file for GOOGLE_PHOTOS
cordova plugin add https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos
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
