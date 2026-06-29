# PRD: Offline Markdown Viewer & Editor — Android App

**Version:** 1.0  
**Platform:** Android  
**Framework:** Flutter  
**Status:** Ready for Development

---

## 1. Overview

A minimal, offline-only Android app that lets users open, read, edit, and save copies of Markdown (`.md`) files stored on their device. No internet required. No accounts. No sync. Just a clean, fast, local Markdown tool.

---

## 2. Goals

- Open and render any `.md` file from local device storage
- Edit the raw Markdown source
- Render code blocks with syntax highlighting, exactly as seen in standard Markdown renderers
- Save edited content as a copy of the original file with one tap
- Support light and dark mode
- Stay minimal — no unnecessary features, no heavy dependencies

---

## 3. Non-Goals

- No cloud sync or remote file access
- No AI or automation features
- No real-time collaboration
- No export to PDF or HTML
- No image upload or media embedding
- No folder management or file renaming

---

## 4. Target User

Android users who work with Markdown files — developers, writers, note-takers — who want a clean local viewer and editor without installing a desktop app or connecting to the internet.

---

## 5. Screens & Navigation

```
App Launch
 └── Home Screen
      ├── Recent Files List
      └── [Open File] Button
           └── System File Picker (.md files only)
                └── Reader Screen
                     ├── [Preview] tab — rendered Markdown
                     ├── [Edit] tab — raw text editor
                     └── Bottom Bar
                          └── [Save Edits as Copy] button
```

### 5.1 Home Screen

- Displays a list of recently opened `.md` files (file name + last opened time)
- One prominent **"Open File"** button to pick a new file from storage
- Empty state: friendly message — *"No files opened yet. Tap + to open a Markdown file."*
- Tapping a recent file reopens it directly
- Long press on a recent file shows option to **remove from recents** (does not delete the file)

### 5.2 Reader Screen

- Top bar: file name (truncated if long) + back arrow + theme toggle icon
- Pill-style toggle below top bar: **Preview | Edit**
- Content area switches between rendered preview and raw editor based on toggle
- Bottom bar (visible in both modes): **"Save Edits as Copy"** button

### 5.3 No Other Screens

No settings screen. No about screen. Theme preference is toggled inline.

---

## 6. Feature Specifications

### 6.1 File Picker

- Uses system file picker (`file_picker` package)
- Filters to `.md` files only
- On selection, reads file content and opens Reader Screen
- Handles storage permission request gracefully (explains why permission is needed if denied)

### 6.2 Preview Mode

- Renders Markdown using `flutter_markdown` package
- Supports standard Markdown: headings, bold, italic, blockquotes, lists, tables, links, images (local paths), horizontal rules
- **Code blocks**: syntax-highlighted using `flutter_highlight` or `markdown_widget` with highlight support
  - Inline code: monospace font, subtle background pill
  - Fenced code blocks (` ``` `): full syntax coloring per language (e.g. Dart, Python, JS, Bash, JSON, HTML)
  - Language tag (e.g. ` ```python `) used to apply correct highlighter theme
  - Code block has a subtle bordered container with a slight background tint
  - Light mode: light code theme (e.g. `github` or `atom-one-light`)
  - Dark mode: dark code theme (e.g. `atom-one-dark` or `vs2015`)
- Preview is scrollable, no horizontal overflow

### 6.3 Edit Mode

- Plain text editor (`TextField` with `maxLines: null`)
- Monospace font (e.g. `JetBrains Mono` or `Source Code Pro` via Google Fonts)
- Font size: 14sp
- Soft keyboard opens automatically when Edit tab is tapped
- No toolbar, no formatting buttons — raw text only
- Edits are held in memory; original file is never modified
- Scroll position is preserved when toggling between Preview and Edit

### 6.4 Save Edits as Copy

- Triggered only by tapping **"Save Edits as Copy"** button
- Saves the current edited text as a new file in the **same directory** as the original
- Naming logic:
  - Default: `originalname_copy.md`
  - If `originalname_copy.md` already exists: `originalname_copy_1.md`, `_2.md`, etc.
- After save: shows a non-intrusive **snackbar** — *"Saved as originalname_copy.md"*
- Button is always visible, even if no edits have been made (saves current content as-is)
- Does not close the screen or navigate away after saving

### 6.5 Light & Dark Mode

- Follows system theme by default
- Manual toggle via icon in the top bar of Reader Screen (sun/moon icon)
- Preference saved locally via `shared_preferences`
- Color palette:

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#1E1E1E` |
| Surface / Cards | `#F5F5F5` | `#2A2A2A` |
| Top bar | `#FFFFFF` | `#1E1E1E` |
| Primary accent | `#5C6BC0` (Indigo) | `#7986CB` |
| Text primary | `#1A1A1A` | `#E8E8E8` |
| Text secondary | `#757575` | `#9E9E9E` |
| Code block bg | `#F0F0F0` | `#2D2D2D` |
| Border / divider | `#E0E0E0` | `#3A3A3A` |

---

## 7. Flutter Package List

