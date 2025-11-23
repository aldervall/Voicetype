#!/bin/bash

#===============================================================================
# VoiceType Uninstaller
#
# Removes all components installed by install.sh:
# - Systemd user services
# - Launcher scripts
# - Installation directories
# - Temporary build artifacts
# - Running processes
# - whisper.cpp models (optional)
# - Claude Code plugin integration (optional)
# - Project directory (optional)
#
# Usage:
#   bash scripts/uninstall.sh              # Interactive (default)
#   bash scripts/uninstall.sh --all        # Remove everything
#   bash scripts/uninstall.sh --keep-data  # Keep models & installation
#   bash scripts/uninstall.sh --help       # Show help
#===============================================================================

# Don't use set -e - we want graceful error handling
# set -e

# Parse command line arguments
UNINSTALL_MODE="interactive"  # interactive, all, keep-data
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            UNINSTALL_MODE="all"
            shift
            ;;
        --keep-data)
            UNINSTALL_MODE="keep-data"
            shift
            ;;
        --help|-h)
            cat << EOF
VoiceType Uninstaller

Usage: bash scripts/uninstall.sh [OPTIONS]

Options:
  (none)          Interactive mode - prompts for each optional removal
  --all           Remove everything including models, installation files, and Claude plugin
  --keep-data     Remove only system integration (keep models and installation files)
  --help, -h      Show this help message

What Gets Removed:
  Always:
    • Systemd services (daemon, whisper-server)
    • Launcher scripts (~/.local/bin/voicetype-*)
    • Installation directory (~/.local/voicetype)
    • Temporary builds (/tmp/whisper.cpp)
    • Running processes

  Optional (prompted in interactive mode):
    • whisper.cpp models (~142 MB)
    • Project directory
    • Claude Code plugin integration

Examples:
  bash scripts/uninstall.sh              # Ask about each optional item
  bash scripts/uninstall.sh --all        # Nuclear option - remove everything
  bash scripts/uninstall.sh --keep-data  # Keep models for re-install

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Color output functions
echo_info() { echo -e "\033[1;34mℹ\033[0m $1"; }
echo_success() { echo -e "\033[1;32m✓\033[0m $1"; }
echo_warning() { echo -e "\033[1;33m⚠\033[0m $1"; }
echo_error() { echo -e "\033[1;31m✗\033[0m $1"; }

# Banner
cat << "EOF"

╔═══════════════════════════════════════════════════════╗
║                                                       ║
║        🗑  VoiceType Uninstaller          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

EOF

echo_info "This will remove all VoiceType components"
echo_warning "This action cannot be undone!"
echo ""
echo "The following will be removed:"
echo "  • Systemd services (daemon, whisper-server)"
echo "  • Launcher scripts in ~/.local/bin/"
echo "  • Installation directory: ~/.local/voicetype"
echo "  • Temporary build directory: /tmp/whisper.cpp"
echo "  • Running processes"
echo ""
echo_info "Project directory will NOT be removed: $(pwd)"
echo ""

# Ask for confirmation (if running interactively)
if [ -t 0 ]; then
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Uninstall cancelled"
        exit 0
    fi
fi

echo ""
echo "========================================="
echo " Step 1/6: Stopping Services"
echo "========================================="
echo ""

# Stop systemd services
for service in voicetype-daemon whisper-server voice-holdtospeak voice-input; do
    if systemctl --user is-active "$service" &>/dev/null; then
        echo_info "Stopping $service..."
        systemctl --user stop "$service" 2>/dev/null || true
        echo_success "Stopped $service"
    fi
done

# Disable systemd services
for service in voicetype-daemon whisper-server voice-holdtospeak voice-input; do
    if systemctl --user is-enabled "$service" &>/dev/null; then
        echo_info "Disabling $service..."
        systemctl --user disable "$service" 2>/dev/null || true
        echo_success "Disabled $service"
    fi
done

echo ""
echo "========================================="
echo " Step 2/6: Killing Running Processes"
echo "========================================="
echo ""

# Kill any running processes
if pgrep -f "voice_holdtospeak" &>/dev/null; then
    echo_info "Killing voice_holdtospeak processes..."
    pkill -f "voice_holdtospeak" || true
    echo_success "Killed voice_holdtospeak"
fi

if pgrep -f "whisper-server" &>/dev/null; then
    echo_info "Killing whisper-server processes..."
    pkill -f "whisper-server" || true
    echo_success "Killed whisper-server"
fi

sleep 1  # Give processes time to die

echo ""
echo "========================================="
echo " Step 3/6: Removing Systemd Services"
echo "========================================="
echo ""

SERVICE_DIR="$HOME/.config/systemd/user"
SERVICES_REMOVED=0

