
if [ $# != 1 ]; then
    echo "Usage: build.sh VersionNumber"
    exit 1
else
    echo "Version Number is :" $1
fi

# Declare Path
BUILD_DIR=./build
CONFIGURATION=Debug
#UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/deepshare_ios_v$1
IPHONE_DEVICE_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos
SIMULATE_DEVICE_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator

# Build device sdk for amd64
xcodebuild \
    -target DeepShare -sdk iphoneos \
    -configuration "${CONFIGURATION}" \
    ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" CONFIGURATION_BUILD_DIR="${IPHONE_DEVICE_BUILD_DIR}/arm64" ARCHS='arm64' VALID_ARCHS='arm64'

# Build device sdk for armv7
xcodebuild \
    -target DeepShare -sdk iphoneos \
    -configuration "${CONFIGURATION}" \
    ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" CONFIGURATION_BUILD_DIR="${IPHONE_DEVICE_BUILD_DIR}/armv7" ARCHS='armv7 armv7s' VALID_ARCHS='armv7 armv7s'

# Build device sdk for simulator x86_64
xcodebuild \
    -target DeepShare -sdk iphonesimulator \
    -configuration "${CONFIGURATION}" \
    ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" CONFIGURATION_BUILD_DIR="${SIMULATE_DEVICE_BUILD_DIR}" ARCHS='x86_64 i386' VALID_ARCHS='x86_64 i386'

# Copy the libs to the universal folder (clean it first)
rm -rf "${UNIVERSAL_OUTPUTFOLDER}"
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}/lib"
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}/demo"

# lipo to merge all the architecture into one lib
lipo -create ${IPHONE_DEVICE_BUILD_DIR}/arm64/libDeepShare.a ${IPHONE_DEVICE_BUILD_DIR}/armv7/libDeepShare.a ${SIMULATE_DEVICE_BUILD_DIR}/libDeepShare.a -output ${UNIVERSAL_OUTPUTFOLDER}/lib/libDeepShare.a

# Copy demo into the folder
find ${SIMULATE_DEVICE_BUILD_DIR} -name "*.h" -exec cp {} "${UNIVERSAL_OUTPUTFOLDER}/lib/" \;
cp -r ./demo_template/ ${UNIVERSAL_OUTPUTFOLDER}/demo
find ./DeepShareSample -name "*.[hm]" -exec cp {} "${UNIVERSAL_OUTPUTFOLDER}/demo/DeepShareDemo/DeepShareDemo/" \;
cp -r ${UNIVERSAL_OUTPUTFOLDER}/lib/ ${UNIVERSAL_OUTPUTFOLDER}/demo/DeepShareDemo/DeepShareDemo/
