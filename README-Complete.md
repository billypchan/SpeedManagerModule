# SpeedManagerModule - Complete Distribution Guide

This repository provides the **SpeedManagerModule**, a Swift package for real-time speed monitoring on iOS and watchOS devices using CoreLocation.

## 🚀 Quick Start

### Swift Package Manager (Recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/billypchan/SpeedManagerModule.git`

### Basic Usage

```swift
import SpeedManagerModule

class ViewController: UIViewController, SpeedManagerDelegate {
    private var speedManager: SpeedManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speedManager = SpeedManager(speedUnit: .kilometersPerHour)
        speedManager.delegate = self
        speedManager.startUpdatingSpeed()
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        print("Speed: \(speed) km/h")
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerAuthorizationStatus) {
        print("Authorization: \(status)")
    }
    
    func speedManager(_ speedManager: SpeedManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManager) {
        print("Location services unavailable")
    }
}
```

## 📦 Distribution Options

This package provides multiple integration methods to suit different project needs:

### 1. Source Distribution (Default)
- Direct Swift Package Manager integration
- Full source code access
- Supports all platforms
- Best for development and customization

### 2. Binary Distribution (Coming Soon)
- Pre-compiled XCFramework
- Faster build times
- Smaller repository size
- Best for production apps

### 3. Manual Integration
- Copy source files directly
- Full control over compilation
- No dependency management needed

## 🏗️ Building Distribution Packages

We provide several build scripts for creating different distribution formats:

### Source Distribution
```bash
./build-source-distribution.sh
```
Creates a zip file with all source code and integration instructions.

### XCFramework Attempts
```bash
# Primary build script (may need Xcode project)
./build-xcframework.sh

# Modern Swift 6.x compatible script
./build-xcframework-modern.sh

# Simple script (requires additional tools)
./build-xcframework-simple.sh
```

**Note**: Creating XCFrameworks from Swift Packages has limitations in current Swift toolchain. The source distribution is the most reliable method.

## 📱 Supported Platforms

- **iOS** 15.0+
- **watchOS** 8.0+
- **macOS** 12.0+ (for development/testing)

## 🔧 Features

- ✅ Real-time speed monitoring
- ✅ Multiple speed units (m/s, km/h, mph)
- ✅ Background location updates (optional)
- ✅ Compass heading tracking
- ✅ SwiftUI integration (`@Published` properties)
- ✅ Delegate pattern for event handling
- ✅ Cross-platform support

## 📋 Requirements

### Runtime
- iOS 15.0+ / watchOS 8.0+ / macOS 12.0+
- Swift 5.9+

### Permissions
Add these keys to your app's Info.plist:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to monitor speed.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to monitor speed in background.</string>
```

## 🎯 Integration Examples

### SwiftUI Example

```swift
import SwiftUI
import SpeedManagerModule

struct ContentView: View {
    @StateObject private var speedManager = SpeedManager(speedUnit: .kilometersPerHour)
    
    var body: some View {
        VStack {
            Text("Speed: \(speedManager.speed, specifier: "%.1f") km/h")
                .font(.largeTitle)
            
            Text("Heading: \(speedManager.degrees, specifier: "%.0f")°")
                .font(.title2)
            
            Button("Start Monitoring") {
                speedManager.startUpdatingSpeed()
            }
        }
        .padding()
    }
}
```

### UIKit Example

```swift
import UIKit
import SpeedManagerModule

class SpeedViewController: UIViewController, SpeedManagerDelegate {
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    
    private var speedManager: SpeedManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speedManager = SpeedManager(
            speedUnit: .milesPerHour,
            allowsBackgroundLocationUpdates: false
        )
        speedManager.delegate = self
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        speedManager.startUpdatingSpeed()
    }
    
    // MARK: - SpeedManagerDelegate
    
    func speedManager(_ speedManager: SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        DispatchQueue.main.async {
            self.speedLabel.text = String(format: "%.1f mph", speed)
        }
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerAuthorizationStatus) {
        switch status {
        case .authorized:
            print("Location authorized")
        case .denied:
            print("Location denied")
        case .notDetermined:
            print("Location permission not determined")
        }
    }
    
    func speedManager(_ speedManager: SpeedManager, didFailWithError error: Error) {
        print("Speed manager error: \(error.localizedDescription)")
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManager) {
        print("Location services are not available")
    }
}
```

## 📚 API Reference

### SpeedManager Class

Main class for speed monitoring functionality.

#### Initialization
```swift
SpeedManager(
    speedUnit: SpeedManagerUnit,
    trigger: SpeedManagerTrigger? = nil,
    allowsBackgroundLocationUpdates: Bool = false
)
```

#### Properties
- `speed: Double` - Current speed in specified units
- `speedAccuracy: Double` - Accuracy of speed measurement  
- `degrees: Double` - Current magnetic heading
- `location: CLLocation?` - Current location
- `authorizationStatus: SpeedManagerAuthorizationStatus` - Location permission status

#### Methods
- `startUpdatingSpeed()` - Begin speed monitoring
- `startMonitoringSpeed()` - Internal method for location updates

### SpeedManagerUnit Enum

Available speed measurement units:
- `.metersPerSecond` - Meters per second
- `.kilometersPerHour` - Kilometers per hour
- `.milesPerHour` - Miles per hour

### SpeedManagerAuthorizationStatus Enum

Location authorization states:
- `.notDetermined` - Permission not requested
- `.authorized` - Permission granted
- `.denied` - Permission denied

### SpeedManagerDelegate Protocol

Delegate methods for receiving updates:
- `speedManager(_:didUpdateSpeed:speedAccuracy:)` - Speed updates
- `speedManager(_:didUpdateAuthorizationStatus:)` - Authorization changes  
- `speedManager(_:didFailWithError:)` - Error handling
- `speedManagerDidFailWithLocationServicesUnavailable(_:)` - Service unavailable

## 🚀 CI/CD Integration

The repository includes GitHub Actions for automated building:

- `.github/workflows/build-xcframework.yml` - Automated XCFramework creation
- Triggered on version tags (v*)
- Creates GitHub releases with binary distributions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Support

- 📋 [Issues](https://github.com/billypchan/SpeedManagerModule/issues) - Bug reports and feature requests
- 💬 [Discussions](https://github.com/billypchan/SpeedManagerModule/discussions) - Questions and support

## 🔄 Version History

### 1.0.0
- Initial release
- Basic speed monitoring functionality
- iOS and watchOS support
- SwiftUI integration
- Delegate pattern implementation

---

**Note**: XCFramework distribution is currently experimental due to Swift Package Manager limitations. Source distribution via Swift Package Manager is the recommended integration method.