| Package | Purpose |
|---|---|
| `flutter_markdown` | Markdown rendering |
| `markdown_widget` | Extended markdown with code highlight support (use instead of flutter_markdown if better code block control is needed) |
| `flutter_highlight` | Syntax highlighting for code blocks |
| `highlight` | Language grammar definitions |
| `file_picker` | System file picker |
| `permission_handler` | Android storage permissions |
| `path_provider` | File system paths |
| `shared_preferences` | Theme preference persistence |
| `google_fonts` | Monospace font for editor |

---

## 8. Android Permissions

Declare in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

- For Android 13+ (API 33+), use `READ_MEDIA_DOCUMENTS` or rely on the system file picker URI approach (no broad storage permission needed when using file picker intent)
- Request permissions at runtime before showing file picker
- If denied, show an inline message with a **"Grant Permission"** button that opens app settings

---

## 9. UI & Design Guidelines

- **No splash screen**
- **No onboarding**
- **No bottom navigation bar**
- Typography: system default sans-serif for UI, monospace only in edit mode and code blocks
- Border radius: 12dp for cards, 20dp for pill toggle, 8dp for buttons
- Elevation: minimal — use borders/tint instead of heavy shadows
- Icon style: Material Symbols (outlined variant)
- Animations: keep to system defaults — no custom page transitions needed
- FAB: use for "Open File" on home screen only

---

## 10. Edge Cases to Handle

| Scenario | Behavior |
|---|---|
| File is very large (>1MB) | Show a loading indicator briefly while reading |
| File has no language tag on code block | Render as plain monospace, no crash |
| Storage permission permanently denied | Show inline explanation + button to open app settings |
| Duplicate copy file name exists | Auto-increment suffix: `_copy_1`, `_copy_2` |
| User hits back with unsaved edits | No warning — edits are in-memory and expected to be discarded unless "Save as Copy" was used |
| File not found in recents | Show toast: *"File no longer available"* and remove from list |
| Empty `.md` file | Show empty state in preview: *"This file is empty."* |

---

## 11. Build & Delivery Instructions (via Antigravity Agent)

Use these prompts in sequence inside your Antigravity IDE:

**Step 1 — Project Setup**
```
Create a new Flutter project named 'md_editor'. 
Add these dependencies to pubspec.yaml: flutter_markdown, 
flutter_highlight, highlight, file_picker, permission_handler, 
path_provider, shared_preferences, google_fonts.
Run flutter pub get.
```

**Step 2 — Home Screen**
```
Build the Home Screen with a list of recently opened .md files 
stored in shared_preferences. Add a FloatingActionButton to open 
the system file picker filtered to .md files. Support light and 
dark mode via system theme and a manual toggle saved to 
shared_preferences.
```

**Step 3 — Reader Screen with Preview**
```
Build the Reader Screen. Add a pill toggle between Preview and Edit 
modes. In Preview mode, render the markdown using flutter_markdown. 
For code blocks, use flutter_highlight to apply syntax highlighting 
with the 'atom-one-light' theme in light mode and 'atom-one-dark' 
in dark mode. Show inline code with a monospace font and subtle 
background.
```

**Step 4 — Edit Mode**
```
In Edit mode, show a scrollable TextField with monospace font 
(JetBrains Mono via google_fonts), font size 14, no toolbar. 
Hold edits in memory only. Preserve scroll position when toggling 
between Preview and Edit tabs.
```

**Step 5 — Save as Copy**
```
Add a 'Save Edits as Copy' button in the bottom bar of the Reader 
Screen. On tap, write the current edited text to the same directory 
as the original file, named originalname_copy.md. If that name 
exists, increment: _copy_1.md, _copy_2.md, etc. Show a snackbar 
with the saved file name. Handle WRITE_EXTERNAL_STORAGE permission.
```

**Step 6 — Permissions**
```
Add runtime permission handling for storage using permission_handler. 
For Android 13+, use the file picker URI approach. If permission is 
denied, show an inline message with a button to open app settings.
```

**Step 7 — Build APK**
```
Install Flutter SDK and Android build tools in the agent environment 
if not already present. Run 'flutter build apk --release'. 
Provide the output APK file located at build/app/outputs/flutter-apk/app-release.apk.
```

---

## 12. Acceptance Criteria

- [ ] App opens `.md` files from device storage via file picker
- [ ] Preview renders headings, lists, bold, italic, blockquotes, tables, links correctly
- [ ] Code blocks display with syntax highlighting, correct colors per light/dark mode
- [ ] Inline code renders with monospace font and background tint
- [ ] Edit mode shows raw text in monospace font, fully editable
- [ ] Toggling between Preview and Edit preserves scroll position
- [ ] "Save Edits as Copy" saves file in same directory with correct naming
- [ ] Snackbar confirms save with file name
- [ ] Light and dark mode work correctly across all screens
- [ ] Theme toggle persists across app restarts
- [ ] Recent files list updates correctly
- [ ] App works fully offline
- [ ] APK installs and runs on Android 10+ (API 29+)

---

*End of PRD*
