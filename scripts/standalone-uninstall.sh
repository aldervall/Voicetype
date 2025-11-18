#!/bin/bash

#===============================================================================
# Voice-to-Claude-CLI Standalone Uninstaller
#
# This script is SELF-CONTAINED and installed to ~/.local/bin/voiceclaudecli-uninstall
# It does NOT require the project directory to exist (marketplace-friendly!)
#
# Removes:
# - Claude Code plugin registration (from installed_plugins.json)
# - Plugin installation directory (from marketplace or local)
# - Systemd user services
# - Launcher scripts in ~/.local/bin/
# - Running processes
# - Optionally: whisper models, development directory
#
# Usage:
#   voiceclaudecli-uninstall              # Interactive (default)
#   voiceclaudecli-uninstall --all        # Remove everything
#   voiceclaudecli-uninstall --keep-data  # Keep models & dev folder
#   voiceclaudecli-uninstall --help       # Show help
#===============================================================================

# Don't use set -e - we want graceful error handling
# set -e

# Parse command line arguments
UNINSTALL_MODE="interactive"  # interactive, all, keep-data

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
Voice-to-Claude-CLI Standalone Uninstaller

This uninstaller works regardless of how the plugin was installed:
  • From Claude Code marketplace
  • From local development directory
  • From git clone

Usage: voiceclaudecli-uninstall [OPTIONS]

Options:
  (none)          Interactive mode - prompts for each optional removal
  --all           Remove everything including models and dev directory
  --keep-data     Remove only system integration (keep models and dev files)
  --help, -h      Show this help message

What Gets Removed:
  Always:
    • Claude Code plugin registration
    • Plugin files (from marketplace or ~/.claude/plugins/local/)
    • Systemd services (daemon, whisper-server)
    • Launcher scripts (~/.local/bin/voiceclaudecli-*)
    • Running processes

  Optional (prompted in interactive mode):
    • Development directory (if found and separate from plugin)
    • whisper.cpp models (~142 MB)

Examples:
  voiceclaudecli-uninstall              # Ask about each optional item
  voiceclaudecli-uninstall --all        # Nuclear option - remove everything
  voiceclaudecli-uninstall --keep-data  # Keep models for re-install

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
║        🗑  Voice-to-Claude-CLI Uninstaller          ║
║           (Standalone - No Project Required)         ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

EOF

echo_info "This will remove Voice-to-Claude-CLI from your system"
echo_warning "This action cannot be undone!"
echo ""

# Find plugin installation from Claude's registry
CLAUDE_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
PLUGIN_INSTALL_PATH=""
PLUGIN_NAME=""

if [ -f "$CLAUDE_PLUGINS_JSON" ]; then
    echo_info "Checking Claude Code plugin registry..."

    # Look for voice-to-claude-cli plugin (could have different names)
    # Possible plugin names: voice@*, voiceclaudecli@*, voice-to-claude-cli@*
    PLUGIN_NAME=$(jq -r '.plugins | keys[] | select(test("voice|voiceclaudecli"))' "$CLAUDE_PLUGINS_JSON" 2>/dev/null | head -1)

    if [ -n "$PLUGIN_NAME" ]; then
        PLUGIN_INSTALL_PATH=$(jq -r ".plugins[\"$PLUGIN_NAME\"].installPath" "$CLAUDE_PLUGINS_JSON" 2>/dev/null)
        echo_success "Found plugin registration: $PLUGIN_NAME"
        echo_info "Install path: $PLUGIN_INSTALL_PATH"
    else
        echo_warning "Plugin not found in Claude Code registry"
        echo_info "Will remove system integration only"
    fi
else
    echo_warning "Claude Code plugin registry not found"
    echo_info "Will remove system integration only"
fi

echo ""
echo "The following will be removed:"
echo "  • Systemd services (daemon, whisper-server)"
echo "  • Launcher scripts in ~/.local/bin/"
echo "  • Running processes"
if [ -n "$PLUGIN_INSTALL_PATH" ]; then
    echo "  • Claude Code plugin: $PLUGIN_INSTALL_PATH"
fi
echo ""

# Ask for confirmation (if running interactively)
if [ -t 0 ] && [ "$UNINSTALL_MODE" = "interactive" ]; then
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Uninstall cancelled"
        exit 0
    fi
fi

echo ""
echo "========================================="
echo " Step 1/8: Stopping Services"
echo "========================================="
echo ""

