set -x # echo on
set +e # switch off exit on error
curr_path=${BASH_SOURCE%/*}

# check that all the required environment vars are set
: "${EVOX_QT_PATH:?variable not set, see also macosx_build_config.command}"
: "${EVOX_BOOST_ROOT:?variable not set, see also macosx_build_config.command}"
: "${EVOX_BOOST_LIBS_PATH:?variable not set, see also macosx_build_config.command}"
: "${EVOX_BUILD_DIR:?variable not set, see also macosx_build_config.command}"
: "${CMAKE_OSX_SYSROOT:?CMAKE_OSX_SYSROOT should be set to macOS SDK path, e.g.: /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk}"

ARCHIVE_NAME_PREFIX=evox-macos-x64-

if [ -n "$build_prefix" ]; then
  ARCHIVE_NAME_PREFIX=${ARCHIVE_NAME_PREFIX}${build_prefix}-
  build_prefix_label="$build_prefix "
fi

if [ "$testnet" == true ]; then
  testnet_def="-D TESTNET=TRUE"
  testnet_label="testnet "
  ARCHIVE_NAME_PREFIX=${ARCHIVE_NAME_PREFIX}testnet-
fi

######### DEBUG ##########
#cd "$EVOX_BUILD_DIR/release/src"
#rm *.dmg
#if false; then
##### end of DEBUG ######

rm -rf $EVOX_BUILD_DIR; mkdir -p "$EVOX_BUILD_DIR/release"; cd "$EVOX_BUILD_DIR/release"

cmake $testnet_def -D CMAKE_OSX_SYSROOT=$CMAKE_OSX_SYSROOT -D BUILD_GUI=TRUE -D CMAKE_PREFIX_PATH="$EVOX_QT_PATH/clang_64" -D CMAKE_BUILD_TYPE=Release -D BOOST_ROOT="$EVOX_BOOST_ROOT" -D BOOST_LIBRARYDIR="$EVOX_BOOST_LIBS_PATH" ../..
if [ $? -ne 0 ]; then
    echo "Failed to cmake"
    exit 1
fi



make -j Evox
if [ $? -ne 0 ]; then
    echo "Failed to make Evox"
    exit 1
fi

make -j connectivity_tool daemon simplewallet
if [ $? -ne 0 ]; then
    echo "Failed to make binaries!"
    exit 1
fi


cd src/
if [ $? -ne 0 ]; then
    echo "Failed to cd src"
    exit 1
fi

# copy all necessary libs into the bundle in order to workaround El Capitan's SIP restrictions
mkdir -p Evox.app/Contents/Frameworks/boost_libs
cp -R "$EVOX_BOOST_LIBS_PATH/" Evox.app/Contents/Frameworks/boost_libs/
if [ $? -ne 0 ]; then
    echo "Failed to cp workaround to MacOS"
    exit 1
fi

# rename process name to big letter 
mv Evox.app/Contents/MacOS/evox Evox.app/Contents/MacOS/Evox
if [ $? -ne 0 ]; then
    echo "Failed to rename process"
    exit 1
fi

cp evoxd simplewallet Evox.app/Contents/MacOS/
if [ $? -ne 0 ]; then
    echo "Failed to copy binaries to Evox.app folder"
    exit 1
fi

# fix boost libs paths in main executable and libs to workaround El Capitan's SIP restrictions
source ../../../utils/macosx_fix_boost_libs_path.sh
fix_boost_libs_in_binary @executable_path/../Frameworks/boost_libs Evox.app/Contents/MacOS/Evox
fix_boost_libs_in_binary @executable_path/../Frameworks/boost_libs Evox.app/Contents/MacOS/simplewallet
fix_boost_libs_in_binary @executable_path/../Frameworks/boost_libs Evox.app/Contents/MacOS/evoxd
fix_boost_libs_in_libs @executable_path/../Frameworks/boost_libs Evox.app/Contents/Frameworks/boost_libs



"$EVOX_QT_PATH/clang_64/bin/macdeployqt" Evox.app
if [ $? -ne 0 ]; then
    echo "Failed to macdeployqt Evox.app"
    exit 1
fi



rsync -a ../../../src/gui/qt-daemon/layout/html Evox.app/Contents/MacOS --exclude less --exclude package.json --exclude gulpfile.js
if [ $? -ne 0 ]; then
    echo "Failed to cp html to MacOS"
    exit 1
fi

cp ../../../src/gui/qt-daemon/app.icns Evox.app/Contents/Resources
if [ $? -ne 0 ]; then
    echo "Failed to cp app.icns to resources"
    exit 1
fi

codesign -s "Developer ID Application: Evox Limited" --timestamp --options runtime -f --entitlements ../../../utils/macos_entitlements.plist --deep ./Evox.app
if [ $? -ne 0 ]; then
    echo "Failed to sign Evox.app"
    exit 1
fi


read version_str <<< $(DYLD_LIBRARY_PATH=$EVOX_BOOST_LIBS_PATH ./connectivity_tool --version | awk '/^Evox/ { print $2 }')
version_str=${version_str}
echo $version_str


echo "############### Prepearing archive... ################"
mkdir package_folder
if [ $? -ne 0 ]; then
    echo "Failed to zip app"
    exit 1
fi

mv Evox.app package_folder 
if [ $? -ne 0 ]; then
    echo "Failed to top app package"
    exit 1
fi

#fi

package_filename=${ARCHIVE_NAME_PREFIX}${version_str}.dmg

source ../../../utils/macosx_dmg_builder.sh
build_fancy_dmg package_folder $package_filename
if [ $? -ne 0 ]; then
    echo "Failed to create fancy dmg"
    exit 1
fi

echo "Build success"

echo "############### Uploading... ################"

package_filepath=$package_filename

scp $package_filepath evox_build_server:/var/www/html/builds/
if [ $? -ne 0 ]; then
    echo "Failed to upload to remote server"
    exit 1
fi


read checksum <<< $( shasum -a 256 $package_filepath | awk '/^/ { print $1 }' )

mail_msg="New ${build_prefix_label}${testnet_label}build for macOS-x64:<br>
https://build.evox.org/builds/$package_filename<br>
sha256: $checksum"

echo "$mail_msg"

echo "$mail_msg" | mail -s "Evox macOS-x64 ${build_prefix_label}${testnet_label}build $version_str" ${emails}


######################
# notarization
######################

cd package_folder

echo "Notarizing..."

# creating archive for notarizing
echo "Creating archive for notarizing"
rm -f Evox.zip
/usr/bin/ditto -c -k --keepParent ./Evox.app ./Evox.zip

tmpfile="tmptmptmp"
xcrun altool --notarize-app --primary-bundle-id "org.evox.desktop" -u "andrey@zano.org" -p "@keychain:Developer-altool" --file ./Evox.zip > $tmpfile 2>&1
NOTARIZE_RES=$?
NOTARIZE_OUTPUT=$( cat $tmpfile )
rm $tmpfile
echo "NOTARIZE_OUTPUT=$NOTARIZE_OUTPUT"
if [ $NOTARIZE_RES -ne 0 ]; then
    echo "Notarization failed"
    exit 1
fi

GUID=$(echo "$NOTARIZE_OUTPUT" | egrep -Ewo '[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}')
if [ ${#GUID} -ne 36 ]; then
    echo "Couldn't get correct GUID from the response, got only \"$GUID\""
    exit 1
fi


success=0

# check notarization status
for i in {1..10}; do
    xcrun altool --notarization-info $GUID -u "andrey@zano.org" -p "@keychain:Developer-altool" > $tmpfile 2>&1
    NOTARIZE_OUTPUT=$( cat $tmpfile )
    rm $tmpfile 
    NOTARIZATION_LOG_URL=$(echo "$NOTARIZE_OUTPUT" | sed -n "s/.*LogFileURL\: \([[:graph:]]*\).*/\1/p")
    if [ ${#NOTARIZATION_LOG_URL} -ge 30 ]; then
        success=1
        curl -L $NOTARIZATION_LOG_URL
        break
    fi
    sleep 60 
done

if [ $success -ne 1 ]; then
    echo "Build notarization failed"
    exit 1
fi

echo "Notarization done"
