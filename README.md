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

### Option 3: Run on Device (Detailed)
### Option 3: Run on Device (Simplified)
Because we configured an "Executable Target" in the package, you can run it directly:

1.  **Open Project**:
    ```bash
    open Package.swift
    ```
2.  **Select Target**:
    -   In the top bar (Scheme selector), confirm **OctaneLogApp** is selected.
    -   Select your **iPhone** as the destination.
3.  **Run**:
    -   Press **Run** (Play icon).
    -   Xcode will automatically handle the signing (ensure a Team is selected in the project settings if prompted, usually "Personal Team" works automatically).