# Stop systemd services
for service in voiceclaudecli-daemon whisper-server voice-holdtospeak voice-input; do
    if systemctl --user is-active "$service" &>/dev/null; then
        echo_info "Stopping $service..."
        systemctl --user stop "$service" 2>/dev/null || true
        echo_success "Stopped $service"
    fi
done

# Disable systemd services
for service in voiceclaudecli-daemon whisper-server voice-holdtospeak voice-input; do
    if systemctl --user is-enabled "$service" &>/dev/null; then
        echo_info "Disabling $service..."
        systemctl --user disable "$service" 2>/dev/null || true
        echo_success "Disabled $service"
    fi
done

echo ""
echo "========================================="
echo " Step 2/8: Killing Running Processes"
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
echo " Step 3/8: Removing Systemd Services"
echo "========================================="
echo ""

SERVICE_DIR="$HOME/.config/systemd/user"
SERVICES_REMOVED=0

for service_file in voiceclaudecli-daemon.service whisper-server.service voice-holdtospeak.service voice-input.service; do
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
echo " Step 4/8: Removing Launcher Scripts"
echo "========================================="
echo ""

BIN_DIR="$HOME/.local/bin"
SCRIPTS_REMOVED=0

# Note: We keep voiceclaudecli-uninstall until the very end (this script!)
for script in voiceclaudecli-daemon voiceclaudecli-input voiceclaudecli-interactive voiceclaudecli-stop-server claude-voice-input voice-input; do
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
echo " Step 5/8: Removing Claude Plugin Files"
echo "========================================="
echo ""

if [ -n "$PLUGIN_INSTALL_PATH" ] && [ -d "$PLUGIN_INSTALL_PATH" ]; then
    PLUGIN_SIZE=$(du -sh "$PLUGIN_INSTALL_PATH" 2>/dev/null | cut -f1)
    echo_info "Removing plugin files: $PLUGIN_INSTALL_PATH"

    # Safety check - don't remove if it's a system directory
    case "$PLUGIN_INSTALL_PATH" in
        /|/home|/usr|/bin|/sbin|/etc|/var)
            echo_error "Refusing to remove system directory: $PLUGIN_INSTALL_PATH"
            ;;
        *)
            rm -rf "$PLUGIN_INSTALL_PATH"
            echo_success "Removed plugin files ($PLUGIN_SIZE)"
            ;;
    esac
else
    echo_info "No plugin installation directory found"
fi

# Update Claude's installed_plugins.json
if [ -n "$PLUGIN_NAME" ] && [ -f "$CLAUDE_PLUGINS_JSON" ]; then
    echo_info "Updating Claude Code plugin registry..."

    # Create backup
    cp "$CLAUDE_PLUGINS_JSON" "$CLAUDE_PLUGINS_JSON.backup"

    # Remove plugin entry using jq
    if command -v jq &>/dev/null; then
        jq "del(.plugins[\"$PLUGIN_NAME\"])" "$CLAUDE_PLUGINS_JSON" > "$CLAUDE_PLUGINS_JSON.tmp" && \
        mv "$CLAUDE_PLUGINS_JSON.tmp" "$CLAUDE_PLUGINS_JSON"
        echo_success "Removed plugin registration from Claude Code"
        echo_info "Backup saved: $CLAUDE_PLUGINS_JSON.backup"
    else
        echo_warning "jq not installed - plugin entry not removed from registry"
        echo_info "Manual cleanup: Edit $CLAUDE_PLUGINS_JSON"
    fi
fi

# Check for local plugin copy
LOCAL_PLUGIN="$HOME/.claude/plugins/local/voice"
if [ -d "$LOCAL_PLUGIN" ]; then
    echo_info "Found local plugin copy: $LOCAL_PLUGIN"
    LOCAL_SIZE=$(du -sh "$LOCAL_PLUGIN" 2>/dev/null | cut -f1)
    rm -rf "$LOCAL_PLUGIN"
    echo_success "Removed local plugin copy ($LOCAL_SIZE)"
fi

echo ""
echo "========================================="
echo " Step 6/8: Cleaning Temporary Files"
echo "========================================="
echo ""

