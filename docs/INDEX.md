# Documentation Index

**VoiceType** - Complete documentation guide

---

## 🚀 Quick Start (For Users)

**Just want to install and use it?** Start here:

1. **[README.md](README.md)** - Main user guide
   - Installation via Claude Code marketplace (3 steps)
   - Usage instructions (F12 hold-to-speak)
   - Features and supported platforms

2. **Run the installer:**
   ```bash
   /voice-claudecli-install  # From Claude Code
   ```

3. **Start using:**
   - Hover over Claude Code window
   - Hold F12, speak, release
   - Text appears in Claude CLI

**Need customization?** See [ADVANCED.md](ADVANCED.md)

---

## 📖 User Documentation

### Installation & Setup

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[README.md](README.md)** | Main user guide | First-time installation |
| **[INSTALLATION_STATUS.md](INSTALLATION_STATUS.md)** | Current installation state & known issues | Installation troubleshooting |
| **[QUICK_TEST_CHECKLIST.md](QUICK_TEST_CHECKLIST.md)** | 5-minute health check | Verify everything works |

### Usage & Customization

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[ADVANCED.md](ADVANCED.md)** | Advanced usage guide | Customize hotkeys, duration, beeps |
|  | - Change F12 to another key | Bind to custom hotkey |
|  | - Adjust recording duration | Record longer/shorter clips |
|  | - Customize beeps & notifications | Disable sounds |
|  | - Use in scripts | Automate transcription |

---

## 🔧 Developer Documentation

### Architecture & Design

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[CLAUDE.md](CLAUDE.md)** | Complete developer guide | Working with the codebase |
|  | - Architecture overview | Understand system design |
|  | - Development workflow | Making code changes |
|  | - Troubleshooting reference | Debugging issues |
|  | - Cross-platform guidelines | Adding platform support |
| **[PLUGIN_ARCHITECTURE.md](PLUGIN_ARCHITECTURE.md)** | Plugin design decisions | Understanding historical fixes |
|  | - Plugin discovery mechanism | Why plugin.json is at root |
|  | - Marketplace vs plugin | Architecture choices |
|  | - Installation script design | Error handling patterns |

### Testing & Quality

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[INSTALLATION_FLOW.md](INSTALLATION_FLOW.md)** | 7-phase testing guide | Complete installation testing |
|  | - Phase-by-phase verification | Systematic testing |
|  | - Troubleshooting matrix | Debug installation issues |
|  | - Multi-environment testing | Test on different distros |
| **[QUICK_TEST_CHECKLIST.md](QUICK_TEST_CHECKLIST.md)** | 5-minute smoke tests | Quick verification after changes |
| **[PROJECT_STRUCTURE_AUDIT.md](PROJECT_STRUCTURE_AUDIT.md)** | File inventory & cleanup guide | Understanding project organization |

### Development History

| Document | Description | When to Use |
|----------|-------------|-------------|
| **[HANDOVER.md](HANDOVER.md)** | Session-by-session development history | Understanding project evolution |
|  | - Sessions 1-21 | See all decisions made |
|  | - Architectural decisions | Why things are the way they are |
|  | - Bug fixes and improvements | What was fixed when |
| **[archive/HISTORY.md](archive/HISTORY.md)** | Old development notes | Historical reference only |

---

## 🎯 Common Tasks

### "I want to install VoiceType"
→ **[README.md](README.md)** - Start here!

### "Installation failed, how do I fix it?"
→ **[INSTALLATION_STATUS.md](INSTALLATION_STATUS.md)** - Check known issues
→ **[QUICK_TEST_CHECKLIST.md](QUICK_TEST_CHECKLIST.md)** - Run health checks
→ **[INSTALLATION_FLOW.md](INSTALLATION_FLOW.md)** - Complete troubleshooting guide

### "I want to change the F12 hotkey"
→ **[ADVANCED.md](ADVANCED.md)** - Customization section

### "How does this project work?"
→ **[CLAUDE.md](CLAUDE.md)** - Architecture overview
→ **[PLUGIN_ARCHITECTURE.md](PLUGIN_ARCHITECTURE.md)** - Design decisions

### "I want to contribute code"
→ **[CLAUDE.md](CLAUDE.md)** - Developer workflow
→ **[HANDOVER.md](HANDOVER.md)** - Understand project history
→ **[INSTALLATION_FLOW.md](INSTALLATION_FLOW.md)** - Testing procedures

### "I found a bug"
→ **[INSTALLATION_STATUS.md](INSTALLATION_STATUS.md)** - Check if it's known
→ **[GitHub Issues](https://github.com/aldervall/VoiceType/issues)** - Report it!

---

## 📁 File Organization

```
docs/
├── INDEX.md                        # ← You are here
├── README.md                       # Main user guide
├── ADVANCED.md                     # Advanced usage & customization
├── CLAUDE.md                       # Developer guide
├── HANDOVER.md                     # Development session history
├── PLUGIN_ARCHITECTURE.md          # Plugin design decisions
├── INSTALLATION_FLOW.md            # 7-phase installation testing
├── INSTALLATION_STATUS.md          # Current installation state
├── QUICK_TEST_CHECKLIST.md         # 5-minute smoke tests
├── PROJECT_STRUCTURE_AUDIT.md      # File inventory & cleanup guide
├── images/                         # Screenshots
│   ├── Plugin.AddMarket.png
│   └── Plugin.Enable.png
└── archive/                        # Old documentation
    └── HISTORY.md
```

---

## 🔗 External Resources

- **GitHub Repository:** https://github.com/aldervall/VoiceType
- **Issue Tracker:** https://github.com/aldervall/VoiceType/issues
- **License:** MIT (see [LICENSE](../LICENSE))

---

## 📝 Documentation Standards

**For maintainers:**

### When to Update Documentation

| Change Type | Update These Docs |
|-------------|-------------------|
| **New feature** | README.md, ADVANCED.md, HANDOVER.md |
| **Bug fix** | INSTALLATION_STATUS.md, HANDOVER.md |
| **Architecture change** | CLAUDE.md, PLUGIN_ARCHITECTURE.md, HANDOVER.md |
| **Installation flow change** | INSTALLATION_FLOW.md, INSTALLATION_STATUS.md |
| **Testing procedure change** | QUICK_TEST_CHECKLIST.md, INSTALLATION_FLOW.md |

### Documentation Principles

1. **User docs first** - Users shouldn't need to read developer docs
2. **Task-oriented** - Organize by what users want to do, not by technical structure
3. **Progressive disclosure** - Quick start → Basic usage → Advanced features
4. **Executable examples** - All code blocks should be copy-pasteable
5. **Keep up-to-date** - Update docs in the same commit as code changes

---

**Last Updated:** 2025-11-17
**Version:** v1.3.0
**Status:** ✅ Production Ready
