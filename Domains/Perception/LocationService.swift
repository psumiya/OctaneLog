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
    
    override public init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startMonitoring() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopMonitoring() {
        locationManager.stopUpdatingLocation()
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
        
        // Negative speed indicates an invalid value
        if location.speed >= 0 {
            updateState(speedMps: location.speed)
        }
    }
}
