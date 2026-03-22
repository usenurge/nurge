#!/bin/bash
set -euo pipefail

REPO="usenurge/nurge"
BINARY="nurge"
INSTALL_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BOLD}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
error() { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    darwin) OS="darwin" ;;
    linux)  OS="linux" ;;
    mingw*|msys*|cygwin*) error "Use PowerShell on Windows: irm https://raw.githubusercontent.com/$REPO/main/install.ps1 | iex" ;;
    *) error "Unsupported OS: $OS" ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)  ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

# Get version (argument or latest)
if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    info "Fetching latest version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        # No stable release yet, try latest pre-release
        VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    if [ -z "$VERSION" ]; then
        error "Could not determine latest version. Pass a version explicitly: curl ... | bash -s -- v0.1.0-alpha.1"
    fi
fi

# Strip leading 'v' for filename
VERSION_NUM="${VERSION#v}"

FILENAME="nurge_${VERSION_NUM}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"

info "Installing nurge $VERSION ($OS/$ARCH)..."

# Download and extract
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$URL" -o "$TMPDIR/$FILENAME" || error "Download failed. Check that $VERSION exists at https://github.com/$REPO/releases"
tar -xzf "$TMPDIR/$FILENAME" -C "$TMPDIR"

# Install
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMPDIR/$BINARY" "$INSTALL_DIR/$BINARY"
else
    info "Need sudo to install to $INSTALL_DIR"
    sudo mv "$TMPDIR/$BINARY" "$INSTALL_DIR/$BINARY"
fi

chmod +x "$INSTALL_DIR/$BINARY"

# Verify
if command -v nurge &>/dev/null; then
    success "nurge installed successfully!"
    echo ""
    info "Get started:"
    echo "  nurge init"
else
    error "Installation completed but 'nurge' not found in PATH. Add $INSTALL_DIR to your PATH."
fi
