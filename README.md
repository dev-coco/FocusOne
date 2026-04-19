# FocusOne

FocusOne is a lightweight focus-enhancement tool designed specifically for macOS. It works by overlaying a dimmable dark mask across the screen while dynamically “cutting out” the currently active window, helping users eliminate background distractions and fully concentrate on the task at hand.

## Features

- **Smart Masking**: Automatically dims inactive areas to create an immersive working environment.  
- **Two Focus Modes**:  
  - **Single Window Mode**: Highlights only the frontmost window, ideal for deep writing or code debugging.  
  - **Current App Mode**: Highlights all windows belonging to the active application, suitable for multi-window workflows.  
- **Real-Time Tracking**: Built with `Timer` and `Core Graphics` window APIs to respond instantly to window switching, movement, and resizing.  
- **Adjustable Brightness**: Customize mask opacity from 10% to 90%.  
- **Fullscreen Awareness**: Automatically hides the mask when a fullscreen app is detected, ensuring no interference.  
- **Native Experience**: Integrated with the macOS menu bar, supports launch at login, and uses minimal system resources.  

## Getting Started

### Requirements
- macOS 14.0 (Ventura) or later  
- Xcode 14.0+ (Swift 6 / SwiftUI)  

### Permissions
Since the app needs access to window position data, please ensure the following on first launch:  
1. Open **System Settings** → **Privacy & Security** → **Accessibility**.  
2. Add **FocusOne** to the list and enable access.  