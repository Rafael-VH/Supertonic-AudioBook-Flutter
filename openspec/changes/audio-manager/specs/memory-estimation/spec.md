# Memory Estimation Specification

## Purpose

Estimate total RAM usage before processing audio files and warn the user if the estimate exceeds 70% of available system memory, allowing them to proceed or cancel.

## Requirements

### Requirement: Pre-processing memory estimate (MEM-1) — Priority: must

Before processing begins, the system MUST estimate total RAM usage as the sum of (file characters × estimated bytes per character) for all selected files. This estimate MUST be compared with available system RAM.

#### Scenario: Estimate within safe range

- GIVEN 3 files totaling 10,000 characters and 16 GB available RAM
- WHEN processing is about to start
- THEN the estimate (~80 KB) is below 70% of available RAM
- AND processing starts without showing a warning

#### Scenario: Estimate exceeds 70% threshold

- GIVEN 50 files totaling 50,000,000 characters and 8 GB available RAM
- WHEN processing is about to start
- THEN a warning dialog is shown before processing begins

### Requirement: Warning dialog content (MEM-2) — Priority: must

The warning dialog MUST display the estimated RAM usage, the available system RAM, and offer two actions: Proceed and Cancel.

#### Scenario: Warning dialog shows RAM details

- GIVEN estimated RAM exceeds 70% of available RAM
- WHEN the warning dialog appears
- THEN it displays estimated RAM usage, available RAM, and Proceed/Cancel buttons

#### Scenario: User cancels processing

- GIVEN the warning dialog is shown
- WHEN the user taps Cancel
- THEN processing does NOT start
- AND the user returns to the file selection screen

#### Scenario: User chooses to proceed

- GIVEN the warning dialog is shown
- WHEN the user taps Proceed
- THEN processing starts despite the warning

### Requirement: Platform-aware memory detection (MEM-3) — Priority: must

The system MUST use `ProcessInfo.currentRss` on desktop platforms and a platform channel approximation on mobile to read available system RAM.

#### Scenario: Desktop memory detection

- GIVEN the app runs on macOS/Linux/Windows
- WHEN the system queries available RAM
- THEN `ProcessInfo.currentRss` is used

#### Scenario: Mobile memory detection

- GIVEN the app runs on iOS or Android
- WHEN the system queries available RAM
- THEN a platform channel approximation is used

### Requirement: Graceful fallback on detection failure (MEM-4) — Priority: should

If available RAM cannot be determined, the system MUST assume safe (below threshold) and proceed without showing a warning. The system MUST NOT block processing due to a detection failure.

#### Scenario: RAM detection fails

- GIVEN the system cannot read available RAM (unsupported platform or error)
- WHEN processing is about to start
- THEN processing proceeds without showing a memory warning
