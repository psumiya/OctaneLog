# OctaneLog

> "Mundane to Octane."
> Converting seconds of mundane life into a grand narrative.

## Vision
**OctaneLog** is an iOS application that uses Multimodal AI (Gemini 3 Flash & Pro) to autonomously capture, analyze, and narrate your life on the road.

- **The Director (Flash)**: Watches the road and autonomously clips "Hidden Gems" (Classic Cars, Scenery).
- **The Editor (Pro)**: Synthesizes these moments into a Daily Episode and Yearly Saga.

## Architecture
- **Perception Domain**: Hardware-abstracted Camera logic (`VideoSourceProtocol`) & Real-time AI analysis.
- **Narrative Domain**: Generative text synthesis.
- **Identity Domain**: User profiles and vehicle metadata.

## Directory Structure
- `App/`: Main App Entry point.
- `Domains/`: Core Logic separated by Domain (Perception, Narrative, Identity).
- `Features/`: SwiftUI Views and Feature logic.
- `Core/`: Shared Utilities.

## Getting Started

### Prerequisites
- Xcode 15+
- Swift 5.9+
- Gemini API Key

### Setup
1. Open `Package.swift` in Xcode.
2. Configure `GEMINI_API_KEY` in `GeminiService.swift` or environment.
3. Run `swift build` or build the `OctaneLogCore` scheme in Xcode.

## How to Test and Run

### Option 1: Quick Verification (CLI)
If you don't want to open Xcode, you can confirm the code works by running the unit tests:
```bash
swift test
```

### Option 2: Visual Preview (Xcode)
1. Open the folder in Xcode:
   ```bash
   open Package.swift
   ```
2. In the Project Navigator (left sidebar), go to `Features` -> `CockpitView.swift`.
3. The **Canvas** (preview pane) should appear on the right. If not, press `Option + Command + Enter`.
4. You will see the "Heads-Up Display" UI in the preview.

### Option 3: Run on Device
To run the full app with camera access:
1. In Xcode, ensure the scheme (top bar) is set to `OctaneLogApp` (if available) or create a new App target referencing this package. 
2. *Note: Since this project is a Swift Package, the easiest way to run it as an App is to generate an Xcode Project not provided here, or rely on Previews.*

