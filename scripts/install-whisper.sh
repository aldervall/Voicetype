#!/bin/bash
#
# whisper.cpp Auto-Installer
# Uses pre-built binary or compiles from source if needed
# Works standalone or as Claude Code plugin
#
# NOTE: We DO NOT use 'set -e' to allow graceful error handling

# Detect if running from Claude Code plugin or standalone
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    # Running from Claude Code plugin - use plugin root
    PROJECT_ROOT="$CLAUDE_PLUGIN_ROOT"
    echo "Detected Claude Code plugin installation"
else
    # Running standalone - use script location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    echo "Running standalone installation"
fi

WHISPER_BIN_DIR="$PROJECT_ROOT/.whisper/bin"
WHISPER_MODELS_DIR="$PROJECT_ROOT/.whisper/models"
MODEL_NAME="${MODEL_NAME:-base.en}"
PORT="${PORT:-2022}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}ℹ${NC} $1"; }
echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }
echo_step() { echo -e "${CYAN}${BOLD}▶${NC} ${BOLD}$1${NC}"; }
echo_header() { echo -e "${MAGENTA}${BOLD}$1${NC}"; }

# Detect if running non-interactively (from Claude Code or CI)
if [ -t 0 ]; then
    INTERACTIVE="${INTERACTIVE:-true}"
else
    INTERACTIVE="${INTERACTIVE:-false}"
fi
# Allow explicit override via environment variable
INTERACTIVE="${INTERACTIVE:-true}"

echo
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║     🎙️  WHISPER.CPP AUTO-INSTALLER                  ║
║                                                       ║
║     Local AI Voice Recognition Engine                ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        BINARY_NAME="whisper-server-linux-x64"
        ;;
    aarch64|arm64)
        BINARY_NAME="whisper-server-linux-arm64"
        ;;
    *)
        echo_warning "Unsupported architecture: $ARCH"
        BINARY_NAME=""
        ;;
esac

# Check for pre-built binary
WHISPER_BINARY=""
if [ -n "$BINARY_NAME" ] && [ -f "$WHISPER_BIN_DIR/$BINARY_NAME" ]; then
    echo_success "Found pre-built binary: $BINARY_NAME"
    WHISPER_BINARY="$WHISPER_BIN_DIR/$BINARY_NAME"
    USE_PREBUILT=true
else
    echo_info "No pre-built binary found for $ARCH"
    echo_info "Will build from source..."
    USE_PREBUILT=false

    # Check for required build tools
    echo_info "Checking build dependencies..."

    MISSING_DEPS=()

    if ! command -v git &>/dev/null; then
        MISSING_DEPS+=("git")
    fi

    if ! command -v make &>/dev/null; then
        MISSING_DEPS+=("make")
    fi

    if ! command -v g++ &>/dev/null && ! command -v clang++ &>/dev/null; then
        MISSING_DEPS+=("g++ or clang++")
    fi

    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        echo_error "Missing required build tools: ${MISSING_DEPS[*]}"
        echo
        echo "Install them with:"

        # Detect distro and show appropriate command
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                arch|manjaro|cachyos)
                    echo "  sudo pacman -S git make gcc"
                    ;;
                ubuntu|debian|pop|mint)
                    echo "  sudo apt install git build-essential"
                    ;;
                fedora|rhel|centos)
                    echo "  sudo dnf install git make gcc-c++"
                    ;;
                opensuse*)
                    echo "  sudo zypper install git make gcc-c++"
                    ;;
            esac
        fi

        exit 1
    fi

    echo_success "All build dependencies found"
fi

echo

# Build from source if not using pre-built binary
if [ "$USE_PREBUILT" = false ]; then
    WHISPER_DIR="/tmp/whisper.cpp"

    # Clone or update whisper.cpp
    if [ -d "$WHISPER_DIR" ]; then
        echo_info "whisper.cpp directory exists: $WHISPER_DIR"
        echo_info "Using existing directory"
        cd "$WHISPER_DIR"
        echo_info "Pulling latest changes..."
        git pull || true  # Don't fail if no internet
    else
        echo_info "Cloning whisper.cpp..."
        if ! git clone https://github.com/ggerganov/whisper.cpp "$WHISPER_DIR"; then
            echo_error "Failed to clone whisper.cpp repository!"
            echo
            echo_info "Troubleshooting steps:"
            echo "  1. Check internet connection: ping -c 3 github.com"
            echo "  2. Check git is installed: git --version"
            echo "  3. Try manually: git clone https://github.com/ggerganov/whisper.cpp $WHISPER_DIR"
            echo
            echo_error "Cannot continue without whisper.cpp source code"
            exit 1
        fi
        cd "$WHISPER_DIR"
        echo_success "Cloned whisper.cpp"
    fi

    echo

    # Build whisper.cpp
    echo "========================================"
    echo "Building whisper.cpp"
    echo "========================================"
    echo

    echo_info "Compiling... (this may take a few minutes)"
    echo

    # Build with make (simple, works on all platforms)
    if make -j$(nproc) server 2>&1 | tee /tmp/whisper-build.log; then
        echo_success "Build successful!"

        # Copy binary to .whisper/bin/
        mkdir -p "$WHISPER_BIN_DIR"

        if ! cp "$WHISPER_DIR/build/bin/whisper-server" "$WHISPER_BIN_DIR/$BINARY_NAME"; then
            echo_error "Failed to copy binary (build may have failed silently)"
            echo_info "Check build output above and /tmp/whisper-build.log"
            exit 1
        fi

        chmod +x "$WHISPER_BIN_DIR/$BINARY_NAME"
        WHISPER_BINARY="$WHISPER_BIN_DIR/$BINARY_NAME"
        echo_success "Binary copied to: $WHISPER_BINARY"
    else
        echo_error "Build failed!"
        echo
        echo_info "Troubleshooting steps:"
        echo "  1. Check build log: cat /tmp/whisper-build.log"
        echo "  2. Verify build tools: make --version && g++ --version"
        echo "  3. Check disk space: df -h"
        echo "  4. Try manually:"
        echo "     cd $WHISPER_DIR"
        echo "     make clean"
        echo "     make server"
        echo
        echo_error "Cannot continue without whisper-server binary"
        exit 1
    fi

    echo
