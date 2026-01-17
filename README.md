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

