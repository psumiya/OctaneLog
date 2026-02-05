import Foundation
import OctaneLogCore

// Simple mock for KeychainHelper since we can't easily access the real Keychain in a CLI script properly 
// unless signed, but we can rely on ENV VAR for this test script or ask user.
// For this script, we'll try to read from Environment Variable "GEMINI_API_KEY".

@main
struct VerifyGemini3Video {
    static func main() async {
        print("🚀 Starting Gemini 3 Video Verification...")
        
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
            print("❌ Error: GEMINI_API_KEY environment variable not set.")
            print("Please run: export GEMINI_API_KEY='your_key' && swift run VerifyGemini3Video")
            exit(1)
        }
        
        let service = GeminiFileService(apiKey: apiKey)
        
        // 1. Create Valid Tiny JPEG File (Red Dot 1x1)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_image_\(UUID().uuidString).jpg")
        
        // Base64 of a valid 1x1 JPEG
        let base64Image = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
        guard let dummyData = Data(base64Encoded: base64Image) else {
            print("❌ Failed to create base64 image data")
            exit(1)
        }
        
        do {
            try dummyData.write(to: fileURL)
            print("✅ Created valid JPEG file: \(fileURL.lastPathComponent)")
            
            // 2. Upload
            print("📤 Uploading file...")
            let fileName = try await service.uploadFile(url: fileURL, mimeType: "image/jpeg") 
            
            print("✅ Upload success! Resource Name: \(fileName)")
            
            // 3. Poll
            print("⏳ Polling for ACTIVE state...")
            let fileUri = try await service.waitForActiveState(fileName: fileName)
            print("✅ File is ACTIVE. URI: \(fileUri)")
            
            // 4. List Models (Optional logging)
             print("🔍 Listing available models...")
             _ = try? await service.listModels()
            
            // 5. Generate
            print("\n🧠 Generating content with Gemini 3 Flash Preview...")
            let prompt = "Describe this image."
            let response = try await service.generateContent(
                credential: apiKey, 
                model: "gemini-3-flash-preview", 
                prompt: prompt, 
                fileURIs: [fileUri],
                mimeType: "image/jpeg"
            )
            
            print("\n🤖 Response:\n\(response)\n")
            print("✅ Verification Complete!")
            
        } catch {
            print("\n❌ Verification Failed: \(error)")
            exit(1)
        }
    }
}
