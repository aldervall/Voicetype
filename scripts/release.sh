#!/bin/bash
#
# VoiceType Release Script
# Automates GitHub release + AUR package update in one command
#
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.6.0
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}→${NC} $1"; }
echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }

# Banner
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   VoiceType Release Automation           ║"
echo "║   GitHub + AUR in one command            ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Validate arguments
if [ -z "$1" ]; then
    echo_error "Usage: $0 <version>"
    echo "  Example: $0 1.6.0"
    exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AUR_DIR="$PROJECT_ROOT/aur"
PKGBUILD="$AUR_DIR/PKGBUILD"

cd "$PROJECT_ROOT"

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo_error "Invalid version format: $VERSION"
    echo "  Expected format: X.Y.Z (e.g., 1.6.0)"
    exit 1
fi

echo_info "Releasing version: $VERSION"
echo ""

# Check prerequisites
echo "━━━ Checking Prerequisites ━━━"

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo_error "GitHub CLI (gh) not installed"
    echo "  Install: sudo pacman -S github-cli"
    echo "  Then: gh auth login"
    exit 1
fi
echo_success "GitHub CLI available"

# Check makepkg for .SRCINFO generation
if ! command -v makepkg &> /dev/null; then
    echo_error "makepkg not found (are you on Arch?)"
    exit 1
fi
echo_success "makepkg available"

# Check we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo_error "Not on main branch (currently on: $CURRENT_BRANCH)"
    echo "  Run: git checkout main"
    exit 1
fi
echo_success "On main branch"

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo_error "Uncommitted changes detected"
    echo "  Commit or stash your changes first"
    exit 1
fi
echo_success "Working tree clean"

# Check AUR remote exists
if ! git remote | grep -q "^aur$"; then
    echo_error "AUR remote not configured"
    echo "  Run: git remote add aur ssh://aur@aur.archlinux.org/voicetype-bin.git"
    exit 1
fi
echo_success "AUR remote configured"

echo ""
echo "━━━ Step 1/7: Update PKGBUILD Version ━━━"

# Update pkgver in PKGBUILD
sed -i "s/^pkgver=.*/pkgver=$VERSION/" "$PKGBUILD"
# Reset pkgrel to 1 for new version
sed -i "s/^pkgrel=.*/pkgrel=1/" "$PKGBUILD"
echo_success "Updated PKGBUILD to version $VERSION"

echo ""
echo "━━━ Step 2/7: Commit Version Bump ━━━"

git add "$PKGBUILD"
git commit -m "chore: Bump version to $VERSION"
echo_success "Committed version bump"

echo ""
echo "━━━ Step 3/7: Create Git Tag ━━━"

git tag -a "v$VERSION" -m "Release v$VERSION"
echo_success "Created tag v$VERSION"

echo ""
echo "━━━ Step 4/7: Push to GitHub ━━━"

git push origin main
git push origin "v$VERSION"
echo_success "Pushed to GitHub origin"

echo ""
echo "━━━ Step 5/7: Create GitHub Release ━━━"

# Create GitHub release (this generates the tarball)
gh release create "v$VERSION" \
    --title "VoiceType v$VERSION" \
    --notes "Release v$VERSION" \
    --latest
echo_success "Created GitHub release"

# Wait for release to be available
sleep 3

echo ""
echo "━━━ Step 6/7: Calculate SHA256 ━━━"

# Download tarball and calculate SHA256
TARBALL_URL="https://github.com/aldervall/Voicetype/archive/v$VERSION.tar.gz"
echo_info "Downloading: $TARBALL_URL"

SHA256=$(curl -sL "$TARBALL_URL" | sha256sum | cut -d' ' -f1)

if [ -z "$SHA256" ] || [ "$SHA256" == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]; then
    echo_error "Failed to calculate SHA256 (empty file?)"
    echo "  The release tarball may not be available yet"
    echo "  Wait a moment and run manually:"
    echo "  curl -sL '$TARBALL_URL' | sha256sum"
    exit 1
fi

echo_success "SHA256: $SHA256"

# Update sha256sums in PKGBUILD
sed -i "s/^sha256sums=.*/sha256sums=('$SHA256')/" "$PKGBUILD"
echo_success "Updated PKGBUILD sha256sums"

echo ""
echo "━━━ Step 7/7: Push to AUR ━━━"

# Generate .SRCINFO
cd "$AUR_DIR"
makepkg --printsrcinfo > .SRCINFO
echo_success "Generated .SRCINFO"

# Commit and push to AUR
cd "$PROJECT_ROOT"
git add "$AUR_DIR/PKGBUILD" "$AUR_DIR/.SRCINFO"
git commit -m "aur: Update to v$VERSION"

# Push to both remotes
git push origin main
echo_success "Pushed to GitHub"

# Push AUR directory to AUR remote
# AUR expects PKGBUILD at root, so we use subtree push
git subtree push --prefix=aur aur master
echo_success "Pushed to AUR"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   🎉 Release Complete!                   ║"
echo "╠══════════════════════════════════════════╣"
echo "║   Version: $VERSION"
echo "║   GitHub:  https://github.com/aldervall/Voicetype/releases/tag/v$VERSION"
echo "║   AUR:     https://aur.archlinux.org/packages/voicetype-bin"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Users can now install with:"
echo "  yay -S voicetype-bin"
echo ""
