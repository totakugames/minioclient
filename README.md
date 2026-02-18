# MinIO Desktop Client

A open-source S3/MinIO desktop client built with Flutter.
Designed as a simple, modern alternative to the MinIO Console — especially for teams that need an easy way to browse, upload, and download files.

## Features

- **Connection Profiles** Save and manage multiple S3/MinIO server connections
- **File Browser** Navigate buckets and folders with breadcrumb navigation
- **Drag & Drop Upload** Drop files and folders directly into the app
- **Download** Download individual files or entire directories
- **Transfer Queue** Real-time progress tracking for all uploads and downloads
- **Smart File Icons** Automatically recognizes images, audio, 3D models, and more
- **Dark Theme** Clean, modern interface
- **Cross-Platform** Runs on Windows, macOS, and Linux

## Screenshots
<p align="center">
   <img width="400" alt="start screen" src="https://github.com/user-attachments/assets/da7829c0-66de-4731-b833-2500ffc48a4d" />
   &nbsp;&nbsp;&nbsp;
   <img width="400" alt="login" src="https://github.com/user-attachments/assets/fb020027-a36b-4cdc-a1d7-64e7b9879ded" />
</p>


## Getting Started

### Prerequisites
- Flutter SDK >= 3.6.0
- **Windows:** Visual Studio with C++ Desktop workload
- **macOS:** Xcode
- **Linux:** `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Installation

```bash
git clone https://github.com/totakugames/minioclient.git
cd minioclient

flutter pub get

# Enable desktop support (if not already)
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# Run
flutter run -d windows   # or macos / linux
```

### Build

```bash
flutter build windows   # or macos / linux
```

The compiled binary will be in `build/<platform>/`.

## Usage

1. Launch the app
2. Click **"New Connection"**
3. Enter your S3/MinIO details:
   - **Name:** A label for this connection
   - **Server:** Your S3 endpoint (e.g. `s3.example.com`)
   - **Port:** `443` for HTTPS, `9000` for local MinIO
   - **HTTPS:** Toggle on/off
   - **Access Key:** Your access key
   - **Secret Key:** Your secret key
4. Connect and start browsing

Works with any S3-compatible storage: **MinIO**, **AWS S3**, **Backblaze B2**, **Cloudflare R2**, **DigitalOcean Spaces**, and more.

## Project Structure

```
lib/
├── main.dart                        # Entry point
├── models/                          # Data models
│   ├── connection_profile.dart      # Server connection profile
│   ├── s3_object.dart               # S3 object (file/folder)
│   └── transfer_task.dart           # Upload/download task
├── services/                        # Core logic
│   ├── s3_service.dart              # S3 API communication
│   └── profile_storage_service.dart # Profile persistence
├── providers/                       # State management (Provider)
│   ├── connection_provider.dart     # Connection state
│   ├── file_browser_provider.dart   # Navigation & file listing
│   └── transfer_provider.dart       # Transfer queue
├── screens/                         # Screens
│   ├── connection_screen.dart       # Login / profile selection
│   └── browser_screen.dart          # File browser
├── widgets/                         # Reusable widgets
│   ├── connection_dialog.dart       # Connection dialog
│   ├── file_list_item.dart          # File row
│   └── transfer_panel.dart          # Transfer progress
└── utils/                           # Helpers
    ├── app_theme.dart               # Dark theme
    └── file_type_helper.dart        # File icons & formatting
```

## Roadmap

- [ ] File preview (images, audio)
- [ ] Right-click context menu
- [ ] Multi-select with Shift/Ctrl
- [ ] Presigned URL sharing
- [ ] Search within buckets
- [ ] Grid view with thumbnails
- [ ] Auto-sync for watched folders
- [ ] Bucket creation and management

## Contributing

Contributions are welcome! Feel free to open issues, submit PRs, or fork the project.

## License

MIT
