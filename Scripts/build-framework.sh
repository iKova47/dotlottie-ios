#!/bin/bash

# build-framework.sh
# Builds DotLottiePlayer.xcframework with custom features

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
CONFIG_FILE="$REPO_ROOT/Configuration/BuildConfig.json"
OUTPUT_DIR="$REPO_ROOT/Sources/DotLottieCore/Custom"
SUBMODULE_PATH="$REPO_ROOT/deps/dotlottie-rs"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--config path/to/config.json] [--output path/to/output]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔨 Building Custom DotLottiePlayer Framework${NC}"
echo ""
echo "Configuration: $CONFIG_FILE"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Validate configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Parse JSON configuration
echo "📖 Reading configuration..."

# Extract renderer type
RENDERER=$(grep -o '"renderer"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"renderer"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$RENDERER" ]; then
    echo -e "${RED}❌ Failed to parse renderer from configuration${NC}"
    exit 1
fi

echo "   Renderer: $RENDERER"

# Extract enabled features dynamically from all keys in the "features" block
FEATURES=""
while IFS= read -r line; do
    FEATURE=$(echo "$line" | sed 's/.*"\([^"]*\)"[[:space:]]*:[[:space:]]*true.*/\1/')
    if [ -n "$FEATURE" ]; then
        if [ -z "$FEATURES" ]; then
            FEATURES="$FEATURE"
        else
            FEATURES="$FEATURES,$FEATURE"
        fi
        echo "   ✓ $FEATURE"
    fi
done < <(grep '"[^"]*"[[:space:]]*:[[:space:]]*true' "$CONFIG_FILE")

if [ -z "$FEATURES" ]; then
    echo -e "${YELLOW}⚠️  No features enabled. Building with defaults.${NC}"
fi

# Determine Make target
if [ "$RENDERER" = "webgpu" ]; then
    MAKE_TARGET="apple-webgpu"
    echo -e "   ${BLUE}🎮 Using WebGPU renderer${NC}"
else
    MAKE_TARGET="apple"
    echo "   Using software renderer"
fi

echo ""

# Validate submodule is initialized
if [ ! -d "$SUBMODULE_PATH" ]; then
    echo -e "${RED}❌ Submodule not found: $SUBMODULE_PATH${NC}"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

# Clean previous builds (optional, but recommended)
echo "🧹 Cleaning previous builds..."
if make -C "$REPO_ROOT" apple-clean > /dev/null 2>&1; then
    echo "   Cleaned successfully"
else
    echo "   No previous build to clean"
fi

echo ""

# Start timing
START_TIME=$(date +%s)

# Build framework with features
echo -e "${BLUE}⚙️  Building framework...${NC}"
echo "   Target: $MAKE_TARGET"
echo "   Features: $FEATURES"
echo ""

export FEATURES="$FEATURES"

if make -C "$REPO_ROOT" "$MAKE_TARGET"; then
    echo ""
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    echo "Check the error messages above for details."
    exit 1
fi

# Calculate build time
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
MINUTES=$((BUILD_TIME / 60))
SECONDS=$((BUILD_TIME % 60))

echo "   Build time: ${MINUTES}m ${SECONDS}s"

# Locate built framework
BUILT_FRAMEWORK="$REPO_ROOT/build/apple/DotLottiePlayer.xcframework"

if [ ! -d "$BUILT_FRAMEWORK" ]; then
    echo -e "${RED}❌ Built framework not found at: $BUILT_FRAMEWORK${NC}"
    exit 1
fi

# Create output directory
echo ""
echo "📦 Copying framework to output directory..."
mkdir -p "$OUTPUT_DIR"

# Remove old framework if exists
if [ -d "$OUTPUT_DIR/DotLottiePlayer.xcframework" ]; then
    echo "   Removing old framework..."
    rm -rf "$OUTPUT_DIR/DotLottiePlayer.xcframework"
fi

# Copy new framework
cp -R "$BUILT_FRAMEWORK" "$OUTPUT_DIR/"

echo -e "   ${GREEN}✓${NC} Framework copied to: $OUTPUT_DIR/DotLottiePlayer.xcframework"

# Validate framework structure
echo ""
echo "🔍 Validating framework structure..."

EXPECTED_PLATFORMS=("ios-arm64" "ios-arm64_x86_64-simulator" "macos-arm64_x86_64")
VALIDATION_PASSED=true

for PLATFORM in "${EXPECTED_PLATFORMS[@]}"; do
    PLATFORM_PATH="$OUTPUT_DIR/DotLottiePlayer.xcframework/$PLATFORM"
    if [ -d "$PLATFORM_PATH" ]; then
        echo -e "   ${GREEN}✓${NC} $PLATFORM"
    else
        echo -e "   ${RED}✗${NC} $PLATFORM (missing)"
        VALIDATION_PASSED=false
    fi
done

# Report framework size
echo ""
echo "📊 Framework size:"
FRAMEWORK_SIZE=$(du -sh "$OUTPUT_DIR/DotLottiePlayer.xcframework" | cut -f1)
echo "   Total: $FRAMEWORK_SIZE"

echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ Custom framework build completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Update your Package.swift binary target path to:"
    echo "     path: \"./Sources/DotLottieCore/Custom/DotLottiePlayer.xcframework\""
    echo ""
    echo "  2. Or if using as a local dependency, reference the custom build directory."
    echo ""
    echo "Framework location:"
    echo "  $OUTPUT_DIR/DotLottiePlayer.xcframework"
else
    echo -e "${YELLOW}⚠️  Build completed but framework structure validation failed${NC}"
    echo "Some platforms may be missing. Please review the build output."
fi
