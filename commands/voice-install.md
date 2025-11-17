---
description: Install Voice-to-Claude-CLI with automated setup for your system
---

You are helping the user install Voice-to-Claude-CLI, a local voice transcription tool.

## Installation Steps

**1. Run the automated installer:**
```bash
if [ -f "$CLAUDE_PLUGIN_ROOT/scripts/install.sh" ]; then
  cd "$CLAUDE_PLUGIN_ROOT" && INTERACTIVE=false bash scripts/install.sh
elif [ -f "scripts/install.sh" ]; then
  INTERACTIVE=false bash scripts/install.sh
else
  echo "ERROR: Cannot find install.sh script!"
  echo "CLAUDE_PLUGIN_ROOT: $CLAUDE_PLUGIN_ROOT"
  echo "Current directory: $(pwd)"
  ls -la "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || echo "CLAUDE_PLUGIN_ROOT not accessible"
  exit 1
fi
```

This script will automatically:
- Detect your Linux distribution (Arch, Ubuntu, Fedora, OpenSUSE)
- Install system dependencies (ydotool, clipboard tools, etc.)
- Set up Python virtual environment
- Install whisper.cpp server (pre-built binary)
- Create launcher scripts in ~/.local/bin
- Configure systemd services

**2. Important: User group changes**
If the installer adds the user to the `input` group, they MUST log out and log back in for changes to take effect.

**3. Verify installation:**
```bash
curl http://127.0.0.1:2022/health
systemctl --user status voiceclaudecli-daemon
```

## Usage After Installation

- **Hold-to-speak:** Press and hold F12, speak, then release
- **Quick voice input:** Use `/voice` command in Claude
- **Interactive mode:** Run `voiceclaudecli-interactive`

## Notes

- All processing is 100% local - no cloud services
- Requires sudo for installing system packages
- See CLAUDE.md for troubleshooting and advanced usage
