#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/android"

cat <<EOF | patch -p 0 build.gradle
22a23
> apply plugin: 'io.fabric'
26a28
>         maven { url 'https://maven.fabric.io/public' }
35a38
>             classpath 'io.fabric.tools:gradle:1.+'
50a54
>     maven { url 'https://maven.fabric.io/public' }
244a249,251
>     compile('com.crashlytics.sdk.android:crashlytics:2.5.2@aar') {
>       transitive = true
>     }
EOF

cat <<EOF > fabric.properties
apiSecret=$FABRIC_BUILD_SECRET
apiKey=$FABRIC_API_KEY
EOF

find src -name 'MainActivity.java' | while read file
do
	cat "$file" | awk '
		{print $0}
		/super.onCreate/ {
			sub("super.*", "io.fabric.sdk.android.Fabric.with(this, new com.crashlytics.android.Crashlytics());");
			print $0
		}
	' > "${file}.tmp"
	mv -vf "${file}.tmp" "$file"
done

