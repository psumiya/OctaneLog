# Compatibility Matrix

This document tracks the verified combinations of SDKs, Models, and Platforms for **OctaneLog**.
Refer to this before upgrading dependencies or changing model strings to avoid regression.

## 🛠 Core Dependencies

| Component | Version | Status | Notes |
| :--- | :--- | :--- | :--- |
| **Swift** | `5.9` | ✅ Verified | Required for Swift Syntax macros. |
| **Xcode** | `15.0+` | ✅ Verified | |
| **SDK** | `google-generative-ai-swift` | `0.5.6` | ✅ Verified | Official Google SDK (REST-based). |

## 🤖 Model Compatibility

| Model String | SDK Version | Status | Notes |
| :--- | :--- | :--- | :--- |
| `gemini-1.5-flash` | `0.5.0` | ✅ Verified | Initial MVP model. Works reliably. |
| `gemini-2.5-flash` | `0.5.6` | ✅ Verified | **Previous Production Model.** |
| `gemini-2.5-pro` | `0.5.6` | ✅ Verified | |
| `gemini-3-flash-preview` | `0.5.6` | ✅ **VERIFIED** | **Hackathon Model.** Found in `v1beta` list. |
| `gemini-3-pro-preview` | `0.5.6` | ✅ **VERIFIED** | **Hackathon Model.** Found in `v1beta` list. |
| `nano-banana-pro-preview` | `0.5.6` | ✅ Available | For "Creative Autopilot" track. |

## 📡 Feature Support (Client-Side Only)

| Feature | Supported? | Constraints |
| :--- | :--- | :--- |
| **Text Generation** | ✅ YES | Standard `generateContent`. |
| **Vision (Static)** | ✅ YES | `generateContent` with `jpeg` data. |
| **Multimodal Live** | ❌ NO | Requires **WebSockets**. The Swift SDK is REST-only. |
| **Audio Streaming** | ❌ NO | Requires **WebSockets**. |
| **Tools (Function Calling)** | ⚠️ PARTIAL | Supported by SDK, but not currently implemented in `GeminiService`. |

## 📱 Hardware Targets

| Device | OS | Status |
| :--- | :--- | :--- |
| **iPhone 15 Pro** | iOS 17.5 | ✅ Verified | Primary testing device. |
| **iPhone 14** | iOS 17.0 | ✅ Verified | |
| **Simulator** | iOS 17.0 | ✅ Verified | Vision features work with static assets. |
