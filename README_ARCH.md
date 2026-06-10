# ARCH

## Specs

* OS: `arch`
* Window Manager: `hyprland`
* Display Manager: `ly`
* Wallpaper Daemon: `awww`
* Status Bar & Notification: `hyprpanel`
* App Launcher: `walker`
* Terminal: `kitty`
* File Manager: `thunar`, `yazi`
* Auth Agent: `hyprpolkitagent`
* Audio Server: `pipewire`
* Input Method: `fcitx5` + `rime`
* AUR Helper: `paru`
* Editor: `neovim`, `zed`, `neovide (optional)`

## Required Dependencies

### System Base

```bash
# Base development tools (required for building AUR packages)
sudo pacman -S base-devel git

# System utilities
sudo pacman -S lsb-release
```

### AUR Helper

```bash
# Install paru (AUR helper)
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### Hyprland Ecosystem

```bash
# Window Manager & Core
paru -S hyprland
paru -S ly                         # Display manager
paru -S ags-hyprpanel-git          # Status bar & notification (the `hyprpanel` AUR release also works)
paru -S hyprpolkitagent            # Authentication agent
paru -S xdg-desktop-portal-hyprland # Desktop portal (screenshots, screen sharing)
paru -S xdg-desktop-portal-gtk     # Portal fallback (file pickers)

# Wayland utilities
paru -S walker-bin                 # Application launcher (Ctrl+Space)
paru -S elephant-bin               # Walker backend service
paru -S elephant-desktopapplications-bin elephant-calc-bin elephant-menus-bin # Walker providers (apps + calc + custom menus)
paru -S grim                       # Screenshot tool
paru -S slurp                      # Screen area selector
paru -S swappy                     # Screenshot editor (hyprpanel dashboard)
paru -S satty                      # Screenshot annotator (bin/screenshot, Ctrl+Shift+3/4)
paru -S hyprpicker                 # Color picker
paru -S wl-clipboard               # Wayland clipboard (wl-copy, wl-paste)
paru -S cliphist                   # Clipboard history
paru -S clipse                     # Clipboard manager TUI
paru -S awww                       # Wallpaper Daemon
paru -S libnotify                  # Desktop notifications (notify-send)

# Media & Audio
paru -S pipewire                   # Audio server
paru -S wireplumber                # Session manager for PipeWire
paru -S pipewire-pulse             # PulseAudio replacement
paru -S pipewire-alsa              # ALSA support
paru -S playerctl                  # Media player controller
paru -S brightnessctl              # Screen brightness control

# File management
paru -S yazi                       # Terminal file manager
paru -S thunar                     # GUI file manager

# Additional utilities
paru -S inotify-tools              # File system event monitoring (for waydroid-http-share)
paru -S imagemagick                # Imagemagick
paru -S jq                         # JSON processor (bin/screenshot parses hyprctl output)
paru -S xdg-utils                  # xdg-open (hyprpanel dashboard directory shortcuts)
```

### Terminal

```bash
# Kitty terminal
paru -S kitty

# Optional: Ghostty terminal
paru -S ghostty
```

### Input Method

```bash
# Fcitx5 with Rime
paru -S fcitx5
paru -S fcitx5-rime
paru -S rime-bopomofo              # Rime 注音 (bopomofo) schema
paru -S fcitx5-configtool          # Configuration tool (optional)
paru -S fcitx5-qt                  # Qt5 support
paru -S fcitx5-gtk                 # GTK support
```

### Editors

```bash
# Neovim
paru -S neovim
paru -S neovide                    # Neovim GUI client (optional)

# Zed editor
paru -S zed

# Neovim dependencies (for LazyVim plugins)
paru -S ripgrep                    # Fast search tool
paru -S fd                         # Fast find alternative
paru -S lazygit                    # Git TUI
paru -S git-delta                  # Git Highlight
paru -S python                     # Python support
paru -S python-pip
paru -S nodejs                     # Node.js support
paru -S npm
```

### Shell Environment

```bash
# Zsh and related tools
paru -S zsh
paru -S jump                       # Directory navigation

# Optional but recommended
paru -S fzf                        # Fuzzy finder
paru -S ncdu                       # Disk usage analyzer
```

### Fonts

```bash
# Nerd Fonts for proper icon display
paru -S ttf-jetbrains-mono-nerd
paru -S ttf-meslo-nerd
```

### Optional Tools

```bash
# OCR + translation (Ctrl+Shift+2 `translate` flow, walker translate menu)
paru -S tesseract
paru -S tesseract-data-eng         # English language data
paru -S tesseract-data-chi_tra     # Traditional Chinese data
paru -S dialect                    # Translation GUI (bin/translate, elephant translate menu)

# Screen lock
paru -S betterlockscreen

# KDE Connect (for phone integration)
paru -S kdeconnect

# Waydroid (Android emulator)
paru -S waydroid

# Browser
paru -S brave-bin                  # or your preferred browser

# Music player
paru -S spotify-launcher

# System monitoring
paru -S btop                       # System monitor TUI (hyprpanel dashboard, zsh `monitor` alias)
paru -S fastfetch                  # System info (hyprpanel dashboard)
```

### NVIDIA (machine-specific)

`hyprland.conf` sets NVIDIA-specific env vars (`LIBVA_DRIVER_NAME`, `GBM_BACKEND`, ...). On NVIDIA machines install:

```bash
paru -S nvidia-open                # Open kernel modules
paru -S nvidia-utils
paru -S egl-wayland
```

### Version Managers

```bash
# Proto (multi-language version manager)
# This will be installed automatically by the install.sh script
# It manages Node.js, Python, and other language versions

# Alternatively, you can install it manually:
curl -fsSL https://moonrepo.dev/install/proto.sh | bash
```