fi

# Download model
echo
echo_header "╔═══════════════════════════════════════════════════════╗"
echo_header "║  📥 Downloading Whisper Model (~142 MB)              ║"
echo_header "╚═══════════════════════════════════════════════════════╝"
echo

mkdir -p "$WHISPER_MODELS_DIR"
MODEL_PATH="$WHISPER_MODELS_DIR/ggml-${MODEL_NAME}.bin"

if [ -f "$MODEL_PATH" ]; then
    echo_success "Model already exists: $MODEL_PATH"
else
    echo_info "Downloading $MODEL_NAME model (~142MB)..."
    bash "$PROJECT_ROOT/.whisper/scripts/download-model.sh" "$MODEL_NAME"
    echo_success "Model downloaded"
fi

echo

# Test the server
echo "========================================"
echo "Testing whisper Server"
echo "========================================"
echo

# Check if server is already running on port
if curl -s http://127.0.0.1:$PORT/health >/dev/null 2>&1; then
    echo_success "whisper server is already running on port $PORT"
else
    echo_info "Starting test server on port $PORT..."

    # Start server in background
    "$WHISPER_BINARY" \
        --model "$MODEL_PATH" \
        --host 127.0.0.1 \
        --port $PORT \
        --inference-path "/v1/audio/transcriptions" \
        --threads 4 \
        --processors 1 \
        --convert \
        --print-progress &

    SERVER_PID=$!

    # Wait for server to start
    sleep 3

    # Test server health
    if curl -s http://127.0.0.1:$PORT/health | grep -q "ok"; then
        echo_success "Server is responding correctly!"

        # Kill test server
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    else
        echo_error "Server health check failed"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
fi

echo

# Create systemd service
echo "========================================"
echo "Creating systemd Service"
echo "========================================"
echo

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/whisper-server.service" <<EOF
[Unit]
Description=whisper.cpp Server for Local Speech-to-Text
After=default.target

[Service]
Type=simple
ExecStart=$WHISPER_BINARY \\
    --model $MODEL_PATH \\
    --host 127.0.0.1 \\
    --port $PORT \\
    --inference-path "/v1/audio/transcriptions" \\
    --threads 4 \\
    --processors 1 \\
    --convert \\
    --print-progress
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo_success "Created: $SYSTEMD_USER_DIR/whisper-server.service"

# Reload systemd
systemctl --user daemon-reload
echo_success "Systemd daemon reloaded"

echo

# Ask to start service
if [ "$INTERACTIVE" = "true" ]; then
    read -p "Start whisper server now? [Y/n]: " START_NOW
    START_NOW=${START_NOW:-y}
else
    # Non-interactive mode: default to yes
    START_NOW="${AUTO_START_SERVER:-y}"
    echo_info "Non-interactive mode: Starting whisper server (override with AUTO_START_SERVER=n)"
fi

if [[ "$START_NOW" =~ ^[Yy] ]]; then
    echo_info "Starting whisper-server..."
    systemctl --user start whisper-server
    echo_success "Server started"

    # Wait a moment for startup
    sleep 2

    # Check status
    if systemctl --user is-active whisper-server &>/dev/null; then
        echo_success "Server is running!"

        # Test health endpoint
        if curl -s http://127.0.0.1:$PORT/health | grep -q "ok"; then
            echo_success "Health check passed!"
        else
            echo_warning "Server running but health check failed"
        fi
    else
        echo_warning "Server failed to start, check logs:"
        echo "  journalctl --user -u whisper-server -n 50"
    fi
fi

echo

# Ask to enable auto-start
if [ "$INTERACTIVE" = "true" ]; then
    read -p "Enable auto-start on login? [Y/n]: " ENABLE_AUTO
    ENABLE_AUTO=${ENABLE_AUTO:-y}
else
    # Non-interactive mode: default to yes
    ENABLE_AUTO="${AUTO_ENABLE_SERVICE:-y}"
    echo_info "Non-interactive mode: Enabling auto-start (override with AUTO_ENABLE_SERVICE=n)"
fi

if [[ "$ENABLE_AUTO" =~ ^[Yy] ]]; then
    systemctl --user enable whisper-server
    echo_success "Auto-start enabled"
fi

echo

# Final summary
echo "========================================"
echo "whisper.cpp Installation Complete!"
echo "========================================"
echo

if [ "$USE_PREBUILT" = true ]; then
    echo_success "Using pre-built binary (no compilation needed!)"
else
    echo_success "Built from source"
fi
echo_success "Binary: $WHISPER_BINARY"
echo_success "Model: $MODEL_PATH"
echo_success "Port: $PORT"
echo

echo "Service management:"
echo "  systemctl --user start whisper-server    # Start server"
echo "  systemctl --user stop whisper-server     # Stop server"
echo "  systemctl --user status whisper-server   # Check status"
echo "  systemctl --user enable whisper-server   # Auto-start on login"
echo

echo "Logs:"
echo "  journalctl --user -u whisper-server -f"
echo

echo "Health check:"
echo "  curl http://127.0.0.1:$PORT/health"
echo

echo "Manual start (if needed):"
echo "  bash $PROJECT_ROOT/.whisper/scripts/start-server.sh"
echo

echo "To test transcription, use voiceclaudecli-daemon or voiceclaudecli-input!"
echo
