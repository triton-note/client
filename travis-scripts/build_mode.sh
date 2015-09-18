isMatch() {
	m=$(echo "$TRAVIS_BRANCH" | sed "s/$1//")
	if [ -z "$m" ]
	then
		return 0
	else
		return 1
	fi
}

isInclude() {
	for w in "$@"
	do
		isMatch $w && return 0
	done
	return 1
}

BUILD_MODE="test"

isInclude $BRANCH_DEBUG && BUILD_MODE="debug"

if [ "$MODE" != "debug" ]
then
	isInclude $BRANCH_RELEASE && BUILD_MODE="release"
fi

export BUILD_MODE
echo "BUILD_MODE=$MODE"
