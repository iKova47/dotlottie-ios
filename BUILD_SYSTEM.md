## Custom Builds

By default, dotLottie-iOS uses a prebuilt XCFramework with all standard features enabled. This works great for most use cases and requires no additional setup.

If you need **smaller binary sizes** you can build a custom framework with only the features you need:

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/LottieFiles/dotlottie-ios.git
cd dotlottie-ios

# 2. Initialize submodules
git submodule update --init --recursive

# 3. Edit configuration
nano Configuration/BuildConfig.json

# 4. Build custom framework
swift package plugin --allow-writing-to-package-directory build-custom-framework

# 5. Update Package.swift to use custom build
# Change path to: "./Sources/DotLottieCore/Custom/DotLottiePlayer.xcframework"
```

### Prerequisites

**Required:** Rust toolchain (rustup, cargo, nightly)

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install nightly toolchain
rustup toolchain install nightly

# Verify installation
./Scripts/validate-environment.sh
```

### Why Build Custom?

✅ **Reduce binary size by 30-60%** - Disable unused image formats and features
✅ **Optimize for your use case** - Enable only PNG if that's all you use

**Note:** Custom builds are for advanced users who need specific optimizations. The standard prebuilt framework works perfectly for most applications.

---
    