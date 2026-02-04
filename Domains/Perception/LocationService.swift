import Foundation
import CoreLocation
import Observation

public enum DriveState: String, Sendable {
    case stationary = "Stationary" // < 5 mph
    case crawling = "Crawling"     // 5-20 mph
    case cruising = "Cruising"     // > 20 mph
}

@Observable
public class LocationService: NSObject {
    private let locationManager = CLLocationManager()
    
    public var currentSpeed: Double = 0.0 // in mph
    public var driveState: DriveState = .stationary
    public var isAuthorized = false
    public var lastLocation: CLLocation?
    
    public var onLocationUpdate: ((CLLocation, DriveState) -> Void)?

    override public init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Critical for background tracking
        #if os(iOS)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        #endif
    }
    
    public func requestPermission() {
        locationManager.requestAlwaysAuthorization() 
    }
    
    public func startMonitoring() {
        locationManager.startUpdatingLocation()
        #if os(iOS)
        locationManager.allowsBackgroundLocationUpdates = true
        #endif
    }
    
    public func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        #if os(iOS)
        locationManager.allowsBackgroundLocationUpdates = false
        #endif
    }
    
    private func updateState(speedMps: Double) {
        // Convert m/s to mph
        let speedMph = speedMps * 2.23694
        self.currentSpeed = max(0, speedMph)
        
        switch self.currentSpeed {
        case 0..<5:
            self.driveState = .stationary
        case 5..<20:
            self.driveState = .crawling
        default:
            self.driveState = .cruising
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            self.isAuthorized = true
            self.startMonitoring()
        case .denied, .restricted:
            self.isAuthorized = false
            self.stopMonitoring()
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        var effectiveSpeed = location.speed
        
        // Fallback: Calculate speed manually if invalid (-1)
        if effectiveSpeed < 0, let last = self.lastLocation {
            let distance = location.distance(from: last)
            let timeDiff = location.timestamp.timeIntervalSince(last.timestamp)
            
            // Avoid division by zero and unrealistic jumps
            if timeDiff > 0 && distance > 0 {
                effectiveSpeed = distance / timeDiff
            }
        }
        
        // Treat negative speed as 0 if still invalid after fallback
        effectiveSpeed = max(0, effectiveSpeed)
        
        updateState(speedMps: effectiveSpeed)
        
        self.lastLocation = location
        
        // Notify listener
        self.onLocationUpdate?(location, self.driveState)
    }
}