# Remove any temporary build artifacts
if [ -d "/tmp/whisper.cpp" ]; then
    echo_info "Removing /tmp/whisper.cpp..."
    TMP_SIZE=$(du -sh "/tmp/whisper.cpp" 2>/dev/null | cut -f1)
    rm -rf "/tmp/whisper.cpp"
    echo_success "Removed /tmp/whisper.cpp ($TMP_SIZE)"
else
    echo_info "No temporary build files found"
fi

if [ -f "/tmp/whisper-build.log" ]; then
    rm -f "/tmp/whisper-build.log"
    echo_success "Removed /tmp/whisper-build.log"
fi

echo ""
echo "========================================="
echo " Step 7/8: Optional - Dev Directory & Models"
echo "========================================="
echo ""

# Try to find development directory (separate from plugin installation)
POSSIBLE_DEV_DIRS=(
    "$HOME/voice-to-claude-cli"
    "$HOME/Voice-to-Claude-CLI"
    "$HOME/projects/voice-to-claude-cli"
    "$HOME/aldervall/voice-to-claude-cli"
    "$HOME/aldervall/Voice-to-Claude-CLI"
    "$HOME/code/voice-to-claude-cli"
    "$HOME/dev/voice-to-claude-cli"
)

# ╔══════════════════════════════════════════════════════════════════╗
# ║  CRITICAL SAFETY CHECK: Never remove current directory or parent ║
# ╚══════════════════════════════════════════════════════════════════╝
CURRENT_DIR=$(pwd 2>/dev/null || echo "/nowhere")

# Get the real path of current directory (resolve symlinks)
if [ -d "$CURRENT_DIR" ]; then
    CURRENT_DIR_REAL=$(cd "$CURRENT_DIR" && pwd -P 2>/dev/null || echo "$CURRENT_DIR")
else
    CURRENT_DIR_REAL="$CURRENT_DIR"
fi

# Find which dev directories actually exist (with multiple safety checks)
FOUND_DEV_DIRS=()
SKIPPED_CURRENT_DIR=false

for dir in "${POSSIBLE_DEV_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Get real path (resolve symlinks)
        DIR_REAL=$(cd "$dir" && pwd -P 2>/dev/null || echo "$dir")

        # Safety checks:
        # 1. Not the plugin install path
        # 2. Not the current directory (exact match)
        # 3. Not a parent of current directory
        # 4. Current directory is not inside this directory

        IS_SAFE=true

        # Check if it's the plugin path
        if [ "$DIR_REAL" = "$PLUGIN_INSTALL_PATH" ]; then
            IS_SAFE=false
        fi

        # Check if it's the current directory
        if [ "$DIR_REAL" = "$CURRENT_DIR_REAL" ]; then
            IS_SAFE=false
            SKIPPED_CURRENT_DIR=true
        fi

        # Check if current directory is inside this directory
        case "$CURRENT_DIR_REAL/" in
            "$DIR_REAL/"*)
                IS_SAFE=false
                SKIPPED_CURRENT_DIR=true
                ;;
        esac

        if [ "$IS_SAFE" = true ]; then
            FOUND_DEV_DIRS+=("$dir")
        fi
    fi
done

if [ "$SKIPPED_CURRENT_DIR" = true ]; then
    echo_warning "⚠⚠⚠ SAFETY: Skipped current working directory"
    echo_info "Directory: $CURRENT_DIR_REAL"
    echo_info "Reason: Never remove the directory you're currently in!"
    echo ""
fi