for service_file in voicetype-daemon.service whisper-server.service voice-holdtospeak.service voice-input.service; do
    if [ -f "$SERVICE_DIR/$service_file" ]; then
        echo_info "Removing $service_file..."
        rm -f "$SERVICE_DIR/$service_file"
        echo_success "Removed $service_file"
        SERVICES_REMOVED=$((SERVICES_REMOVED + 1))
    fi
done

if [ $SERVICES_REMOVED -gt 0 ]; then
    echo_info "Reloading systemd daemon..."
    systemctl --user daemon-reload
    echo_success "Systemd daemon reloaded"
else
    echo_info "No systemd services found"
fi

echo ""
echo "========================================="
echo " Step 4/6: Removing Launcher Scripts"
echo "========================================="
echo ""

BIN_DIR="$HOME/.local/bin"
SCRIPTS_REMOVED=0

for script in voicetype-daemon voicetype-input voicetype-interactive voicetype-stop-server claude-voice-input voice-input; do
    if [ -f "$BIN_DIR/$script" ]; then
        echo_info "Removing $script..."
        rm -f "$BIN_DIR/$script"
        echo_success "Removed $script"
        SCRIPTS_REMOVED=$((SCRIPTS_REMOVED + 1))
    fi
done

if [ $SCRIPTS_REMOVED -eq 0 ]; then
    echo_info "No launcher scripts found"
fi

echo ""
echo "========================================="
echo " Step 5/6: Removing Installation Dirs"
echo "========================================="
echo ""

# Remove ~/.local/voicetype
if [ -d "$HOME/.local/voicetype" ]; then
    echo_info "Removing ~/.local/voicetype..."
    DIR_SIZE=$(du -sh "$HOME/.local/voicetype" 2>/dev/null | cut -f1)
    rm -rf "$HOME/.local/voicetype"
    echo_success "Removed ~/.local/voicetype ($DIR_SIZE)"
else
    echo_info "~/.local/voicetype not found"
fi

# Remove /tmp/whisper.cpp
if [ -d "/tmp/whisper.cpp" ]; then
    echo_info "Removing /tmp/whisper.cpp..."
    TMP_SIZE=$(du -sh "/tmp/whisper.cpp" 2>/dev/null | cut -f1)
    rm -rf "/tmp/whisper.cpp"
    echo_success "Removed /tmp/whisper.cpp ($TMP_SIZE)"
else
    echo_info "/tmp/whisper.cpp not found"
fi

echo ""
echo "========================================="
echo " Step 6/9: Final Cleanup"
echo "========================================="
echo ""

# Remove any whisper build logs
if [ -f "/tmp/whisper-build.log" ]; then
    rm -f "/tmp/whisper-build.log"
    echo_success "Removed /tmp/whisper-build.log"
fi

echo ""
echo "========================================="
echo " Step 7/9: Optional - whisper.cpp Models"
echo "========================================="
echo ""

# Handle whisper models based on mode
REMOVE_MODELS=false
if [ "$UNINSTALL_MODE" = "all" ]; then
    REMOVE_MODELS=true
elif [ "$UNINSTALL_MODE" = "keep-data" ]; then
    REMOVE_MODELS=false
elif [ "$UNINSTALL_MODE" = "interactive" ] && [ -d "$PROJECT_ROOT/.whisper/models" ]; then
    MODEL_SIZE=$(du -sh "$PROJECT_ROOT/.whisper/models" 2>/dev/null | cut -f1)
    echo_info "whisper.cpp models found: $MODEL_SIZE"
    echo_warning "Removing models means re-downloading (~142 MB) on next install"
    read -p "Remove whisper.cpp models? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_MODELS=true
    fi
fi

if [ "$REMOVE_MODELS" = true ] && [ -d "$PROJECT_ROOT/.whisper/models" ]; then
    echo_info "Removing whisper.cpp models..."
    MODEL_SIZE=$(du -sh "$PROJECT_ROOT/.whisper/models" 2>/dev/null | cut -f1)
    rm -rf "$PROJECT_ROOT/.whisper/models"
    echo_success "Removed whisper.cpp models ($MODEL_SIZE)"
elif [ -d "$PROJECT_ROOT/.whisper/models" ]; then
    echo_info "Keeping whisper.cpp models for future use"
else
    echo_info "No whisper.cpp models found"
fi

echo ""
echo "========================================="
echo " Step 8/9: Optional - Project Directory"
echo "========================================="
echo ""

# Handle installation directory based on mode
REMOVE_PROJECT=false
if [ "$UNINSTALL_MODE" = "all" ]; then
    REMOVE_PROJECT=true
elif [ "$UNINSTALL_MODE" = "keep-data" ]; then
    REMOVE_PROJECT=false
