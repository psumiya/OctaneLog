# Bug Fixes Applied

## Issues Fixed

### 1. Video Recording Not Accessible in Files App
**Problem**: Videos were being saved to the app's private Documents folder but weren't accessible via the Files app.

**Fix**: Added required keys to `App/Info.plist`:
- `UIFileSharingEnabled` = true
- `LSSupportsOpeningDocumentsInPlace` = true

**Result**: Videos saved to `Documents/Drives/[DriveID]/` are now accessible through the Files app.

---

### 2. GPS Route Data Not Being Captured
**Problem**: "No Route Data Available" was showing in Garage view because route points weren't being collected.

**Root Causes & Fixes**:

a) **Accuracy Filter Too Strict**
   - Changed from `< 200m` to `< 500m` accuracy threshold
   - Now accepts initial GPS fixes which are often 200-500m in urban areas
   - File: `Domains/Perception/DirectorService.swift`

b) **Location Permission Race Condition**
   - Added 0.5s delay after requesting permission before starting monitoring
   - Ensures permission dialog is processed before location updates begin
   - File: `Domains/Perception/DirectorService.swift`

c) **Better Initialization**
   - Clear events and route arrays at start of each drive
   - Added logging to track location authorization status
   - File: `Domains/Perception/DirectorService.swift`

**Result**: Route data is now properly collected and displayed in LogDetailView.

---

### 3. Gemini Video Processing Timeout
**Problem**: Long loading spinner because video uploads were timing out after 30 seconds.

**Fixes**:

a) **Increased Timeout**
   - Changed from 30 attempts (30s) to 60 attempts (~2 minutes with backoff)
   - Added exponential backoff: 1s, 2s, 2s, 2s...
   - File: `Core/GeminiFileService.swift`

b) **Better Progress Feedback**
   - Added detailed logging for each upload step
   - Shows "Uploading clip 1/3", "Waiting for clip to be ready", etc.
   - User can see progress instead of generic "loading"
   - File: `Domains/Narrative/NarrativeAgent.swift`

c) **Improved Error Handling**
   - If all uploads fail, falls back to text-only narrative
   - Continues processing other clips if one fails
   - Clear error messages logged to console
   - File: `Domains/Narrative/NarrativeAgent.swift`

**Result**: Video processing is more reliable and user gets better feedback during upload.

---

## Testing Recommendations

1. **Test Video Recording**:
   - Start a drive, let it record for 30 seconds
   - End the drive
   - Open Files app → On My iPhone → OctaneLog → Drives
   - Verify video files are visible and playable

2. **Test GPS Tracking**:
   - Ensure location permission is set to "Always"
   - Start a drive and move around (walk/drive)
   - End the drive
   - Check Garage view → tap on the episode
   - Verify route map is displayed (not "No Route Data Available")

3. **Test Gemini Processing**:
   - Start a drive with video recording
   - End the drive
   - Watch console logs for upload progress
   - Verify narrative is generated (may take 1-2 minutes for video)
   - If upload fails, should fall back to text-only narrative

4. **Check Console Logs**:
   - Look for: "Director: Session started. Location authorized: true"
   - Look for: "Director: Finishing drive - X events, Y route points, Z video clips"
   - Look for: "GeminiFileService: File is ACTIVE. Ready for use."

---

## Additional Notes

- Videos are saved at 480p (VGA 640x480) to reduce file size and upload time
- Location accuracy filter now accepts points up to 500m accuracy
- Background task handling is already implemented in RootView for iOS
- Route data is properly passed through the entire flow: DirectorService → CockpitView → RootView → NarrativeAgent → Episode

---

## Known Limitations

1. If app is backgrounded during recording, the current clip stops (by design for iOS background limitations)
2. Video upload requires active internet connection
3. Large videos (>100MB) may still take 2+ minutes to process
4. Location tracking requires "Always" permission for best results
