# SpeedManagerModule - Complete Distribution Guide

This repository provides the **SpeedManagerModule**, a Swift package for real-time speed monitoring on iOS and watchOS devices using CoreLocation.

## 🚀 Quick Start

### Swift Package Manager (Recommended)

#### Option 1: Package.swift
Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")
]
```

#### Option 2: Xcode Integration
1. **Open your Xcode project**
2. **File** → **Add Package Dependencies**
3. **Enter the repository URL**: `https://github.com/billypchan/SpeedManagerModule.git`
4. **Choose version requirements**:
   - Select "Up to Next Major Version" and enter `1.0.0`
   - Or choose "Exact Version" for a specific release
5. **Click "Add Package"**
6. **Select your target** and click "Add Package"

#### Option 3: Xcode with Binary Distribution (When Available)
For faster build times with pre-compiled XCFramework:

1. **Download the XCFramework**:
   - Go to [Releases](https://github.com/billypchan/SpeedManagerModule/releases)
   - Download `SpeedManagerModule.xcframework.zip`
   - Extract the `.xcframework` file

2. **Add to Xcode Project**:
   - Drag the `SpeedManagerModule.xcframework` into your project
   - Select "Copy items if needed"
   - Add to your app target

3. **Alternative: Use Binary Package Dependency**:
   - File → Add Package Dependencies
   - Enter: `https://github.com/billypchan/SpeedManagerModule.git`
   - Xcode will automatically use the binary version if available

#### Option 4: Local Package Development
For local development or customization:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/billypchan/SpeedManagerModule.git
   ```

2. **Add Local Package in Xcode**:
   - File → Add Package Dependencies
   - Click "Add Local..."
   - Select the cloned `SpeedManagerModule` folder
   - Add to your target

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

## 📦 Binary Package Integration

### Understanding Distribution Types

This package supports both **source** and **binary** distribution methods:

- **Source Distribution**: Downloads and compiles source code (default)
- **Binary Distribution**: Uses pre-compiled XCFramework for faster builds

### Xcode Binary Package Setup

#### Method 1: Automatic Binary Detection (Recommended)

When binary distribution is available, Xcode automatically prefers it:

1. **Add Package Dependency**:
   ```
   File → Add Package Dependencies
   Repository: https://github.com/billypchan/SpeedManagerModule.git
   ```

2. **Xcode automatically chooses**:
   - Binary version (if available) for faster builds
   - Source version (fallback) if binary isn't available

3. **Verify Binary Usage**:
   - Check project navigator for `SpeedManagerModule` (binary icon)
   - Build times should be significantly faster

#### Method 2: Manual XCFramework Integration

For direct XCFramework integration:

1. **Download Binary Release**:
   - Visit [Releases](https://github.com/billypchan/SpeedManagerModule/releases)
   - Download latest `SpeedManagerModule.xcframework.zip`
   - Extract to get `SpeedManagerModule.xcframework`

2. **Add to Xcode Project**:
   ```
   Project Navigator → Right-click your project
   → "Add Files to [ProjectName]"
   → Select SpeedManagerModule.xcframework
   → ✅ "Copy items if needed"
   → ✅ Add to target
   ```

3. **Configure Framework Search Paths** (if needed):
   - Project settings → Build Settings
   - Search for "Framework Search Paths"
   - Add path to XCFramework if not automatic

4. **Import and Use**:
   ```swift
   import SpeedManagerModule
   // Ready to use!
   ```

#### Method 3: Local Binary Package

For testing binary builds locally:

1. **Build Locally**:
   ```bash
   git clone https://github.com/billypchan/SpeedManagerModule.git
   cd SpeedManagerModule
   ./build-source-distribution.sh  # Creates distribution package
   ```

2. **Use Local Package**:
   ```
   Xcode → File → Add Package Dependencies
   → "Add Local..."
   → Select the cloned folder
   ```

### Binary vs Source Comparison

| Feature | Source Distribution | Binary Distribution |
|---------|-------------------|-------------------|
| **Build Time** | Slower (compiles every time) | ⚡ **Faster** (pre-compiled) |
| **Download Size** | Smaller initial download | Larger download |
| **Debugging** | ✅ **Full source access** | Limited to public interfaces |
| **Customization** | ✅ **Fully customizable** | Read-only |
| **Platform Support** | ✅ **All Swift platforms** | iOS 15+, watchOS 8+ only |
| **Swift Version** | ✅ **Adapts automatically** | Fixed Swift version |
| **Xcode Integration** | ✅ **Seamless** | ✅ **Seamless** |

### Troubleshooting Binary Integration

#### XCFramework Not Found
```bash
# Verify XCFramework structure
find . -name "*.xcframework" -exec ls -la {} \;
```

#### Build Errors with Binary
1. **Clean Build Folder**: Product → Clean Build Folder
2. **Reset Package Cache**: 
   ```
   File → Packages → Reset Package Caches
   ```
3. **Update Package**: 
   ```
   File → Packages → Update to Latest Package Versions
   ```

#### Fallback to Source
If binary distribution has issues:
1. Remove binary package dependency
2. Add source dependency:
   ```swift
   .package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")
   ```

### Performance Benefits

**Binary Distribution Advantages**:
- ⚡ **3-5x faster** clean builds
- 📦 **Reduced compilation overhead** 
- 🔄 **Faster CI/CD pipelines**
- 💾 **Lower memory usage** during builds

**When to Use Each Method**:
- **Binary**: Production apps, CI/CD, large teams
- **Source**: Development, debugging, customization needs

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