# Terminal Setup

Terminal setup for zsh in macOS, Ubuntu/Debian, and Windows.

![Terminal Demo](./images/demo-terminal.png)

## Key Features

- Cross-platform support (macOS, Ubuntu/Debian, and Windows)
- Customizable zsh configuration
- [Powerline10k](https://github.com/romkatv/powerlevel10k) theme for a beautiful and informative prompt
- Zinit plugin manager with the following plugins:
  - [zdharma-continuum/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting): Provides syntax highlighting for commands while they are typed
  - [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions): Additional completion definitions for Zsh
  - [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search): Fish shell-like history search feature
  - [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): Fish-like autosuggestions for Zsh
  - Prezto modules:
    - [helper](https://github.com/sorin-ionescu/prezto/tree/master/modules/helper): Provides helper functions for other modules
    - [git](https://github.com/sorin-ionescu/prezto/tree/master/modules/git): Enhances the Git distributed version control system
    - [gnu-utility](https://github.com/sorin-ionescu/prezto/tree/master/modules/gnu-utility): Provides for the interactive use of GNU utilities on non-GNU systems
    - [utility](https://github.com/sorin-ionescu/prezto/tree/master/modules/utility): Provides general aliases and functions
- Auto-switching Node.js versions using [proto](https://moonrepo.dev/docs/proto)
- Quickly jump to different directories with [jump](https://github.com/gsamokovarov/jump)
- Git helpers and automatic version checking
- Rust version checking
- [Customizable aliases and functions](#custom-functions-and-aliases) for improved productivity
- Automatic software updates (Homebrew, apt, etc.)
- Terminal Integration
  - [iTerm2](https://iterm2.com) (macOS)
  - [Alacritty](https://alacritty.org) (macOS, Linux, Windows)
  - [Kitty](https://sw.kovidgoyal.net/kitty/) (macOS, Linux)
  - [Windows Terminal](https://github.com/microsoft/terminal) (Windows or WSL)
- Neovim Configuration
  - Modern Neovim setup with Lazy.nvim plugin manager
  - LSP support with Mason for easy language server installation
  - Beautiful UI with Telescope, Treesitter, and custom themes
  - Optimized for productivity with smart keymaps and autocompletion

## Auto Installation (Recommended)

1. To customize your own configs, you can fork this project before running the below installation script

2. Run the below to setup the terminal automatically:

    ```bash
    sudo curl -fsSL https://raw.githubusercontent.com/saltchang/terminal-setup/HEAD/install.sh | sh -
    ```

    It will setup the terminal by the below steps:

    1. Install homebrew, coreutils, python and pipx for macOS
    2. Install fonts: Meslo & Fira Code
    3. Install and setup zsh
    4. Clone this project into `$HOME/projects/personal/terminal-setup`
    5. Create a soft link from `$HOME/.zshrc` to the one in this project
    6. Create a soft link from `$HOME/.p10k.zsh` to the one in this project
    7. Create a soft link from `$HOME/.local/terminal-setup/bin` to the one in this project
    8. Optionally install pnpm
    9. Optionally install and setup terminal (iTerm2 or Kitty)
    10. Optionally install and setup Neovim with configuration

3. After the installation, restart your terminal or run `source $HOME/.zshrc`, you should see the new face of the shell

## Manual Installation

*For Windows, see [Windows Section](#windows)*

### Setup Your Terminal

#### Install & Config iTerm (macOS)

1. Install [iTerm2](https://iterm2.com/)

    ```bash
    brew install --cask iterm2
    ```

2. Download this [iTerm Profile](./terminal-config/iTerm/profiles/Salty_Nozo.json)
3. Open your iTerm > Settings > Profiles > Other Actions > Import JSON Profiles > Choose the downloaded profile
4. After you setup: Other Actions > Set as Default
5. Restart iTerm

#### Install Kitty (macOS, Linux)

1. Install [Kitty](https://sw.kovidgoyal.net/kitty/)

    macOS:

    ```bash
    brew install --cask kitty
    ```

    Linux (Ubuntu/Debian):

    ```bash
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    ```

2. You can setup the config by copying the [Kitty Config](./terminal-config/kitty/kitty.conf) to your `~/.config/kitty/kitty.conf` or run the install script:

    ```bash
    ./scripts/setup-kitty.sh
    ```

    It will create a symbolic link to the config from your `~/.config/kitty/kitty.conf`

#### Setup Neovim Config (All Platforms)

1. Install required dependencies:
   - ripgrep: for Telescope fuzzy finder
   - fd: for file search
   - unzip, gzip, tar: for Mason to install LSP servers
2. Install optinal language server if you don't use version managers:
   - node.js
   - python
   - go
3. You can setup the config by running the setup script:

    ```bash
    ./scripts/setup-nvim.sh
    ```

    Or with the main setup script:

    ```bash
    ./setup.sh --setup-nvim
    ```

    It will create a symbolic link from your `~/.config/nvim` to the nvim config in this repository.

4. After setup, open Neovim and the plugins will automatically install:

    ```bash
    nvim

    # or neovide
    neovide
    ```

For more details, see [Neovim Config README](./vim-config/README.md).

### Customize Your Configs

To customize your own configs, you can fork this project before the below steps.

### Setup for macOS

#### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Install coreutils

[GNU-coreutils](https://formulae.brew.sh/formula/coreutils) is required for some commands in macOS.

```bash
brew install coreutils
```

#### Install Python & Pipx

```bash
brew install python
brew install pipx
```

### Install Nerd Fonts

Please install at least one of the below fonts for your terminal, [Menlo](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip) is recommended.

- [Menlo](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip)

See all [Nerd Fonts](https://www.nerdfonts.com/font-downloads).

#### FiraCode

Fira Code is recommended for your editor such as [VS Code](https://code.visualstudio.com).

##### macOS

```bash
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
```

##### Ubuntu/Debian

```bash
sudo apt install fonts-firacode
```

### Clone This Project

It's recommended to put the project under `$HOME/projects/personal`:

```bash
mkdir -p $HOME/projects/personal
cd $HOME/projects/personal
```

Then clone this project (if you forked it, replace the URL with your own):

- use SSH

    ```bash
    git clone git@github.com:saltchang/terminal-setup.git
    ```

- use HTTPS

    ```bash
    git clone https://github.com/saltchang/terminal-setup.git
    ```

### Install zsh

#### macOS

*Since **Catalina**, macOS will use zsh as the default shell, so you should have zsh built-in in your system*

#### Ubuntu/Debian

```bash
sudo apt update && sudo apt -y install zsh
```

Then restart your terminal

### Setup the Shell

To setup the shell, just run the script:

```bash
cd terminal-setup

./setup.sh
```

It will create a soft link from `~/.zshrc` to the one in this project, check `dotfiles/.zshrc`.

Now restart your terminal or run `source ~/.zshrc`, you should see the new face of the shell.

## Customize Your Shell

Run the below command to open your `.zshrc`:

```bash
edit-rc
```

Or use the shortcut to go to the `terminal-setup` repo:

```bash
go-rc-repo
```

Then you can start to customize your shell.

## Color for powerlevel10k

If you would like to customize the color scheme of powerlevel10k, please see [This chart](https://user-images.githubusercontent.com/704406/43988708-64c0fa52-9d4c-11e8-8cf9-c4d4b97a5200.png).

## Custom Functions and Aliases

This setup includes several custom functions and aliases to improve your productivity. Here's a list of what's available:

### Custom Functions

- `cl`: Change to a directory and list its contents
- `home`: Change to the home directory and display a welcome message
- `gow`: Go to the work projects directory
- `gop`: Go to the personal projects directory
- `gol`: Go to the libraries directory
- `odg`: Interactive menu to select and go to different IXT projects
- `select_menu`: Interactive menu to select an option from a list
- `update_git`: Check for and update Git to the latest version
- `update_terminal_setup`: Update the terminal setup itself

### Custom Aliases

- `edit`: Open files in the default editor (set to VSCode)
- `edit-rc`: Edit the .zshrc file
- `go-rc-repo`: Go to the terminal setup repository
- `edit-ssh`: Edit the SSH config file
- `source-rc`: Source (reload) the .zshrc file
- `paths`: Display all directories in PATH, one per line
- `weather`: Show weather information using wttr.in

#### Git Aliases

- `gclb`: Clean local branches (except main and develop)
- `gclmb`: Clean merged branches
- `gfap`: Fetch all and pull
- `gfapr`: Fetch all and pull with rebase
- `gpuoc`: Push and set upstream to origin for the current branch

#### System-specific Aliases

macOS:

- `unu`: Update and upgrade Homebrew packages

Linux:

- `unu`: Update and upgrade apt packages
- `ffind`: Fuzzy find files
- `monitor`: Monitor system resources using gotop
- `mand`: Analyze disk usage with ncdu (excluding /mnt)

#### Docker Aliases

- `docker-all`: List all Docker containers with details
- `docker-ls`: List running Docker containers with details

#### Other Aliases

- `c`: Clear the terminal
- `python`: Alias for python3
- `pip`: Alias for pip3

## Troubleshooting

### Font Issues

If you're seeing boxes or question marks instead of special characters in your prompt:

1. Make sure you've installed the recommended fonts (Meslo or FiraCode).
2. Ensure your terminal is set to use one of these fonts.
3. If using iTerm2, go to Settings > Profiles > Text and select the appropriate font.

### Node.js Version Switching Issues

If automatic Node.js version switching isn't working:

1. Make sure proto is properly installed and configured.
2. Check if you have a `.prototools` or `.nvmrc` file in your project directory.
3. Try activating the correct Node.js version by `proto activate zsh`.

### Neovim Issues

If you encounter issues with Neovim:

1. **Plugins not loading**: Make sure you have internet connection when first opening Neovim. Lazy.nvim will automatically download plugins.
2. **LSP not working**: Open Neovim and run `:Mason` to check if language servers are installed. You can install them from the Mason UI.
3. **Clipboard issues on Linux**: Make sure you have clipboard support installed (`wl-clipboard` for Wayland).
4. **Treesitter errors**: Run `:TSUpdate` in Neovim to update all parser installations.

For any other issues, please open an issue on the GitHub repository.

## Windows

### Config Windows Terminal

1. Open your Windows Terminal > Settings > Open JSON file
2. Copy json configs from this [config file](./terminal-config/windows-terminal/windows-terminal-profile.json)
3. Paste the config to the Windows Terminal config json you just opened
4. Restart Windows Terminal

### Setup PowerShell

See [PowerShell Setup](./posh/README.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
