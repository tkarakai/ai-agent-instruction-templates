# Loading Templates with Claude Code Skills

## Introduction

There are two ways to load AI agent instruction templates into your project:

**a) Using the `load.sh` shell script** — Works with any AI tool. See the [Quick Start](../../../README.md#quick-start) section in the main README.

**b) Using Claude Code skills** — A convenience wrapper around the shell script for Claude Code users.

If you want to load templates using skills in Claude Code, we recommend these installation options:

1. **`npx skills add`** — Quick one-command installation
2. **Claude Code Marketplace plugin** — Manual installation via Claude Code's plugin system

> **Note:** This repository functions as a Claude Code marketplace thanks to these files:
> - `.claude-plugin/marketplace.json` — Marketplace registration
> - `integrations/claude-code/.claude-plugin/plugin.json` — Plugin definition

## How to Install Skills

### Option 1: Using `npx skills add`

**Prerequisites:** Node.js and npm installed on your system.

```bash
# Install all skills from this repository
npx skills add tkarakai/ai-agent-instruction-templates

# Or install specific skills
npx skills add tkarakai/ai-agent-instruction-templates --skill load-template
npx skills add tkarakai/ai-agent-instruction-templates --skill list-templates
```

### Option 2: Using Claude Code Marketplace Plugin

**Step 1: Add the Marketplace**

```bash
/plugin marketplace add tkarakai/ai-agent-instruction-templates
```

**Step 2: Install the Plugin**

```bash
/plugin install ait@ai-agent-instruction-templates
```

## How to Verify Skills Installation

After installation, you might need to restart Claude Code. To verify, type `/skills`. You should see `load-template` and `list-templates` listed under "Plugin skills (ait)".

## How to Use the Skills

Once installed, the skills are available in any project:

```bash
# List available templates
/ait:list-templates

# Load a template into your project
/ait:load-template Software-Technical-Planner

# Load a specific version
/ait:load-template Software-Technical-Planner@v1.0.0
```

**Note:** Plugin skills might not appear in autocomplete when typing `/`. You must type the full command (e.g., `/ait:load-template`) or ask Claude to perform the task in natural language (e.g., "list the available templates").

> **Sidenote:** Typically, skills are installed into a repository's directory alongside other agent guidance documents for use by an AI agent working on that project. This is not the case here—these skills are hosted in this repository but used in other projects to load templates. They are not used to develop or work on this repository itself.
