# Claude Code Plugin Architecture - Voice-to-Claude-CLI

**Last Updated:** 2025-11-17
**Status:** 🔴 BROKEN - Requires Major Refactoring

## Executive Summary

The Voice-to-Claude-CLI plugin has a **dual identity crisis** preventing proper discovery by Claude Code. Users cannot see `/voice-install` because the plugin registration architecture is fundamentally broken.

### 🚨 Critical Issues

1. **Plugin.json in wrong location** - Must be at project root, currently in `.claude-plugin/`
2. **Marketplace/Plugin confusion** - Mixing marketplace catalog with plugin identity
3. **Zero error handling in installation** - Scripts crash instantly on any failure
4. **No graceful degradation** - All-or-nothing installation approach

---

## Claude Code Plugin Discovery Mechanism

### How Claude Code Finds Plugin Components

When a plugin is installed, Claude Code automatically discovers:

| Component | Discovery Method | Location |
|-----------|------------------|----------|
| **Slash Commands** | Auto-scan `commands/` directory | `commands/*.md` files |
| **Skills** | Auto-scan `skills/` directory | `skills/*/SKILL.md` files |
| **Plugin Metadata** | Read `plugin.json` | **ROOT DIRECTORY ONLY** |

**Critical Rule:** `plugin.json` MUST be at the plugin root directory.

### Plugin vs Marketplace

These are **two different concepts**:

#### Plugin (Single Tool)
```
my-plugin/                   # This becomes the plugin
├── plugin.json              # ✅ At root - discovered!
├── commands/                # ✅ Auto-discovered
│   └── my-command.md
├── skills/                  # ✅ Auto-discovered
│   └── my-skill/SKILL.md
└── scripts/
    └── helper.sh
```

Users install with:
```bash
/plugin install <github-url>
```

#### Marketplace (Plugin Catalog)
```
my-marketplace/
├── marketplace.json         # Lists multiple plugins
└── plugins/
    ├── plugin-a/            # Each is separate plugin
    │   └── plugin.json
    └── plugin-b/
        └── plugin.json
```

Users add marketplace:
```bash
/plugin marketplace add <marketplace-url>
```

Then install individual plugins:
```bash
/plugin install plugin-a@my-marketplace
```

---

## Current Architecture (BROKEN)

### File Structure - What We Have Now

```
voice-to-claude-cli/                    # Git repository root
├── .claude-plugin/                     # ❌ WRONG - This implies marketplace
│   ├── marketplace.json                #    Says "I host plugins"
│   └── plugin.json                     # ❌ WRONG LOCATION - Claude can't find this!
│
├── commands/                           # ✅ CORRECT
│   ├── voice.md                        # ✅ Would be discovered... IF plugin.json was found
│   └── voice-install.md                # ❌ Never discovered = user confusion!
│
├── skills/                             # ✅ CORRECT
│   └── voice/
│       ├── SKILL.md                    # ✅ Would be discovered... IF plugin.json was found
│       └── scripts/
│           └── transcribe.py
│
├── scripts/                            # Installation scripts
│   ├── install.sh                      # ❌ CRASHES on any error (set -e)
│   └── install-whisper.sh              # ❌ CRASHES on any error (set -e)
│
├── src/                                # Python source code
│   ├── voice_to_claude.py
│   ├── platform_detect.py
│   └── ...
│
└── README.md
```

### What Happens When User Tries to Install

**Step 1:** User adds marketplace
```bash
/plugin marketplace add https://github.com/aldervall/Voice-to-Claude-CLI
```

**Step 2:** Claude Code reads `.claude-plugin/marketplace.json`
```json
{
  "plugins": [{
    "name": "voice-transcription",
    "source": "./"               // ← Points to repository root
  }]
}
```

