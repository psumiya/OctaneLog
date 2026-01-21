import Foundation
import Vision
import CoreImage
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Responsible for detecting and redacting sensitive information (PII) from images
/// before they leave the device.
/// - Scans for Faces (Bystanders)
/// - Scans for Text (License Plates, Street Signs)
public actor PrivacyService {
    
    public init() {}
    
    /// Redacts faces and text from the provided image.
    /// Returns: JPEG Data of the redacted image.
    public func scrub(image: CGImage) async -> Data? {
        let reqGroup = DispatchGroup()
        
        var rectsToRedact: [CGRect] = []
        
        // 1. Setup Requests
        let faceRequest = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else { return }
            let boxes = results.map { $0.boundingBox }
            DispatchQueue.main.async { // Mutate on consistent thread or use lock, but here we just collect
                rectsToRedact.append(contentsOf: boxes)
            }
        }
        
        let textRequest = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            let boxes = results.map { $0.boundingBox } // Top candidate bouning box
            DispatchQueue.main.async {
                rectsToRedact.append(contentsOf: boxes)
            }
        }
        textRequest.recognitionLevel = .fast // We just need to find *where* text is, accuracy matters less
        
        // 2. Perform Requests
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([faceRequest, textRequest])
        } catch {
            print("PrivacyService: Failed to perform Vision requests: \(error)")
            // Fail safe: If privacy fails, we should probably NOT return the original image? 
            // For MVP, we return nil to block the upload.
            return nil 
        }
        
        // 3. Draw Redactions
        guard !rectsToRedact.isEmpty else {
            // Nothing to redact, return original as JPEG
            return convertToData(image: image)
        }
        
        return redact(image: image, normalizedRects: rectsToRedact)
    }
    
    private func redact(image: CGImage, normalizedRects: [CGRect]) -> Data? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        // Draw original
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw Black Rectangles
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
        
        for normRect in normalizedRects {
            // Vision coordinates are normalized (0...1) with origin at bottom-left.
            // CoreGraphics usually has origin at bottom-left too, but CGContext coordinate systems can vary based on platform.
            // Standard approach:
            let rect = VNImageRectForNormalizedRect(normRect, Int(width), Int(height))
            context.fill(rect)
        }
        
        // Export
        guard let newImage = context.makeImage() else { return nil }
        return convertToData(image: newImage)
    }
    
    private func convertToData(image: CGImage) -> Data? {
        #if os(macOS)
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        return bitmapRep.representation(using: .jpeg, properties: [:])
        #else
        let uiImage = UIImage(cgImage: image)
        return uiImage.jpegData(compressionQuality: 0.8)
        #endif
    }
}
