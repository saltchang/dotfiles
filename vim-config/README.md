# VIM Configs

Instructions for setting up Neovim configuration on various platforms.

## Requirements

- **Neovim** >= 0.11.0
- **Nerd Fonts** (Recommended for icons)
- **GCC/Clang** (Required for compiling treesitter parsers)

## Installation

### Arch Linux

Install Editor and GUI:

```bash
paru -S neovim neovide
```

Install Dependencies:

- `ripgrep`: for Telescope
- `fd`: for looking for files
- `wl-clipboard`: Wayland system clipboard
- `unzip`, `gzip`, `tar`: for Mason to install LSP servers

```bash
paru -S ripgrep fd wl-clipboard unzip gzip tar
```

Optional Runtimes:

```bash
paru -S npm python-pip go
```

### Debian / Ubuntu

Ensure you have a recent version of Neovim (apt repositories often have outdated versions).
For Ubuntu, you can use the unstable PPA:

```bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```

Install Dependencies:

```bash
sudo apt install ripgrep fd-find unzip gzip tar xclip curl build-essential
```

> **Note**: On Debian/Ubuntu, `fd` is often installed as `fdfind`. You may need to link it:
>
> ```bash
> ln -s $(which fdfind) ~/.local/bin/fd
> ```
>
> Make sure `~/.local/bin` is in your `$PATH`.

Optional Runtimes:

```bash
sudo apt install npm python3-pip golang
```

### Fedora

Fedora usually ships with recent Neovim versions.

```bash
sudo dnf install neovim ripgrep fd-find unzip gzip tar xclip curl gcc-c++
```

Optional Runtimes:

```bash
sudo dnf install npm python3-pip go
```

### macOS

Using Homebrew:

```bash
brew install neovim ripgrep fd unzip gzip gnu-tar
```

Optional Runtimes:

```bash
brew install node python go
```

## GUI Clients (Optional)

This configuration works well with **Neovide**.

- **Arch Linux**: `paru -S neovide`
- **macOS**: `brew install --cask neovide`
- **Other Linux**: Please refer to the [Neovide Installation Guide](https://neovide.dev/installation.html). Using the AppImage or installing via Cargo is recommended.
