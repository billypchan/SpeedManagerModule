# SpeedManagerModule - Binary Distribution

This repository provides both source and binary distribution options for the SpeedManagerModule Swift package, which provides location-based speed monitoring for iOS and watchOS applications.

## 📦 Installation Options

### Option 1: Source Distribution (Recommended for Development)

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/billypchan/SpeedManagerModule.git`

### Option 2: Binary Distribution (Faster Build Times)

Use the pre-compiled XCFramework for faster build times:

```swift
dependencies: [
    .package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")
]
```

The package will automatically use the binary version when available.

## 🚀 Quick Start

```swift
import SpeedManagerModule

class ViewController: UIViewController, SpeedManagerDelegate {
    private var speedManager: SpeedManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize with desired speed unit
        speedManager = SpeedManager(
            speedUnit: .kilometersPerHour,
            allowsBackgroundLocationUpdates: false
        )
        speedManager.delegate = self
        
        // Start monitoring speed
        speedManager.startUpdatingSpeed()
    }
    
    // MARK: - SpeedManagerDelegate
    
    func speedManager(_ speedManager: SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        print("Current speed: \(speed) km/h (accuracy: \(speedAccuracy))")
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerAuthorizationStatus) {
        switch status {
        case .authorized:
            print("Location access authorized")
        case .denied:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
        }
    }
    
    func speedManager(_ speedManager: SpeedManager, didFailWithError error: Error) {
        print("Speed manager error: \(error)")
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManager) {
        print("Location services unavailable")
    }
}
```

## 🔧 Features

- **Real-time speed monitoring** using CoreLocation
- **Multiple speed units** (m/s, km/h, mph)
- **Background location updates** (optional)
- **Heading/compass direction** tracking
- **Cross-platform support** (iOS 15+, watchOS 8+, macOS 12+)
- **SwiftUI integration** with `@Published` properties
- **Delegate pattern** for event handling

## 📱 Supported Platforms

- iOS 15.0+
- watchOS 8.0+
- macOS 12.0+ (for development/testing)

## 🛠 Building XCFramework

To build the XCFramework locally:

```bash
# Method 1: Full build with Xcode project generation
./build-xcframework.sh

# Method 2: Simple build (requires swift-create-xcframework)
./build-xcframework-simple.sh
```

The build process will create:
- `Build/SpeedManagerModule.xcframework` - The XCFramework
- `Build/SpeedManagerModule.xcframework.zip` - Compressed for distribution
- `Build/BinaryPackage.swift` - Template for binary distribution

## 🏗 Development Workflow

### For Package Maintainers

1. **Make changes** to source code
2. **Test thoroughly** on all supported platforms
3. **Build XCFramework**:
   ```bash
   ./build-xcframework.sh
   ```
4. **Create GitHub release** with the generated `.xcframework.zip`
5. **Update Package.swift** with the new URL and checksum
6. **Tag and publish** the release

### For Package Consumers

Simply update your package dependency version in Xcode or Package.swift.

## 📋 Requirements

### Runtime Requirements
- iOS 15.0+ / watchOS 8.0+ / macOS 12.0+
- Swift 5.9+

### Build Requirements (for XCFramework generation)
- Xcode 15.0+
- macOS with Apple Developer Tools
- Optional: `swift-create-xcframework` for simplified building

## 🔒 Permissions

This package requires location permissions. Add these to your app's Info.plist:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to monitor speed.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to monitor speed, including in background.</string>
```

## 📖 API Reference

### SpeedManager

The main class for speed monitoring.

#### Initialization

```swift
init(speedUnit: SpeedManagerUnit, 
     trigger: SpeedManagerTrigger? = nil,
     allowsBackgroundLocationUpdates: Bool = false)
```

#### Properties

- `speed: Double` - Current speed in specified units
- `speedAccuracy: Double` - Accuracy of speed measurement
- `degrees: Double` - Current heading in degrees (magnetic)
- `location: CLLocation?` - Current location
- `authorizationStatus: SpeedManagerAuthorizationStatus` - Location permission status

#### Methods

- `startUpdatingSpeed()` - Begin speed monitoring
- `startMonitoringSpeed()` - Start location updates

### SpeedManagerUnit

Speed measurement units:
- `.metersPerSecond` - m/s
- `.kilometersPerHour` - km/h  
- `.milesPerHour` - mph

### SpeedManagerDelegate

Protocol for receiving speed updates and events.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues & Support

Please report issues on [GitHub Issues](https://github.com/billypchan/SpeedManagerModule/issues).

For questions and support, please use [GitHub Discussions](https://github.com/billypchan/SpeedManagerModule/discussions).