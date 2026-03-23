#!/bin/bash

# validate-environment.sh
# Validates that all prerequisites are installed for building custom frameworks

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating build environment..."
echo ""

EXIT_CODE=0

# Check Rust compiler
echo -n "Checking for Rust compiler (rustc)... "
if command -v rustc &> /dev/null; then
    RUSTC_VERSION=$(rustc --version)
    echo -e "${GREEN}✓${NC} $RUSTC_VERSION"
else
    echo -e "${RED}✗${NC} Not found"
    echo "  ❌ Rust compiler (rustc) is not installed"
    echo "  📦 Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    EXIT_CODE=1
fi

# Check Cargo
echo -n "Checking for Cargo build tool... "
if command -v cargo &> /dev/null; then
    CARGO_VERSION=$(cargo --version)
    echo -e "${GREEN}✓${NC} $CARGO_VERSION"
else
    echo -e "${RED}✗${NC} Not found"
    echo "  ❌ Cargo is not installed"
    echo "  📦 Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    EXIT_CODE=1
fi

# Check Rust nightly toolchain
echo -n "Checking for Rust nightly toolchain... "
if command -v rustup &> /dev/null; then
    if rustup toolchain list | grep -q nightly; then
        NIGHTLY_VERSION=$(rustup run nightly rustc --version 2>/dev/null || echo "nightly (version unknown)")
        echo -e "${GREEN}✓${NC} $NIGHTLY_VERSION"
    else
        echo -e "${RED}✗${NC} Not installed"
        echo "  ❌ Rust nightly toolchain is required"
        echo "  📦 Install via: rustup toolchain install nightly"
        EXIT_CODE=1
    fi
else
    echo -e "${RED}✗${NC} rustup not found"
    echo "  ❌ rustup is required to manage Rust toolchains"
    echo "  📦 Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    EXIT_CODE=1
fi

# Check Xcode command line tools
echo -n "Checking for Xcode command line tools... "
if xcode-select -p &> /dev/null; then
    XCODE_PATH=$(xcode-select -p)
    echo -e "${GREEN}✓${NC} $XCODE_PATH"
else
    echo -e "${RED}✗${NC} Not found"
    echo "  ❌ Xcode command line tools are not installed"
    echo "  📦 Install via: xcode-select --install"
    EXIT_CODE=1
fi

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check dotlottie-rs submodule
echo -n "Checking dotlottie-rs submodule... "
SUBMODULE_PATH="$REPO_ROOT/deps/dotlottie-rs"
if [ -d "$SUBMODULE_PATH" ]; then
    if [ -f "$SUBMODULE_PATH/Makefile" ]; then
        echo -e "${GREEN}✓${NC} Initialized"
    else
        echo -e "${YELLOW}⚠${NC} Directory exists but appears uninitialized"
        echo "  ⚠️  Submodule directory exists but is missing Makefile"
        echo "  📦 Initialize via: git submodule update --init --recursive"
        EXIT_CODE=1
    fi
else
    echo -e "${RED}✗${NC} Not found"
    echo "  ❌ dotlottie-rs submodule is not initialized"
    echo "  📦 Initialize via: git submodule update --init --recursive"
    EXIT_CODE=1
fi

# Check thorvg nested submodule (critical dependency)
echo -n "Checking thorvg nested submodule... "
THORVG_PATH="$SUBMODULE_PATH/dotlottie-rs/deps/thorvg"
if [ -d "$THORVG_PATH" ]; then
    # Check if thorvg has actual content (not just empty directory)
    if [ -f "$THORVG_PATH/meson.build" ] || [ -d "$THORVG_PATH/src" ]; then
        echo -e "${GREEN}✓${NC} Initialized"
    else
        echo -e "${RED}✗${NC} Directory exists but is empty"
        echo "  ❌ thorvg submodule is not initialized (nested submodule)"
        echo "  📦 Initialize via: git submodule update --init --recursive"
        echo "  💡 Note: Must use --recursive flag to initialize nested submodules"
        EXIT_CODE=1
    fi
else
    echo -e "${RED}✗${NC} Not found"
    echo "  ❌ thorvg submodule is missing (nested within dotlottie-rs)"
    echo "  📦 Initialize via: git submodule update --init --recursive"
    echo "  💡 Note: Must use --recursive flag to initialize nested submodules"
    EXIT_CODE=1
fi

# Check Makefile exists
echo -n "Checking for dotlottie-rs Makefile... "
if [ -f "$SUBMODULE_PATH/Makefile" ]; then
    echo -e "${GREEN}✓${NC} Found"
else
    echo -e "${RED}✗${NC} Not found at $SUBMODULE_PATH/Makefile"
    echo "  ❌ Makefile is missing from dotlottie-rs submodule"
    echo "  📦 Initialize submodule via: git submodule update --init --recursive"
    EXIT_CODE=1
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Environment validation passed!${NC}"
    echo "   All required dependencies are installed."
else
    echo -e "${RED}❌ Environment validation failed!${NC}"
    echo "   Please install missing dependencies before building custom framework."
    echo ""
    echo "Quick setup guide:"
    echo "  1. Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "  2. Install nightly: rustup toolchain install nightly"
    echo "  3. Initialize submodules: git submodule update --init --recursive"
    echo "     ⚠️  IMPORTANT: The --recursive flag is required to initialize nested submodules (thorvg)"
    echo ""
    echo "For detailed instructions, see CUSTOM_BUILDS.md"
fi

exit $EXIT_CODE
