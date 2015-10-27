#!/bin/sh

target=$(ls platforms/ios/*/*-Info.plist)
echo "Editing $target"

domain="amazonaws.com"
parent="NSAppTransportSecurity:NSExceptionDomains:$domain"

/usr/libexec/PlistBuddy -c "Delete ${parent}" "$target"
/usr/libexec/PlistBuddy -c "Add ${parent}:NSThirdPartyExceptionMinimumTLSVersion string 'TLSv1.0'" "$target"
/usr/libexec/PlistBuddy -c "Add ${parent}:NSThirdPartyExceptionRequiresForwardSecrecy bool false" "$target"
/usr/libexec/PlistBuddy -c "Add ${parent}:NSIncludesSubdomains bool true" "$target"
