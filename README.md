<div align="center">

# 🔐 LUKS Drive Manager

<img src="path/to/logo.png" alt="Logo" width="200"/>

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/username/luks-drive-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/username/luks-drive-manager.svg)](https://github.com/username/luks-drive-manager/commits/main)

*A powerful and user-friendly tool for managing LUKS encrypted devices with an intuitive interface*

[Features](#-features) • 
[Requirements](#-requirements) • 
[Installation](#-installation) • 
[Usage](#-usage) • 
[Screenshots](#-screenshots) • 
[Support](#-support) • 
[Security](#-security) • 
[Contributing](#-contributing) • 
[License](#-license)

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
  - [Interactive Mode](#interactive-mode)
  - [Command-Line Mode](#command-line-mode)
- [Screenshots](#-screenshots)
- [Support](#-support)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

<table>
  <tr>
    <td><b>🔍 Device Discovery</b></td>
    <td>Automatically detects and lists all available LUKS encrypted devices</td>
  </tr>
  <tr>
    <td><b>🔓 Unlock Devices</b></td>
    <td>Easily unlock encrypted LUKS volumes with password authentication</td>
  </tr>
  <tr>
    <td><b>🔒 Lock Devices</b></td>
    <td>Securely lock your devices with a single command</td>
  </tr>
  <tr>
    <td><b>💾 Header Backup</b></td>
    <td>Create and manage backups of critical LUKS headers</td>
  </tr>
  <tr>
    <td><b>🖥️ Interactive UI</b></td>
    <td>User-friendly menu with color-coded interface</td>
  </tr>
  <tr>
    <td><b>📊 Detailed Info</b></td>
    <td>Comprehensive device information display</td>
  </tr>
  <tr>
    <td><b>⚡ CLI Support</b></td>
    <td>Full command-line interface for scripting and automation</td>
  </tr>
  <tr>
    <td><b>🔄 Progress Tracking</b></td>
    <td>Visual indicators for operations in progress</td>
  </tr>
</table>

---

## 📦 Requirements

To run LUKS Drive Manager, you need the following components installed on your system:

- Bash (version 4.0 or later)
- Linux system with LUKS support
- `cryptsetup` package for LUKS operations
- `lsblk` and `blkid` utilities for device information
- `sudo` privileges for mounting/unmounting operations

---

## 📥 Installation

You can install LUKS Drive Manager by following these steps:

1. Clone the repository:

```bash
git clone https://github.com/rhythmcreative/unlock-disk.git
```

2. Navigate to the project directory:

```bash
cd unlock-disk
sudo ./install.sh
```

---

## 🚀 Usage

LUKS Drive Manager can be used in both interactive and command-line modes.

### Interactive Mode

1. Launch the script without arguments:

```bash
sudo ./unlock_drive.sh
```

2. Navigate through the interactive menu to:
   - View available LUKS devices
   - Unlock encrypted devices
   - Lock mounted devices
   - Backup LUKS headers
   - Access help and information

### Command-Line Mode

The script supports various command-line arguments for direct operations:

```bash
# List all LUKS devices
./unlock_drive.sh --list

# Unlock a specific device
./unlock_drive.sh --unlock /dev/sdX

# Lock a specific device
./unlock_drive.sh --lock /dev/sdX

# Backup LUKS header
./unlock_drive.sh --backup /dev/sdX /path/to/backup.img

# Display help
./unlock_drive.sh --help
```

---

## 📸 Screenshots
<div align="center">
  <!-- Main Menu Section -->
  <h3><i>Main Menu</i></h3>
  <img src="https://github.com/user-attachments/assets/5d9fe90d-67fd-431f-b3fc-3912cb6d4c93" alt="Main Menu Image" width="600"/>

  <br><br>

  <!-- Device Listing Section -->
  <h3><i>Device Listing</i></h3>
  <img src="https://github.com/user-attachments/assets/96f5ff5d-291f-4f9b-9cc1-ad31790fcbbe" alt="Device Listing Image" width="600"/>

  <br><br>

  <!-- Unlock Operation Section -->
  <h3><i>Unlock Operation</i></h3>
  <img src="https://github.com/user-attachments/assets/dc4712a9-c666-47b6-a394-d476126eb3f1" alt="Unlock Operation Image" width="600"/>
</div>


---

## 🤝 Support

If you encounter any issues or have questions about LUKS Drive Manager, please:

1. Check the [documentation](https://github.com/username/unlock-disk/wiki)
2. Look through existing [issues](https://github.com/username/unlock-disk/issues)
3. Create a new issue with a detailed description and steps to reproduce


---

## 👥 Contributing

Contributions are welcome! Here's how you can contribute:

Please make sure to update tests and documentation as appropriate, Thanks.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p>Made by <a href="https://github.com/rhythmcreative"></a>rhythmcreative</p>
  <p>
    <a href="https://www.tiktok.com/@rhythmcreative">Tiktok</a> •
    <a href="https://www.youtube.com/@rhythmcreative4k">Youtube</a>
  </p>
  
  <p> © 2025 LUKS Drive Manager</p>
</div>
