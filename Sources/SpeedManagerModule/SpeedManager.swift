import Foundation
import CoreLocation

public protocol SpeedManagerTrigger {
    func startUpdatingSpeed()
    func startMonitoringSpeed()
}

public class SpeedManager : NSObject, ObservableObject, SpeedManagerTrigger {
    
    // MARK: Private
    private let locationManager = CLLocationManager()
    private var speedUnit: SpeedManagerUnit
    private var trigger: SpeedManagerTrigger?
    private var allowsBackgroundLocationUpdates: Bool = false
    
    // MARK: Public
    public var delegate: SpeedManagerDelegate?
   
    @Published public var authorizationStatus: SpeedManagerAuthorizationStatus = .notDetermined

    @Published public var speed: Double = 0
    @Published public var speedAccuracy: Double = 0
    @Published public var location: CLLocation?

    private var isRequestingLocation = false
    
    public init(_ speedUnit: SpeedManagerUnit,
                trigger: SpeedManagerTrigger? = nil,
                allowsBackgroundLocationUpdates: Bool = false) {
        
        self.speedUnit = speedUnit
        self.delegate = nil
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        super.init()
        self.trigger = trigger ?? self
       
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLHeadingFilterNone
        
        self.locationManager.requestAlwaysAuthorization()
    }
    
    public func startUpdatingSpeed() {
        trigger?.startMonitoringSpeed()
    }
    
    public func startMonitoringSpeed() {
        
        switch self.authorizationStatus {
            
        case .authorized:
            if allowsBackgroundLocationUpdates { self.locationManager.allowsBackgroundLocationUpdates = true
            }
            self.locationManager.startUpdatingLocation()
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
        case .denied:
            fatalError("No location services available")
        }
    }
}

// MARK: CLLocationManagerDelegate methods

extension SpeedManager: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            
        case .authorizedWhenInUse,
                .authorizedAlways:
            authorizationStatus = .authorized
            locationManager.requestLocation() 
            break
            
        case .notDetermined:
            authorizationStatus = .notDetermined
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            authorizationStatus = .denied
        }
        
        self.startMonitoringSpeed()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        location = locations.last

        let currentSpeed = location?.speed ?? 0
        speed = currentSpeed >= 0 ? currentSpeed * speedUnit.rawValue : .nan
        speedAccuracy = location?.speedAccuracy ?? .nan

        self.delegate?.speedManager(self, didUpdateSpeed: speed, speedAccuracy: speedAccuracy)

        self.locationManager.requestLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.delegate?.speedManager(self, didFailWithError: error)
    }
}
