# Audio Pending Management Specification

## Purpose

List processed audio files as pending saves (temp WAVs in `_temp/`), allowing users to review, choose destination folders, rename, and confirm save before any file is written to its final location. Also covers temp file lifecycle and orphan cleanup.

## Requirements

### Requirement: Temp WAV exposed after processing (APM-1) — Priority: must

Processing MUST leave WAV files in `_temp/` under the output directory. The user MUST NOT be auto-saved. Each processed file MUST appear in the "Audios Generados" screen with its temp path, filename, format, duration, and file size.

#### Scenario: Processing produces temp files without saving

- GIVEN user has selected one or more files for processing
- WHEN processing completes
- THEN WAV files exist in `_temp/` under the output directory
- AND the user is navigated to "Audios Generados" (not saved automatically)

#### Scenario: Each item shows metadata

- GIVEN one temp WAV exists in `_temp/`
- WHEN the "Audios Generados" screen renders
- THEN each item displays filename, original format, duration, and file size

### Requirement: Per-item actions (APM-2) — Priority: must

Each audio item MUST have a "More" menu with three options: Choose folder (folder picker), Rename (text input dialog), and Confirm save. Confirm save MUST write the file to the chosen location with the chosen name, then delete the temp file.

#### Scenario: Choose folder for an audio

- GIVEN a pending audio item
- WHEN user opens the More menu and selects "Choose folder"
- THEN a native folder picker opens
- AND the selected folder is stored as the destination for that item

#### Scenario: Rename an audio

- GIVEN a pending audio item named "libro1"
- WHEN user selects Rename and enters "mi_libro"
- THEN the display name updates to "mi_libro"
- AND the original filename is preserved for reference

#### Scenario: Confirm save writes file and cleans temp

- GIVEN a pending audio with a chosen folder and name
- WHEN user confirms save
- THEN the WAV is converted to the chosen format and moved to the destination
- AND the temp file is deleted from `_temp/`
- AND the item is removed from the pending list

#### Scenario: Save without choosing folder

- GIVEN a pending audio with no folder selected
- WHEN user confirms save
- THEN the system MUST prompt for a folder before proceeding

### Requirement: Batch save all (APM-3) — Priority: must

A "Save All" button MUST be available that saves all pending audios using their individually chosen folders/names. Audios without a chosen folder MUST be skipped or prompted.

#### Scenario: Save All with all items configured

- GIVEN 3 pending audios, each with a chosen folder and name
- WHEN user taps "Save All"
- THEN all 3 are saved to their respective destinations
- AND all temp files are deleted

#### Scenario: Save All with some items unconfigured

- GIVEN 3 pending audios, 1 without a chosen folder
- WHEN user taps "Save All"
- THEN the 2 configured audios are saved
- AND the unconfigured audio is skipped (or the user is prompted)

### Requirement: Temp file cleanup on startup (APM-4) — Priority: must

On app startup, the system MUST scan `_temp/` and delete any WAV files older than 24 hours. This prevents orphan accumulation.

#### Scenario: Orphan files older than 24h are deleted

- GIVEN `_temp/` contains WAV files from a previous session (>24h old)
- WHEN the app starts
- THEN all files older than 24 hours are deleted from `_temp/`

#### Scenario: Recent temp files are preserved

- GIVEN `_temp/` contains a WAV file created 1 hour ago
- WHEN the app starts
- THEN the file is preserved

### Requirement: Mode-aware processing (APM-5) — Priority: must

In file mode, the system MUST process only the user-selected files. In folder mode, the system MUST process all `.md` files in the selected folder.

#### Scenario: File mode processes only selected files

- GIVEN user selects 3 specific `.md` files
- WHEN processing starts
- THEN only those 3 files are processed (no additional files)

#### Scenario: Folder mode processes all .md files

- GIVEN user selects a folder containing 10 `.md` files
- WHEN processing starts
- THEN all 10 `.md` files are processed

#### Scenario: Folder mode skips non-.md files

- GIVEN a folder contains 7 `.md` files and 3 `.txt` files
- WHEN processing starts in folder mode
- THEN only the 7 `.md` files are processed

### Requirement: File name conflict on save (APM-6) — Priority: should

Before writing to the destination, the system MUST check if a file with the same name already exists. If so, it MUST show a dialog offering Replace, Rename, or Cancel.

#### Scenario: Destination file already exists

- GIVEN the user confirms save to a folder where "libro1.mp3" already exists
- WHEN the save is attempted
- THEN a conflict dialog appears with Replace, Rename, and Cancel options

#### Scenario: Destination file does not exist

- GIVEN the user confirms save to an empty folder
- WHEN the save is attempted
- THEN the file is written without conflict