elif [ "$UNINSTALL_MODE" = "interactive" ]; then
    INSTALL_SIZE=$(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    echo_info "Installation directory: $PROJECT_ROOT ($INSTALL_SIZE)"
    echo_warning "Removing installation directory means re-cloning from GitHub"
    echo_info "Keep it if you want to reinstall easily later"
    read -p "Remove installation directory? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_PROJECT=true
    fi
fi

if [ "$REMOVE_PROJECT" = true ]; then
    echo_info "Removing installation directory..."
    INSTALL_SIZE=$(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    # Safety check - don't remove if we're in /home directly or system dirs
    case "$PROJECT_ROOT" in
        /|/home|/usr|/bin|/sbin|/etc|/var|/tmp)
            echo_error "Refusing to remove system directory: $PROJECT_ROOT"
            echo_info "Please remove manually if needed: rm -rf $PROJECT_ROOT"
            ;;
        *)
            cd /tmp  # Move out of installation dir before removing it
            rm -rf "$PROJECT_ROOT"
            echo_success "Removed installation directory ($INSTALL_SIZE)"
            ;;
    esac
else
    echo_info "Keeping installation directory: $PROJECT_ROOT"
fi

echo ""
echo "========================================="
echo " Step 9/9: Optional - Claude Code Plugin"
echo "========================================="
echo ""

# Handle Claude Code plugin removal based on mode
REMOVE_CLAUDE_PLUGIN=false
if [ "$UNINSTALL_MODE" = "all" ]; then
    REMOVE_CLAUDE_PLUGIN=true
elif [ "$UNINSTALL_MODE" = "keep-data" ]; then
    REMOVE_CLAUDE_PLUGIN=false
elif [ "$UNINSTALL_MODE" = "interactive" ]; then
    echo_info "Claude Code may have cached this plugin"
    echo_warning "This will try to remove it from Claude's config (if accessible)"
    read -p "Remove Claude Code plugin integration? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_CLAUDE_PLUGIN=true
    fi
fi

if [ "$REMOVE_CLAUDE_PLUGIN" = true ]; then
    echo_info "Looking for Claude Code plugin directories..."

    # Common Claude Code plugin locations
    CLAUDE_PLUGIN_DIRS=(
        "$HOME/.claude/plugins/voice-to-claude-cli"
        "$HOME/.config/claude/plugins/voice-to-claude-cli"
        "$HOME/.local/share/claude/plugins/voice-to-claude-cli"
    )

    REMOVED_COUNT=0
    for plugin_dir in "${CLAUDE_PLUGIN_DIRS[@]}"; do
        if [ -d "$plugin_dir" ]; then
            echo_info "Found plugin at: $plugin_dir"
            rm -rf "$plugin_dir"
            echo_success "Removed Claude plugin: $plugin_dir"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        fi
    done

    if [ $REMOVED_COUNT -eq 0 ]; then
        echo_info "No Claude Code plugin directories found"
        echo_info "Plugin may have been installed differently (marketplace/git)"
        echo_warning "You may need to remove manually from Claude Code settings"
    else
        echo_success "Removed $REMOVED_COUNT Claude Code plugin location(s)"
        echo_info "Restart Claude Code for changes to take effect"
    fi
else
    echo_info "Keeping Claude Code plugin integration"
fi

echo ""
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║           ✨ UNINSTALL COMPLETE! ✨                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

EOF

echo_success "VoiceType system integration removed"
echo ""

# Show what was kept based on choices
KEPT_ITEMS=()
[ -d "$PROJECT_ROOT" ] && [ "$REMOVE_PROJECT" = false ] && KEPT_ITEMS+=("Project directory: $PROJECT_ROOT")
[ -d "$PROJECT_ROOT/.whisper/models" ] && [ "$REMOVE_MODELS" = false ] && KEPT_ITEMS+=("whisper.cpp models: $PROJECT_ROOT/.whisper/models/")
[ "$REMOVE_CLAUDE_PLUGIN" = false ] && KEPT_ITEMS+=("Claude Code plugin (if installed)")

if [ ${#KEPT_ITEMS[@]} -gt 0 ]; then
    echo_info "What was kept:"
    for item in "${KEPT_ITEMS[@]}"; do
        echo "  • $item"
    done
    echo ""
fi

echo_info "Manual cleanup (if needed):"
echo "  • Remove from 'input' group: sudo deluser \$USER input"
echo "  • (Group removal requires logout to take effect)"
echo ""

if [ "$REMOVE_PROJECT" = false ]; then
    echo_success "To reinstall: cd $PROJECT_ROOT && bash scripts/install.sh"
else
    echo_success "To reinstall: git clone https://github.com/aldervall/VoiceType.git"
fi
echo ""
