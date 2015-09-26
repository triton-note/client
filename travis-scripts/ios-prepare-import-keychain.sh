#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

DIR=tmp_certs
KEYCHAIN=$HOME/Library/Keychains/ios-build.keychain
KEYCHAIN_PASSWORD=$(openssl rand -base64 48)

case "$BUILD_MODE" in
"release")
	DISTRIBUTION_CERTIFICATE_BASE64="$IOS_DISTRIBUTION_CERTIFICATE_BASE64"
	DISTRIBUTION_KEY_BASE64="$IOS_DISTRIBUTION_KEY_BASE64"
	DISTRIBUTION_KEY_PASSWORD="$IOS_DISTRIBUTION_KEY_PASSWORD"
	;;
"debug")
	DISTRIBUTION_CERTIFICATE_BASE64="$IOS_DEVELOPER_CERTIFICATE_BASE64"
        DISTRIBUTION_KEY_BASE64="$IOS_DEVELOPER_KEY_BASE64"
        DISTRIBUTION_KEY_PASSWORD="$IOS_DEVELOPER_KEY_PASSWORD"
        ;;
esac

rm -rf $DIR
mkdir -p $DIR

echo $IOS_APPLE_AUTHORITY_BASE64 | base64 -D > $DIR/apple.cer
echo $DISTRIBUTION_KEY_BASE64 | base64 -D > $DIR/dist.p12
echo $DISTRIBUTION_CERTIFICATE_BASE64 | base64 -D > $DIR/dist.cer

security create-keychain -p "$KEYCHAIN_PASSWORD" ios-build.keychain

security import $DIR/apple.cer -k $KEYCHAIN -T /usr/bin/codesign
security import $DIR/dist.cer  -k $KEYCHAIN -T /usr/bin/codesign
security import $DIR/dist.p12  -k $KEYCHAIN -T /usr/bin/codesign -P "$DISTRIBUTION_KEY_PASSWORD"

security list-keychain -s $KEYCHAIN
security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN

rm -rf $DIR

echo "Downloading profiles"
ios profiles:download:all --type distribution -u "$IOS_ITUNES_CONNECT_ACCOUNT" -p "$IOS_ITUNES_CONNECT_PASSWORD"
echo "Done"
mkdir MobileProvisionings
echo "Moving mobileprovision"
mv *.mobileprovision MobileProvisionings

BASE=~/Library/MobileDevice/Provisioning\ Profiles
mkdir -p "$BASE"
for file in MobileProvisionings/*.mobileprovision; do
  uuid=`grep UUID -A1 -a "$file" | grep -io "[-A-Z0-9]\{36\}"`
  extension="${file##*.}"
  echo "$file -> $uuid"
  cp -f "$file" "$BASE/$uuid.$extension"
done
ls -lsa "$BASE"
