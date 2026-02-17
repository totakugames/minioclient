# Totaku Asset Manager

Kleiner S3/MinIO Asset Manager für Game Development Teams.
Gebaut mit Flutter für Windows, macOS und Linux.

## Features

- **Verbindungsprofile** — Mehrere MinIO/S3-Server speichern und verwalten
- **File Browser** — Ordnerstruktur durchsuchen mit Breadcrumb-Navigation
- **Drag & Drop Upload** — Dateien und Ordner einfach reinziehen
- **Download** — Einzelne Dateien oder ganze Ordner herunterladen
- **Transfer Queue** — Upload/Download-Fortschritt in Echtzeit
- **Dark Theme** — Modernes, augenfreundliches UI
- **Asset-Typ-Icons** — Erkennt automatisch Bilder, Audio, 3D-Modelle, Unity-Assets etc.

## Setup

### Voraussetzungen
- Flutter SDK >= 3.6.0
- Für Windows: Visual Studio mit C++ Desktop-Workload
- Für macOS: Xcode
- Für Linux: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Installation

```bash
# Repo klonen
git clone <your-repo-url>
cd totaku_asset_manager

# Dependencies installieren
flutter pub get

# Desktop-Support aktivieren (falls noch nicht)
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# App starten
flutter run -d windows   # oder macos / linux
```

### Build

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

Das fertige Build liegt unter `build/<platform>/`.

## Projektstruktur

```
lib/
├── main.dart                    # Entry Point
├── models/                      # Datenmodelle
│   ├── connection_profile.dart  # Verbindungsprofil
│   ├── s3_object.dart           # S3-Objekt (Datei/Ordner)
│   └── transfer_task.dart       # Upload/Download-Task
├── services/                    # Business Logic
│   ├── s3_service.dart          # MinIO/S3 API-Kommunikation
│   └── profile_storage_service.dart  # Profil-Persistenz
├── providers/                   # State Management (Provider)
│   ├── connection_provider.dart # Verbindungsstatus
│   ├── file_browser_provider.dart  # Navigation & Dateien
│   └── transfer_provider.dart   # Transfer-Queue
├── screens/                     # Screens
│   ├── connection_screen.dart   # Login / Profilauswahl
│   └── browser_screen.dart      # Datei-Browser
├── widgets/                     # Wiederverwendbare Widgets
│   ├── connection_dialog.dart   # Verbindungs-Dialog
│   ├── file_list_item.dart      # Datei-Zeile
│   └── transfer_panel.dart      # Transfer-Fortschritt
└── utils/                       # Hilfsfunktionen
    ├── app_theme.dart           # Dark Theme
    └── file_type_helper.dart    # Datei-Icons & Formatierung
```

## Verwendung mit MinIO

1. App starten
2. "Neue Verbindung" klicken
3. Eingeben:
   - **Name:** z.B. "Your MinIO"
   - **Server:** `s3.yourdomain.de`
   - **Port:** `443`
   - **HTTPS:** An
   - **Access Key:** Dein MINIO_ROOT_USER
   - **Secret Key:** Dein MINIO_ROOT_PASSWORD
4. Verbinden — fertig!

## Nächste Schritte (TODO)

- [ ] Datei-Vorschau (Bilder, Audio)
- [ ] Rechtsklick-Kontextmenü
- [ ] Mehrfachauswahl mit Shift/Ctrl
- [ ] Presigned URL zum Teilen
- [ ] Suche innerhalb von Buckets
- [ ] Grid-Ansicht (Thumbnails)
- [ ] Auto-Sync für bestimmte Ordner
