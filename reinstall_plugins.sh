rm -rf platforms/
rm -rf plugins/
mkdir -vp plugins

cordova prepare $1

# Create Icons and Splash Screens
ionic resources
