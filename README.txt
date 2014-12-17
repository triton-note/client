# Requirements

sudo npm install -g ionic
sudo npm install -g cordova
sudo npm install -g bower
sudo npm install -g gulp

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
