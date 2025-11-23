# Uninstall VoiceType
---
description: Complete removal of VoiceType from your system
---

You are helping the user uninstall VoiceType completely from their system.

## Overview

This uninstaller is **standalone** - it works even if:
- Plugin was installed from marketplace (no dev folder)
- Development directory was deleted
- Plugin was moved or renamed

It removes:
- Claude Code plugin registration and files
- Systemd services and launcher scripts
- Running processes
- Optionally: development directory and whisper models

## Steps

1. **Ask user what to remove:**
   Use the AskUserQuestion tool to ask:
   - Question: "What level of cleanup do you want for VoiceType?"
   - Header: "Cleanup Level"
   - Options:
     * "Remove everything" - Complete removal (plugin, system integration, dev directory, models)
     * "Keep development files" - Remove only system integration (keep dev folder and models for easy reinstall)

2. **Run the standalone uninstaller:**
   ```bash
   voicetype-uninstall [--all|--keep-data]
   ```

   - If user chose "Remove everything": `voicetype-uninstall --all`
   - If user chose "Keep development files": `voicetype-uninstall --keep-data`

3. **Monitor output** and report status to user

## What Gets Removed

**Always removed:**
- ✅ Claude Code plugin registration (from ~/.claude/plugins/installed_plugins.json)
- ✅ Plugin files (from marketplace or local installation)
- ✅ All systemd user services (voicetype-daemon, whisper-server)
- ✅ All launcher scripts (~/.local/bin/voicetype-*)
- ✅ Running processes

**Optionally removed (based on user choice):**
- Development directory (if found)
- whisper.cpp models (~142 MB)

## Troubleshooting

**If voicetype-uninstall command not found:**
The standalone uninstaller might not have been installed. Tell the user they can:
1. Check if it exists: `ls -la ~/.local/bin/voicetype-uninstall`
2. If missing, they can manually remove components:
   - Stop services: `systemctl --user stop voicetype-daemon whisper-server`
   - Disable services: `systemctl --user disable voicetype-daemon whisper-server`
   - Remove scripts: `rm ~/.local/bin/voicetype-*`
   - Remove services: `rm ~/.config/systemd/user/voicetype-*.service`
   - Reload systemd: `systemctl --user daemon-reload`

**"Permission denied" errors:**
- Run as normal user (not sudo)
- These are user services, not system services

**"Service not found" errors:**
- Normal - means service was already removed
- Uninstaller continues safely

## After Uninstall

**To reinstall:**
- From marketplace: Use Claude Code plugin marketplace
- Manually: `git clone https://github.com/aldervall/VoiceType.git && cd VoiceType && bash scripts/install.sh`
- From dev directory (if kept): `cd voice-to-claude-cli && bash scripts/install.sh`

**Manual cleanup (if needed):**
```bash
# Remove from input group (requires logout)
sudo deluser $USER input
```

## Important Notes

- The uninstaller removes itself last (voicetype-uninstall script)
- Restart Claude Code to refresh plugin list after uninstall
- Development directory is kept by default for easy reinstall
- All uninstall operations are local - no network calls
