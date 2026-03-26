#!/bin/bash
set -euo pipefail

# Nurge installer
# Usage:
#   curl -fsSL https://install.nurge.sh | bash
#   curl -fsSL https://install.nurge.sh | bash -s -- --pre
#   curl -fsSL https://install.nurge.sh | bash -s -- v0.1.0

REPO="usenurge/nurge"
INSTALL_DIR="/usr/local/bin"
BINARY="nurge"

# --- Helpers ---

info()  { printf "\033[1;34m→\033[0m %s\n" "$1" >&2; }
ok()    { printf "\033[1;32m✓\033[0m %s\n" "$1" >&2; }
warn()  { printf "\033[1;33m!\033[0m %s\n" "$1" >&2; }
fail()  { printf "\033[1;31m✗\033[0m %s\n" "$1" >&2; exit 1; }

# --- Detect platform ---

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "darwin" ;;
    *)       fail "Unsupported OS: $(uname -s)" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    *)             fail "Unsupported architecture: $(uname -m)" ;;
  esac
}

# --- Resolve version ---

resolve_version() {
  local requested="${1:-}"
  local pre="${2:-false}"

  if [ -n "$requested" ] && [ "$requested" != "--pre" ]; then
    echo "$requested"
    return
  fi

  info "Fetching latest release..."
  local releases
  releases=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases?per_page=20") || fail "Failed to fetch releases"

  local version=""
  if [ "$pre" = "true" ]; then
    version=$(echo "$releases" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"//;s/"//')
  else
    version=$(echo "$releases" | grep -o '"tag_name": *"[^"]*"' | grep -v 'alpha\|beta\|rc' | head -1 | sed 's/.*"tag_name": *"//;s/"//')
  fi

  [ -z "$version" ] && fail "No release found"
  echo "$version"
}

# --- Download & install ---

install() {
  local version="$1"
  local os="$2"
  local arch="$3"

  local archive_name="${BINARY}_${version#v}_${os}_${arch}"
  local ext="tar.gz"
  [ "$os" = "windows" ] && ext="zip"

  local url="https://github.com/${REPO}/releases/download/${version}/${archive_name}.${ext}"

  info "Downloading ${BINARY} ${version} (${os}/${arch})..."
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  curl -fsSL "$url" -o "${tmpdir}/archive.${ext}" || fail "Download failed. Check that ${version} exists at https://github.com/${REPO}/releases"

  info "Extracting..."
  if [ "$ext" = "tar.gz" ]; then
    tar -xzf "${tmpdir}/archive.${ext}" -C "$tmpdir"
  else
    unzip -q "${tmpdir}/archive.${ext}" -d "$tmpdir"
  fi

  # Find the binary (may be nested in a directory)
  local bin_path
  bin_path=$(find "$tmpdir" -name "$BINARY" -type f | head -1)
  [ -z "$bin_path" ] && fail "Binary not found in archive"

  chmod +x "$bin_path"

  # Install to target directory
  if [ -w "$INSTALL_DIR" ]; then
    mv "$bin_path" "${INSTALL_DIR}/${BINARY}"
  else
    info "Need sudo to install to ${INSTALL_DIR}"
    sudo mv "$bin_path" "${INSTALL_DIR}/${BINARY}"
  fi

  ok "Installed ${BINARY} ${version} to ${INSTALL_DIR}/${BINARY}"
}

# --- Main ---

main() {
  local arg="${1:-}"
  local pre=false

  if [ "$arg" = "--pre" ]; then
    pre=true
    arg=""
  fi

  local os arch version
  os=$(detect_os)
  arch=$(detect_arch)
  version=$(resolve_version "$arg" "$pre")

  install "$version" "$os" "$arch"

  # Post-install: next steps
  echo ""
  echo "  Get started:"
  echo "    nurge my-outbound"
  echo "    cd my-outbound"
  echo ""
}

main "$@"
