#!/bin/zsh
# Builds an unsigned TheChoicerVoicer-iOS.ipa: the patched Godot 4.4.1 iOS engine
# and the launcher, with no game content. Sign it with a sideloading tool.
#
#   GODOT=/path/to/Godot_v4.4.1 ios/build.sh
#
# GAME_EXE=/path/to/TheChoicerVoicer.exe takes the app icon from your copy of
# the game. ICON=/path/to/icon.svg (or a 1024x1024 .png) uses any other image.
#
# Needs macOS with Xcode, scons and the Godot 4.4.1 editor.
set -euo pipefail

REPO=${0:A:h:h}
BUILD=$REPO/ios/build
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
GODOT_TAG=4.4.1-stable
SRC=$BUILD/godot
TEMPLATES_URL=https://github.com/godotengine/godot/releases/download/$GODOT_TAG/Godot_v4.4.1-stable_export_templates.tpz

[[ $($GODOT --version) == 4.4.1.* ]] || { echo "GODOT must point to the Godot 4.4.1 editor"; exit 1; }
mkdir -p $BUILD

# 1. Godot 4.4.1 with the port's engine patches.
if [[ ! -d $SRC ]]; then
	echo "== Fetching Godot $GODOT_TAG"
	git clone -q --depth 1 --branch $GODOT_TAG https://github.com/godotengine/godot.git $SRC
	git -C $SRC apply $REPO/engine/*.patch
fi
echo "== Building the iOS engine"
(cd $SRC && scons platform=ios target=template_debug arch=arm64 debug_symbols=no -j$(sysctl -n hw.ncpu) | grep -E "error|Time elapsed" || true)
LIB=$SRC/bin/libgodot.ios.template_debug.arm64.a
[[ -f $LIB ]] || { echo "engine build failed"; exit 1; }

# 2. Export template: the official iOS template with the patched library.
if [[ ! -f $BUILD/ios_official.zip ]]; then
	echo "== Fetching the official iOS export template"
	curl -sSL -o $BUILD/templates.tpz $TEMPLATES_URL
	unzip -p $BUILD/templates.tpz templates/ios.zip > $BUILD/ios_official.zip
	rm $BUILD/templates.tpz
fi
cp $BUILD/ios_official.zip $BUILD/ios_template.zip
tmp=$(mktemp -d)
mkdir -p $tmp/libgodot.ios.debug.xcframework/ios-arm64
cp $LIB $tmp/libgodot.ios.debug.xcframework/ios-arm64/libgodot.a
(cd $tmp && zip -q $BUILD/ios_template.zip libgodot.ios.debug.xcframework/ios-arm64/libgodot.a)
rm -rf $tmp

# 3. Xcode project for the launcher, exported from a copy so ICON leaves the repo untouched.
echo "== Exporting the launcher"
rm -rf $BUILD/xcode $BUILD/launcher
mkdir -p $BUILD/xcode
rsync -a --exclude .godot $REPO/launcher/ $BUILD/launcher/
if [[ -n ${GAME_EXE:-} && -z ${ICON:-} ]]; then
	$GODOT --headless --script $REPO/ios/extract_icon.gd -- $GAME_EXE $BUILD/game_icon.png 2>&1 | grep -E "Saved|Can't|No icon" || true
	[[ -f $BUILD/game_icon.png ]] && ICON=$BUILD/game_icon.png
fi
if [[ -n ${ICON:-} ]]; then
	ext=${ICON:e:l}
	[[ $ext == svg || $ext == png ]] || { echo "ICON must be an .svg or .png"; exit 1; }
	rm -f $BUILD/launcher/icon.svg
	cp $ICON $BUILD/launcher/icon.$ext
	sed -i '' "s|res://icon.svg|res://icon.$ext|" $BUILD/launcher/project.godot
fi
$GODOT --headless --path $BUILD/launcher --import >/dev/null 2>&1 || true
$GODOT --headless --path $BUILD/launcher --export-debug "iOS" ../xcode/ChoicerVoicer.ipa >/dev/null 2>&1
[[ -d $BUILD/xcode/ChoicerVoicer.xcodeproj ]] || { echo "export failed"; exit 1; }

# 4. Unsigned build.
echo "== Building the app"
(cd $BUILD/xcode && xcodebuild -project ChoicerVoicer.xcodeproj -scheme ChoicerVoicer -configuration Debug \
	-sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath dd CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
	build | grep -E "error:|BUILD" || true)
APP=$BUILD/xcode/dd/Build/Products/Debug-iphoneos/ChoicerVoicer.app
[[ -d $APP ]] || { echo "app build failed"; exit 1; }

# Godot 4.4 predates UIScene, which iOS 27 requires of apps built with its SDK;
# stamping an older SDK keeps the app on the legacy lifecycle.
xcrun vtool -set-build-version ios 15.0 18.0 -replace -output $APP/ChoicerVoicer.tmp $APP/ChoicerVoicer 2>/dev/null
mv $APP/ChoicerVoicer.tmp $APP/ChoicerVoicer
chmod +x $APP/ChoicerVoicer
# Debug symbols carry the build machine's paths.
xcrun strip -S $APP/ChoicerVoicer
rm -rf $APP/_CodeSignature $APP/embedded.mobileprovision

# 5. IPA.
rm -rf $BUILD/ipa $BUILD/TheChoicerVoicer-iOS.ipa
mkdir -p $BUILD/ipa/Payload
cp -R $APP $BUILD/ipa/Payload/
(cd $BUILD/ipa && zip -qry ../TheChoicerVoicer-iOS.ipa Payload)
echo "== $BUILD/TheChoicerVoicer-iOS.ipa"
