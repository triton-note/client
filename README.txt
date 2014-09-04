# Requirements

npm install -g ionic
npm install -g cordova
npm install -g bower

# Prepare

npm install
bower install

gulp bower

./reinstall_plugins.sh

gulp splash

# Build

gulp

# Run

#ionic run android
#ionic run ios