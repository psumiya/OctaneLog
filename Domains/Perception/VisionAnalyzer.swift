import Foundation
import AVFoundation
import Vision
import CoreImage

/// Analyzes video frames using Vision framework to extract metadata
/// This reduces the need to upload full videos to Gemini
public actor VisionAnalyzer {
    
    public struct FrameAnalysis: Sendable {
        public let timestamp: TimeInterval
        public let objects: [String]
        public let sceneClassification: String?
        public let dominantColors: [String]
        public let brightness: Double
        
        public init(timestamp: TimeInterval, objects: [String], sceneClassification: String?, dominantColors: [String], brightness: Double) {
            self.timestamp = timestamp
            self.objects = objects
            self.sceneClassification = sceneClassification
            self.dominantColors = dominantColors
            self.brightness = brightness
        }
    }
    
    public struct DriveAnalysis: Sendable {
        public let frames: [FrameAnalysis]
        public let detectedObjects: Set<String>
        public let sceneTypes: Set<String>
        public let averageBrightness: Double
        public let timeOfDay: String // "Dawn", "Day", "Dusk", "Night"
        
        public var summary: String {
            let objectList = Array(detectedObjects).prefix(10).joined(separator: ", ")
            let sceneList = Array(sceneTypes).joined(separator: ", ")
            return """
            Detected Objects: \(objectList)
            Scene Types: \(sceneList)
            Time of Day: \(timeOfDay)
            Average Brightness: \(String(format: "%.1f", averageBrightness * 100))%
            """
        }
    }
    
    public init() {}
    
    /// Analyzes a video file and extracts key metadata
    /// Samples frames every N seconds to avoid processing every frame
    public func analyzeVideo(url: URL, sampleInterval: TimeInterval = 5.0) async throws -> DriveAnalysis {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        print("VisionAnalyzer: Analyzing video (\(Int(durationSeconds))s) with \(Int(durationSeconds / sampleInterval)) samples...")
        
        var frameAnalyses: [FrameAnalysis] = []
        var allObjects = Set<String>()
        var allScenes = Set<String>()
        var totalBrightness: Double = 0
        
        // Sample frames at intervals
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        var currentTime: TimeInterval = 0
        while currentTime < durationSeconds {
            let time = CMTime(seconds: currentTime, preferredTimescale: 600)
            
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let analysis = try await analyzeFrame(cgImage: cgImage, timestamp: currentTime)
                
                frameAnalyses.append(analysis)
                allObjects.formUnion(analysis.objects)
                if let scene = analysis.sceneClassification {
                    allScenes.insert(scene)
                }
                totalBrightness += analysis.brightness
                
            } catch {
                print("VisionAnalyzer: Failed to analyze frame at \(currentTime)s: \(error)")
            }
            
            currentTime += sampleInterval
        }
        
        let avgBrightness = frameAnalyses.isEmpty ? 0 : totalBrightness / Double(frameAnalyses.count)
        let timeOfDay = determineTimeOfDay(brightness: avgBrightness)
        
        return DriveAnalysis(
            frames: frameAnalyses,
            detectedObjects: allObjects,
            sceneTypes: allScenes,
            averageBrightness: avgBrightness,
            timeOfDay: timeOfDay
        )
    }
    
    /// Analyzes a single frame
    private func analyzeFrame(cgImage: CGImage, timestamp: TimeInterval) async throws -> FrameAnalysis {
        var detectedObjects: [String] = []
        var sceneClassification: String?
        
        // 1. Object Recognition - using VNRecognizeAnimalsRequest for animals
        let animalRequest = VNRecognizeAnimalsRequest()
        
        // 2. Scene Classification
        let sceneRequest = VNClassifyImageRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([animalRequest, sceneRequest])
        
        // Extract animals
        if let results = animalRequest.results {
            for observation in results {
                if observation.confidence > 0.5 {
                    // VNRecognizedObjectObservation has labels property
                    if let label = observation.labels.first {
                        detectedObjects.append(label.identifier)
                    }
                }
            }
        }
        
        // Extract scene
        if let results = sceneRequest.results?.prefix(3) {
            for classification in results {
                if classification.confidence > 0.3 {
                    detectedObjects.append(classification.identifier)
                    if sceneClassification == nil {
                        sceneClassification = classification.identifier
                    }
                }
            }
        }
        
        // 3. Brightness Analysis
        let brightness = calculateBrightness(cgImage: cgImage)
        
        // 4. Dominant Colors
        let colors = extractDominantColors(cgImage: cgImage)
        
        return FrameAnalysis(
            timestamp: timestamp,
            objects: detectedObjects,
            sceneClassification: sceneClassification,
            dominantColors: colors,
            brightness: brightness
        )
    }
    
    private func calculateBrightness(cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]) else {
            return 0.5
        }
        guard let outputImage = filter.outputImage else { return 0.5 }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        // Calculate perceived brightness (weighted RGB)
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0
        
        return (0.299 * r + 0.587 * g + 0.114 * b)
    }
    
    private func extractDominantColors(cgImage: CGImage) -> [String] {
        // Simplified color extraction - just categorize brightness
        let brightness = calculateBrightness(cgImage: cgImage)
        
        switch brightness {
        case 0..<0.2:
            return ["dark", "night"]
        case 0.2..<0.4:
            return ["dim", "overcast"]
        case 0.4..<0.6:
            return ["moderate", "cloudy"]
        case 0.6..<0.8:
            return ["bright", "sunny"]
        default:
            return ["very bright", "glare"]
        }
    }
    
    private func determineTimeOfDay(brightness: Double) -> String {
        switch brightness {
        case 0..<0.2:
            return "Night"
        case 0.2..<0.35:
            return "Dusk/Dawn"
        case 0.35..<0.7:
            return "Day (Overcast)"
        default:
            return "Day (Sunny)"
        }
    }
}
