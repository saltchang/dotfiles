# shell-ai

See: [https://github.com/ricklamers/shell-ai](https://github.com/ricklamers/shell-ai)

## Installation

### macOS

It's recommended to use `pipx` to install shell-ai.
You can install `pipx` using Homebrew:

```bash
brew install pipx
```

Then you can install shell-ai using `pipx`:

```bash
pipx install shell-ai
```

### Other Platforms

You can install shell-ai using `pip`:

```bash
pip install shell-ai
```

### Setup Configuration File

```bash
mkdir -p ~/.config/shell-ai/
cp config/shell-ai/config.example.json ~/.config/shell-ai/config.json
chmod 600 ~/.config/shell-ai/config.json # for security
```

then edit the configuration file to add your API key.

```bash
code ~/.config/shell-ai/config.json

# or
vi ~/.config/shell-ai/config.json
```

to generate a new OpenAI API key, go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)

### Usage

```bash
shai Hello, world!
```
