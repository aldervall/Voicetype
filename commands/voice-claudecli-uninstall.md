# Uninstall Voice-to-Claude-CLI

Complete removal of voice-to-claude-cli including whisper.cpp, systemd services, launcher scripts, and Claude Code plugin integration.

## What Will Be Removed

**System Components:**
- ✅ All systemd user services (daemon, whisper-server)
- ✅ All launcher scripts (~/.local/bin/voiceclaudecli-*)
- ✅ Installation directory (~/.local/voiceclaudecli)
- ✅ Temporary build artifacts (/tmp/whisper.cpp)

**Optional Removals (user prompted):**
- whisper.cpp models (~142 MB in .whisper/models/)
- Project directory (where you ran install from)
- Claude Code plugin integration

**NOT Removed:**
- User group membership (input group - requires logout to change)

## Usage

Run the uninstaller:

```bash
bash scripts/uninstall.sh
```

Or use the interactive wizard:

```bash
# Follow prompts for what to remove
bash scripts/uninstall.sh --interactive

# Remove everything without prompts
bash scripts/uninstall.sh --all

# Keep models and project (remove only system integration)
bash scripts/uninstall.sh --keep-data
```

## What Happens

1. **Stops all running processes** (daemon, whisper-server)
2. **Disables systemd services** (prevents auto-start)
3. **Removes service files** from ~/.config/systemd/user/
4. **Removes launcher scripts** from ~/.local/bin/
5. **Removes installation directories** (with size reporting)
6. **Prompts for optional cleanup** (models, project dir, Claude plugin)

## Safety Features

- ✅ **Interactive confirmation** before removing anything
- ✅ **Shows disk space** that will be recovered
- ✅ **Keeps local project** by default (you can re-install easily)
- ✅ **Non-destructive** - only removes what it installed

## After Uninstall

**To reinstall later:**
```bash
# If you kept the project directory
cd voice-to-claude-cli
bash scripts/install.sh

# Or clone fresh
git clone https://github.com/aldervall/Voice-to-Claude-CLI.git
cd Voice-to-Claude-CLI
bash scripts/install.sh
```

**Manual cleanup (if needed):**
```bash
# Remove yourself from input group (requires logout)
sudo deluser $USER input

# Then log out and back in
```

## Troubleshooting

**"Permission denied" errors:**
- Run as your normal user (not sudo)
- If services won't stop, try: `systemctl --user daemon-reload`

**"Service not found" errors:**
- This is normal - means service was already removed or never installed
- Uninstaller continues safely

**Want to keep whisper.cpp for other projects?**
- Use `--keep-data` flag to only remove voice-to-claude-cli integration
- whisper.cpp and models stay in project directory

## Privacy Note

Uninstallation is **completely local** - no data is sent anywhere. The uninstaller only removes files from your computer.
