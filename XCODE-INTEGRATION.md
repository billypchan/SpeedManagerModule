# Xcode Integration Guide - SpeedManagerModule

This guide provides detailed instructions for integrating SpeedManagerModule into your Xcode project using various methods.

## 📱 Quick Integration (Recommended)

### Method 1: Swift Package Manager in Xcode

**Step-by-step instructions:**

1. **Open your Xcode project**

2. **Add Package Dependency**:
   - **File** → **Add Package Dependencies...**
   - Or right-click your project in Navigator → **Add Package Dependencies...**

3. **Enter Repository URL**:
   ```
   https://github.com/billypchan/SpeedManagerModule.git
   ```

4. **Configure Version Requirements**:
   - **Dependency Rule**: "Up to Next Major Version"
   - **Version**: `1.0.0` (or latest)
   - Click **"Add Package"**

5. **Select Target**:
   - ✅ Check your app target
   - ✅ Check your watch extension (if applicable)
   - Click **"Add Package"**

6. **Verify Installation**:
   - Check Project Navigator for `SpeedManagerModule`
   - Should appear under "Package Dependencies"

## 🚀 Binary Distribution (Faster Builds)

### Method 2: XCFramework Integration

For production apps with faster build times:

#### Option A: Download Pre-built XCFramework

1. **Download Binary**:
   - Go to [Releases](https://github.com/billypchan/SpeedManagerModule/releases)
   - Download latest `SpeedManagerModule.xcframework.zip`
   - Extract to get `SpeedManagerModule.xcframework`

2. **Add to Xcode Project**:
   - **Drag & Drop** the `.xcframework` into your project
   - **Destination**: Choose "Copy items if needed" ✅
   - **Add to target**: Select your app target ✅
   - **Create groups** (not folder references)

3. **Verify Framework Linking**:
   - Project Settings → General → Frameworks, Libraries, and Embedded Content
   - `SpeedManagerModule.xcframework` should be listed
   - **Embed & Sign** should be selected

#### Option B: Use Binary Package Dependency

1. **Add Package Dependency** (same as Method 1)
2. **Xcode automatically detects** and uses binary version
3. **Faster builds** without additional configuration

### Method 3: Local Development Setup

For contributors or customization needs:

1. **Clone Repository**:
   ```bash
   git clone https://github.com/billypchan/SpeedManagerModule.git
   cd SpeedManagerModule
   ```

2. **Add Local Package**:
   - Xcode → **File** → **Add Package Dependencies...**
   - Click **"Add Local..."**
   - Navigate to and select the `SpeedManagerModule` folder
   - Add to your target

3. **Development Benefits**:
   - ✅ Direct source code access
   - ✅ Real-time debugging
   - ✅ Ability to modify and test changes

## 🛠 Configuration

### Required Permissions

Add these keys to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to monitor your speed.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to monitor your speed, including in the background.</string>
```

### Background Capabilities (Optional)

For background speed monitoring:

1. **Project Settings** → **Signing & Capabilities**
2. **+ Capability** → **Background Modes**
3. ✅ **Location updates**

Or add to `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## 💻 Usage in Code

### SwiftUI Implementation

```swift
import SwiftUI
import SpeedManagerModule

struct ContentView: View {
    @StateObject private var speedManager = SpeedManager(speedUnit: .kilometersPerHour)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Speed Monitor")
                .font(.title)
            
            Group {
                switch speedManager.authorizationStatus {
                case .authorized:
                    VStack {
                        Text("\(speedManager.speed, specifier: "%.1f")")
                            .font(.system(size: 48, weight: .bold))
                        Text("km/h")
                            .font(.title2)
                    }
                    
                case .denied:
                    Text("Location access denied")
                        .foregroundColor(.red)
                    
                case .notDetermined:
                    Text("Requesting location permission...")
                        .foregroundColor(.orange)
                }
            }
            
            Button("Start Monitoring") {
                speedManager.startUpdatingSpeed()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### UIKit Implementation

```swift
import UIKit
import SpeedManagerModule

class SpeedViewController: UIViewController {
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var speedManager: SpeedManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speedManager = SpeedManager(
            speedUnit: .kilometersPerHour,
            allowsBackgroundLocationUpdates: false
        )
        speedManager.delegate = self
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        speedManager.startUpdatingSpeed()
    }
}

extension SpeedViewController: SpeedManagerDelegate {
    func speedManager(_ speedManager: SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        DispatchQueue.main.async {
            self.speedLabel.text = String(format: "%.1f km/h", speed)
        }
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                self.statusLabel.text = "Location Authorized"
            case .denied:
                self.statusLabel.text = "Location Denied"
            case .notDetermined:
                self.statusLabel.text = "Location Permission Pending"
            }
        }
    }
    
    func speedManager(_ speedManager: SpeedManager, didFailWithError error: Error) {
        print("Speed manager error: \(error.localizedDescription)")
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManager) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Location Services Unavailable"
        }
    }
}
```

## 🔧 Troubleshooting

### Common Issues

#### Package Not Found
- ✅ Check internet connection
- ✅ Verify repository URL
- ✅ Try: File → Packages → Reset Package Caches

#### Build Errors
- ✅ Clean Build Folder (Product → Clean Build Folder)
- ✅ Delete Derived Data
- ✅ Restart Xcode

#### XCFramework Issues
- ✅ Verify framework is added to correct target
- ✅ Check "Embed & Sign" is selected
- ✅ Ensure minimum iOS/watchOS version compatibility

#### Location Permission Issues
- ✅ Check Info.plist has location usage descriptions
- ✅ Test on device (simulator may behave differently)
- ✅ Check device location settings

### Performance Optimization

#### Choose Right Distribution Method

| Method | Build Time | Debug Capability | Use Case |
|--------|------------|------------------|----------|
| **Source Package** | Slower | ✅ Full debugging | Development, customization |
| **Binary Package** | ⚡ Faster | Limited | Production, CI/CD |
| **Local Package** | Moderate | ✅ Full debugging | Contributing, testing |

#### Build Performance Tips

1. **Use Binary Distribution** for production builds
2. **Enable Build Caching** in Xcode settings
3. **Use Incremental Builds** during development
4. **Consider Modular Architecture** for large projects

## 📚 Additional Resources

- **Complete Documentation**: [README-Complete.md](README-Complete.md)
- **Binary Package Guide**: [BINARY-PACKAGE-GUIDE.md](BINARY-PACKAGE-GUIDE.md)
- **API Reference**: See source code documentation
- **Sample Projects**: Check Demo folder
- **GitHub Issues**: [Report problems](https://github.com/billypchan/SpeedManagerModule/issues)

## 🎯 Next Steps

1. **Follow this guide** to integrate the package
2. **Add required permissions** to Info.plist
3. **Test on device** with location services
4. **Explore advanced features** like background monitoring
5. **Check out sample implementations** in the Demo folder

---

*For the most up-to-date integration instructions, always refer to the latest documentation in the repository.*