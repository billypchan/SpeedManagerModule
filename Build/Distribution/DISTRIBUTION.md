# SpeedManagerModule - Source Distribution

This is a source distribution of SpeedManagerModule that can be integrated into iOS and watchOS projects.

## Integration Methods

### 1. Swift Package Manager (Recommended)

Add to your Package.swift:
```swift
dependencies: [
    .package(path: "./SpeedManagerModule")
]
```

### 2. Xcode Integration

1. Drag the SpeedManagerModule folder into your Xcode project
2. Make sure to add it to your target dependencies
3. Import the module: `import SpeedManagerModule`

### 3. Manual Integration

Copy the contents of the `Sources/SpeedManagerModule` folder directly into your project.

## Build Requirements

- iOS 15.0+ / watchOS 8.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Usage

```swift
import SpeedManagerModule

let speedManager = SpeedManager(speedUnit: .kilometersPerHour)
speedManager.delegate = self
speedManager.startUpdatingSpeed()
```

## Files Included

- SpeedManager.swift - Main speed monitoring class
- SpeedManagerDelegate.swift - Delegate protocol
- SpeedManagerUnit.swift - Speed unit enumeration
- SpeedManagerAuthorizationStatus.swift - Authorization status enum
- SpeedManagerTrigger.swift - Trigger protocol