**Step 3:** Claude Code looks for `./plugin.json` (at root)
- ❌ **NOT FOUND!** (It's in `.claude-plugin/plugin.json`)
- ❌ Plugin registration **FAILS SILENTLY**
- ❌ Commands never discovered
- ❌ Skills never discovered
- ❌ User sees nothing and gets confused

**Step 4:** User tries `/voice-install`
- ❌ Command doesn't exist (never discovered)
- ❌ User has no idea what's wrong

---

## Installation Script Issues

### Problem: Nuclear Failure Mode

Both installation scripts use `set -e` with **zero error recovery**:

```bash
#!/bin/bash
set -e  # Exit on FIRST error - no graceful handling!

# Any of these failing = instant script death:
$INSTALL_CMD $PACKAGES           # Package manager timeout? BOOM!
git clone https://...            # No git installed? BOOM!
make -j$(nproc) server           # Build error? BOOM!
curl http://127.0.0.1:2022/...   # Server not started? BOOM!
```

### What Users Experience

**Scenario 1: Missing Dependencies**
```
$ bash scripts/install.sh
Installing: ydotool python-pip ...
Error: Package 'ydotool' not found
[Script exits immediately - no explanation]
```

**Scenario 2: Network Timeout**
```
$ bash scripts/install-whisper.sh
Cloning whisper.cpp...
fatal: unable to connect to github.com
[Script exits immediately - user has no idea how to proceed]
```

**Scenario 3: Build Failure**
```
$ bash scripts/install-whisper.sh
Compiling... (this may take a few minutes)
[Build error occurs]
[Script exits immediately - no fallback, no helpful message]
```

### Non-Interactive Mode Issues

The scripts attempt to detect non-interactive mode:

```bash
if [ -t 0 ]; then
    INTERACTIVE="${INTERACTIVE:-true}"
else
    INTERACTIVE="${INTERACTIVE:-false}"
fi
```

But when Claude Code runs them:
- `INTERACTIVE=false` is set
- User prompts are skipped
- Failures are **silent** (no feedback to Claude or user)
- Claude has no idea what went wrong

---

## Required Fixes

### Fix #1: Move plugin.json to Root (HIGH PRIORITY)

**Current:**
```
.claude-plugin/
└── plugin.json   ❌ Wrong location
```

**Required:**
```
voice-to-claude-cli/
├── plugin.json   ✅ Correct location
```

**Action:**
```bash
mv .claude-plugin/plugin.json ./plugin.json
```

### Fix #2: Clarify Marketplace vs Plugin Identity

**Decision Required:** Choose ONE approach:

#### Option A: Simple Plugin (RECOMMENDED)
Remove marketplace catalog, be a single plugin:

```bash
rm -rf .claude-plugin/        # Remove marketplace structure
# Keep plugin.json at root
```

Users install directly:
```bash
/plugin install https://github.com/aldervall/Voice-to-Claude-CLI
```

#### Option B: Marketplace Hosting Multiple Plugins
Restructure to proper marketplace format:

```
voice-to-claude-cli/
├── marketplace.json          # At root
└── plugins/
    └── voice-transcription/  # Plugin subdirectory
        ├── plugin.json       # Each plugin has own manifest
        ├── commands/
        ├── skills/
        └── scripts/
```

### Fix #3: Add Error Recovery to Installation Scripts

Replace nuclear `set -e` with graceful error handling:

**Current (BROKEN):**
```bash
set -e  # Instant death on any error
$INSTALL_CMD $PACKAGES
git clone https://...
```

**Required (RESILIENT):**
```bash
# NO set -e - handle errors explicitly

if ! $INSTALL_CMD $PACKAGES; then
    echo_error "Failed to install system packages"
    echo_info "Try manually: $INSTALL_CMD $PACKAGES"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo_error "git is required but not installed"
    echo_info "Install git first: sudo pacman -S git"
    exit 1
fi

if ! git clone https://github.com/ggerganov/whisper.cpp "$WHISPER_DIR"; then
    echo_error "Failed to clone whisper.cpp (network issue?)"
    echo_info "Check internet connection and try again"
    exit 1
fi
```

### Fix #4: Add JSON Status Output for Claude

The `/voice-install` command needs machine-readable status:

```bash
# When running from Claude Code (non-interactive)
if [ "$INTERACTIVE" = "false" ]; then
    # Output JSON for Claude to parse
    cat <<EOF
{
  "status": "error",
  "stage": "dependency_install",
  "message": "Failed to install ydotool",
  "help": [
    "Check package manager logs: journalctl -xe",
    "Try manually: sudo pacman -S ydotool"
  ]
}
EOF
fi
```

---

## Testing Checklist

After fixes are implemented:

### Plugin Discovery
- [ ] `plugin.json` exists at repository root
- [ ] `/plugin install <repo-url>` successfully registers plugin
- [ ] `/voice-install` appears in command list
- [ ] `/voice` appears in command list
- [ ] Voice skill appears in skill list

### Installation - Happy Path
- [ ] Fresh system: `bash scripts/install.sh` completes successfully
- [ ] whisper.cpp server starts automatically
- [ ] All systemd services created and enabled
- [ ] Commands work: `voiceclaudecli-daemon`, `voiceclaudecli-input`

### Installation - Error Scenarios
- [ ] Missing `git`: Script shows helpful error message (doesn't crash silently)
- [ ] Missing build tools: Script lists required packages
- [ ] Network timeout: Script explains issue and suggests retry
- [ ] Build failure: Script shows logs location and fallback options
- [ ] Non-interactive mode: JSON status output for Claude

### Plugin Usage from Claude Code
- [ ] `/voice-install` executes and provides feedback to Claude
- [ ] Installation success/failure visible in Claude's context
- [ ] Voice skill triggers automatically when user says "let me speak"
- [ ] Error messages from scripts are parseable by Claude

---

## References

### Claude Code Documentation
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference.md) - Complete plugin.json schema
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces.md) - Marketplace structure
- [Skills Guide](https://code.claude.com/docs/en/skills.md) - Skill discovery mechanism
- [Slash Commands](https://code.claude.com/docs/en/slash-commands.md) - Command discovery

### Related Files
- `CLAUDE.md` - Developer documentation
- `README.md` - User installation guide
- `HANDOVER.md` - Session history
- `.claude-plugin/plugin.json` - Current (broken) location
- `commands/voice-claudecli-install.md` - Installation command definition
- `skills/voice/SKILL.md` - Voice transcription skill

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-17 | Identified dual identity crisis | Plugin vs marketplace confusion prevents discovery |
| 2025-11-17 | Identified installation script fragility | `set -e` causes instant failure with no recovery |
| 2025-11-17 | Recommend simple plugin approach | Simpler user experience than marketplace hosting |

---

## Next Steps

1. **Document findings** ✅ (this file)
2. **Move plugin.json to root** - Enables command/skill discovery
3. **Refactor installation scripts** - Add error handling and JSON output
4. **Test end-to-end** - Verify plugin discovery and installation
5. **Update user documentation** - Clarify installation process

**Estimated Effort:** 2-3 hours to fix plugin discovery + 4-6 hours for robust installation scripts

**Priority:** 🔴 CRITICAL - Users cannot currently use the plugin as intended