# Handle dev directory removal based on mode
REMOVE_DEV=false
if [ "$UNINSTALL_MODE" = "all" ]; then
    if [ ${#FOUND_DEV_DIRS[@]} -gt 0 ]; then
        echo_warning "⚠ --all flag will remove development directories!"
        echo_info "Found ${#FOUND_DEV_DIRS[@]} development director(ies):"
        for dev_dir in "${FOUND_DEV_DIRS[@]}"; do
            DEV_SIZE=$(du -sh "$dev_dir" 2>/dev/null | cut -f1 || echo "unknown")
            if [ -d "$dev_dir/.whisper/models" ]; then
                MODEL_SIZE=$(du -sh "$dev_dir/.whisper/models" 2>/dev/null | cut -f1)
                echo "  • $dev_dir ($DEV_SIZE, includes models: $MODEL_SIZE)"
            else
                echo "  • $dev_dir ($DEV_SIZE)"
            fi
        done
        echo ""
        if [ -t 0 ]; then
            echo_error "⚠⚠⚠ WARNING: This will DELETE development directories ⚠⚠⚠"
            read -p "Are you ABSOLUTELY SURE? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                REMOVE_DEV=true
            else
                echo_info "Keeping development directories"
            fi
        fi
    fi
elif [ "$UNINSTALL_MODE" = "keep-data" ]; then
    REMOVE_DEV=false
elif [ "$UNINSTALL_MODE" = "interactive" ] && [ ${#FOUND_DEV_DIRS[@]} -gt 0 ]; then
    echo_info "Found ${#FOUND_DEV_DIRS[@]} development director(ies):"
    for dev_dir in "${FOUND_DEV_DIRS[@]}"; do
        DEV_SIZE=$(du -sh "$dev_dir" 2>/dev/null | cut -f1 || echo "unknown")

        # Check if it contains whisper models
        if [ -d "$dev_dir/.whisper/models" ]; then
            MODEL_SIZE=$(du -sh "$dev_dir/.whisper/models" 2>/dev/null | cut -f1)
            echo "  • $dev_dir ($DEV_SIZE, includes models: $MODEL_SIZE)"
        else
            echo "  • $dev_dir ($DEV_SIZE)"
        fi
    done
    echo ""
    echo_warning "Development directories are separate from plugin installation"
    echo_info "Keep them if you want to contribute/modify the code"
    read -p "Remove development director(ies)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_DEV=true
    fi
fi

if [ "$REMOVE_DEV" = true ] && [ ${#FOUND_DEV_DIRS[@]} -gt 0 ]; then
    for dev_dir in "${FOUND_DEV_DIRS[@]}"; do
        echo_info "Removing $dev_dir..."
        DEV_SIZE=$(du -sh "$dev_dir" 2>/dev/null | cut -f1)

        # Safety check - don't remove system directories
        case "$dev_dir" in
            /|/home|/usr|/bin|/sbin|/etc|/var|/tmp)
                echo_error "Refusing to remove system directory: $dev_dir"
                ;;
            *)
                rm -rf "$dev_dir"
                echo_success "Removed $dev_dir ($DEV_SIZE)"
                ;;
        esac
    done
elif [ ${#FOUND_DEV_DIRS[@]} -gt 0 ]; then
    echo_info "Keeping development director(ies)"
    for dev_dir in "${FOUND_DEV_DIRS[@]}"; do
        echo "  • $dev_dir"
    done
else
    if [ "$SKIPPED_CURRENT_DIR" = false ]; then
        echo_info "No development directories found"
    fi
fi

echo ""
echo "========================================="
echo " Step 8/8: Final Cleanup"
echo "========================================="
echo ""

# Remove this uninstaller script itself (last step!)
if [ -f "$BIN_DIR/voiceclaudecli-uninstall" ]; then
    echo_info "Removing uninstaller script..."
    rm -f "$BIN_DIR/voiceclaudecli-uninstall"
    echo_success "Removed voiceclaudecli-uninstall"
fi

echo ""
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║           ✨ UNINSTALL COMPLETE! ✨                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

EOF

echo_success "Voice-to-Claude-CLI completely removed from your system"
echo ""

# Show what was kept
KEPT_ITEMS=()
if [ ${#FOUND_DEV_DIRS[@]} -gt 0 ] && [ "$REMOVE_DEV" = false ]; then
    for dev_dir in "${FOUND_DEV_DIRS[@]}"; do
        KEPT_ITEMS+=("Dev directory: $dev_dir")
    done
fi

if [ ${#KEPT_ITEMS[@]} -gt 0 ]; then
    echo_info "What was kept:"
    for item in "${KEPT_ITEMS[@]}"; do
        echo "  • $item"
    done
    echo ""
fi

echo_info "Manual cleanup (if needed):"
echo "  • Remove from 'input' group: sudo deluser \$USER input"
echo "  • Restart Claude Code to refresh plugin list"
echo ""

if [ ${#FOUND_DEV_DIRS[@]} -gt 0 ] && [ "$REMOVE_DEV" = false ]; then
    echo_success "To reinstall: cd ${FOUND_DEV_DIRS[0]} && bash scripts/install.sh"
else
    echo_success "To reinstall: Use Claude Code plugin marketplace"
    echo_success "Or manually: git clone https://github.com/aldervall/Voice-to-Claude-CLI.git && cd Voice-to-Claude-CLI && bash scripts/install.sh"
fi
echo ""
