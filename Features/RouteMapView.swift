import SwiftUI
import MapKit
import CoreLocation

struct RouteMapView: View {
    let route: [RoutePoint]
    
    var body: some View {
        Map {
            if !route.isEmpty {
                MapPolyline(coordinates: route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                    .stroke(.blue, lineWidth: 4)
                
                if let start = route.first {
                    Annotation("Start", coordinate: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)) {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.green)
                            .padding(4)
                            .background(Circle().fill(.white))
                    }
                }
                
                if let end = route.last {
                    Annotation("End", coordinate: CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude)) {
                        Image(systemName: "flag.checkered")
                            .foregroundStyle(.red)
                            .padding(4)
                            .background(Circle().fill(.white))
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview {
    RouteMapView(route: [
        RoutePoint(latitude: 37.7749, longitude: -122.4194, timestamp: Date()),
        RoutePoint(latitude: 37.7799, longitude: -122.4294, timestamp: Date().addingTimeInterval(60))
    ])
    .frame(height: 300)
}
