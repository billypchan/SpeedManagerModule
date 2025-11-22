<p align="center" >
</p>

[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fezefranca%2FSpeedManagerModule%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ezefranca/SpeedManagerModule)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fezefranca%2FSpeedManagerModule%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ezefranca/SpeedManagerModule)
![github workflow](https://github.com/ezefranca/SpeedManagerModule/actions/workflows/swift.yml/badge.svg)
[![License][license-image]][license-url]
[![Twitter](https://img.shields.io/badge/twitter-@ezefranca-blue.svg?style=flat)](http://twitter.com/ezefranca)

# SpeedManagerModule
> Simple Speedometer class to iOS and WatchOS.

Measure the speed using an iPhone or Apple Watch.


https://github.com/user-attachments/assets/fbee0a69-a993-4de2-aebb-9459533b0800

> [!NOTE]
> The Demo UI was created using [LidorFadida](https://github.com/LidorFadida/) package [SpeedometerSwiftUI](https://github.com/LidorFadida/SpeedometerSwiftUI)

### Motivation

I like to measure my speed inside trains and buses. When I was searching for a speedometer app, the majority of them were ugly, with tons of ads. I was searching for an Apple Watch Speedometer with complications, iOS App with Widgets and did not found. Because of that I decided to create my own app. First thing was measure speed using `CLLocationManager`.

## Installation

The Swift Package Manager is the easiest way to install and manage SpeedManagerModule as a dependency.

### Swift Package Manager

#### Package.swift
Add SpeedManagerModule to your dependencies in your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/ezefranca/SpeedManagerModule.git")
]
```

#### Xcode Integration
1. **Open your Xcode project**
2. **File** → **Add Package Dependencies**
3. **Enter repository URL**: `https://github.com/ezefranca/SpeedManagerModule.git`
4. **Select version**: Choose "Up to Next Major Version" 
5. **Add to target**: Select your app target and click "Add Package"

### Binary Distribution (XCFramework)

For faster build times, you can use the pre-compiled binary version:

1. **Download from Releases**:
   - Go to [Releases](https://github.com/ezefranca/SpeedManagerModule/releases)
   - Download `SpeedManagerModule.xcframework.zip`
   - Extract the `.xcframework` file

2. **Add to Xcode**:
   - Drag `SpeedManagerModule.xcframework` into your project
   - ✅ Check "Copy items if needed"
   - ✅ Add to your app target

3. **Alternative: Use Binary Package**:
   - Xcode automatically uses binary version when available
   - No additional configuration needed

### Update Info.plist

Add the correct permission descriptions

```xml
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Your description why you should use NSLocationAlwaysAndWhenInUseUsageDescription</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Your description why you should use NSLocationAlwaysAndWhenInUseUsageDescription</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Your description why you should use NSLocationAlwaysAndWhenInUseUsageDescription</string>
```

Add the background location updates in xcode

![](https://raw.githubusercontent.com/ezefranca/SpeedManagerModule/main/.github/backgroundmodes.png)

Or add the info to the Info.plist

```xml
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
```

## Usage example

### @StateObject

```swift
import SwiftUI

struct ContentView: View {
    
    @StateObject var speedManager = SpeedManager(.kilometersPerHour)
    
    var body: some View {
        VStack {
            switch speedManager.authorizationStatus {
            case .authorized:
                Text("Your current speed is:")
                Text("\(speedManager.speed)")
            default:
                Spacer()
            }
        }
    }
}
```

### Using Delegates

```swift
import UIKit

class SpeedViewController: UIViewController {

    var speedManager = SpeedManager(.kilometersPerHour)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.speedManager.delegate = self
        self.speedManager.startUpdatingSpeed()
    }
}

extension SpeedViewController: SpeedManagerDelegate {
    
    func speedManager(_ manager: SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        // Update UI with the current speed and accuracy
    }
    
    func speedManager(_ manager: SpeedManager, didFailWithError error: Error) {
        // Handle error
    }
    
    func speedManager(_ speedManager: SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerAuthorizationStatus) {
        // Handle authorization status update
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManager) {
        // Handle location services unavailable
    }
}
```

### Changing Unit

Just choose the unit during the class init.

```swift
    var speedManagerKmh = SpeedManager(.kilometersPerHour)
    var speedManagerMs = SpeedManager(.metersPerSecond)
    var speedManagerMph = SpeedManager(.milesPerHour)
```

### Demo 

Check the `Demo` folder to see it in action.


## Meta

@ezefranca – [@ezefranca](https://twitter.com/ezefranca) 

Distributed under the MIT license. See `LICENSE` for more information.

[https://github.com/ezefranca/SpeedManagerModule](https://github.com/ezefranca/SpeedManagerModule)

[swift-image]:https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt
