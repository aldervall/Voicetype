# VoiceType Installation Error Report

**Generated:** 2024-01-15 10:23:45 UTC
**Report ID:** 20240115-102345
**Repository:** https://github.com/aldervall/voice-to-claude-cli

---

## System Information

- **Distribution:** ubuntu
- **Display Server:** wayland
- **Package Manager:** apt
- **Shell:** /bin/bash
- **Interactive:** true

## Installation Details

- **Failed Phase:** STEP 1/7: Install System Dependencies
- **Exit Code:** 100
- **Duration:** 15 seconds
- **Force Mode:** false
- **Installation Directory:** ~/projects/voice-to-claude-cli

## Error Output

```
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package ydotool
E: Unable to locate package python3-venv
```

## Package Status

```
Required packages:
  ✗ ydotool (missing)
  ✓ python3-pip (installed)
  ✓ git (installed)
  ✗ python3-venv (missing)
  ✓ curl (installed)
```

## Software Versions

- **Python:** Python 3.10.12
- **Pip:** pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)
- **Git:** git version 2.34.1
- **Curl:** curl 7.81.0

## Environment (Safe Variables Only)

```
PATH=~/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SHELL=/bin/bash
TERM=xterm-256color
LANG=en_US.UTF-8
DISPLAY=:0
WAYLAND_DISPLAY=wayland-0
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=GNOME
```

---

**Privacy Note:** All usernames and personal paths have been sanitized from this report.
**No personal information (email, IP, credentials) is included.**

For more information: https://github.com/aldervall/voice-to-claude-cli#privacy--error-reporting

---

## Example Analysis

**This example shows:**

1. **What went wrong:** Package manager couldn't find `ydotool` and `python3-venv`
2. **System context:** Ubuntu with Wayland, GNOME desktop
3. **What worked:** Python, pip, git, and curl are available
4. **Privacy:** Notice how paths show `~` instead of `/home/username`

**Likely fix:** User needs to enable universe repository on Ubuntu:
```bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install ydotool python3-venv
```

This is exactly the kind of information that helps us:
- Improve installation instructions for specific distributions
- Add automatic workarounds for common issues
- Make better error messages

**Thank you for helping make voice-to-claude-cli better! 🙏**
