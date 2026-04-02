# dotlottie-ios Makefile
# Owns the build process for DotLottiePlayer.xcframework from deps/dotlottie-rs

.PHONY: all help apple apple-webgpu apple-clean apple-setup clean setup

# Default target
all: help

# Include platform makefiles
include make/apple.mk

help:
	@echo "dotlottie-ios Build System"
	@echo "=========================="
	@echo ""
	@echo "Apple Targets:"
	@echo "  make apple                   - Build DotLottiePlayer.xcframework (software renderer)"
	@echo "  make apple-webgpu            - Build DotLottiePlayer.xcframework (WebGPU renderer)"
	@echo "  make apple-ios               - Build iOS slices only"
	@echo "  make apple-macos             - Build macOS slices only"
	@echo "  make apple-ios-arm64         - Build iOS ARM64 (device)"
	@echo "  make apple-ios-sim-arm64     - Build iOS ARM64 simulator"
	@echo "  make apple-macos-arm64       - Build macOS ARM64"
	@echo "  make apple-macos-x86_64      - Build macOS x86_64"
	@echo ""
	@echo "Setup / Clean:"
	@echo "  make apple-setup             - Install required Rust targets"
	@echo "  make apple-clean             - Clean Apple build artifacts"
	@echo "  make clean                   - Clean all build artifacts"
	@echo ""
	@echo "Output:"
	@echo "  build/apple/DotLottiePlayer.xcframework"
	@echo ""
	@echo "Override features:"
	@echo "  make apple FEATURES=tvg-webp,tvg-png,tvg-jpg"
	@echo ""

setup: apple-setup

clean: apple-clean
	@rm -rf build/
