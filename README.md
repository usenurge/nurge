# Nurge

Outbound sales tool that learns from your sent email history.

## Install

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/usenurge/nurge/main/install.sh | bash
```

**Specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/usenurge/nurge/main/install.sh | bash -s -- v0.1.0-alpha.1
```

**Manual download:**

Download the latest release from the [Releases page](https://github.com/usenurge/nurge/releases).

## Uninstall

```bash
rm /usr/local/bin/nurge
rm -rf .nurge/  # in your project directory
```

## Requirements

- [Claude Code](https://claude.ai/code) — required for AI-powered features

## Get Started

```bash
nurge init
```

Then open Claude Code and run `/nurge:setup`.
