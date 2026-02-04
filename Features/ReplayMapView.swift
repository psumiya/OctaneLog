import SwiftUI
import MapKit

struct ReplayMapView: View {
    let route: [RoutePoint]
    
    @State private var position: MapCameraPosition = .automatic
    @State private var isPlaying = false
    @State private var progress: Double = 0.0 // 0.0 to 1.0
    
    // Animation state
    @State private var lastFrameDate: Date?
    
    // Derived state for the car's current position
    @State private var currentCoordinate: CLLocationCoordinate2D?
    @State private var currentHeading: Double = 0.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                if !route.isEmpty {
                    // The full static route path
                    MapPolyline(coordinates: route.map { $0.coordinate })
                        .stroke(Color.blue, lineWidth: 5)
                    
                    // Start Marker
                    if let start = route.first {
                        Annotation("Start", coordinate: start.coordinate) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    
                    // End Marker
                    if let end = route.last {
                        Annotation("End", coordinate: end.coordinate) {
                            Image(systemName: "flag.checkered")
                                .font(.caption)
                                .padding(4)
                                .background(Circle().fill(Color.red))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Moving Car Annotation
                    if let current = currentCoordinate {
                        Annotation("Octane", coordinate: current) {
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .padding(4)
                                .background(Circle().fill(Color.black))
                                .rotationEffect(Angle(degrees: currentHeading - 90)) // Adjust for SF Symbol orientation if needed
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            
            // Playback Controls Overlay
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    
                    VStack(spacing: 4) {
                        Slider(value: Binding(
                            get: { self.progress },
                            set: { newValue in
                                self.progress = newValue
                                updateCarPosition()
                            }
                        ), in: 0...1) { editing in
                            if editing { isPlaying = false }
                        }
                        .tint(.yellow)
                        .accentColor(.yellow)
                        
                        HStack {
                            Text(formatTime(progress * totalDuration))
                            Spacer()
                            Text(formatTime(totalDuration))
                        }
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding()
        }
        .onAppear {
            if let first = route.first {
                currentCoordinate = first.coordinate
                updateCarPosition()
            }
        }
        // Use a TimelineView for smooth animation when playing
        .overlay {
            if isPlaying {
                TimelineView(.animation) { context in
                    Color.clear
                        .onChange(of: context.date) { oldDate, newDate in
                             advanceProgress(currentTime: newDate)
                        }
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private var totalDuration: TimeInterval {
        guard let start = route.first?.timestamp, let end = route.last?.timestamp else { return 0 }
        return end.timeIntervalSince(start)
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            lastFrameDate = Date()
            if progress >= 1.0 {
                progress = 0.0
            }
        } else {
            lastFrameDate = nil
        }
    }
    
    private func advanceProgress(currentTime: Date) {
        guard let lastDate = lastFrameDate else {
            lastFrameDate = currentTime
            return
        }
        
        let delta = currentTime.timeIntervalSince(lastDate)
        lastFrameDate = currentTime
        
        let duration = totalDuration
        if duration > 0 {
            // Speed multiplier (optional, e.g. 5x speed)
            let playbackSpeed: Double = 5.0
            let progressIncrease = (delta * playbackSpeed) / duration
            
            progress += progressIncrease
            
            if progress >= 1.0 {
                progress = 1.0
                isPlaying = false
                lastFrameDate = nil
            }
            
            updateCarPosition()
        }
    }
    
    private func updateCarPosition() {
        guard !route.isEmpty else { return }
        
        if progress <= 0 {
            currentCoordinate = route.first?.coordinate
            currentHeading = 0 // Or initial heading
            return
        }
        if progress >= 1.0 {
            currentCoordinate = route.last?.coordinate
            return
        }
        
        // Find the segment corresponding to the current progress
        // We map progress (0-1) to total duration, then find where that falls in the timestamps
        let targetTimeOffset = progress * totalDuration
        let startTimestamp = route.first!.timestamp
        let targetDate = startTimestamp.addingTimeInterval(targetTimeOffset)
        
        // Find indices
        // Optimization: This linear search runs every frame. For large routes, might need optimization.
        // But for < few hundred points, it's fine.
        for i in 0..<(route.count - 1) {
            let p1 = route[i]
            let p2 = route[i+1]
            
            if p1.timestamp <= targetDate && p2.timestamp >= targetDate {
                // Interpolate between p1 and p2
                let segmentDuration = p2.timestamp.timeIntervalSince(p1.timestamp)
                let timeIntoSegment = targetDate.timeIntervalSince(p1.timestamp)
                let t = segmentDuration > 0 ? timeIntoSegment / segmentDuration : 0
                
                let lat = p1.latitude + (p2.latitude - p1.latitude) * t
                let lon = p1.longitude + (p2.longitude - p1.longitude) * t
                
                currentCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                // Calculate heading
                let dLon = p2.longitude - p1.longitude
                let y = sin(dLon) * cos(p2.latitude)
                let x = cos(p1.latitude) * sin(p2.latitude) - sin(p1.latitude) * cos(p2.latitude) * cos(dLon)
                let radians = atan2(y, x)
                currentHeading = radians * 180 / .pi
                
                return
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timeInterval) ?? "00:00"
    }
}

// Helper extension to make RoutePoint easier to use with MapKit
extension RoutePoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    let now = Date()
    let points = [
        RoutePoint(latitude: 37.7749, longitude: -122.4194, timestamp: now),
        RoutePoint(latitude: 37.7849, longitude: -122.4094, timestamp: now.addingTimeInterval(100)),
        RoutePoint(latitude: 37.7949, longitude: -122.3994, timestamp: now.addingTimeInterval(300))
    ]
    
    ReplayMapView(route: points)
        .frame(height: 400)
        .preferredColorScheme(.dark)
}
