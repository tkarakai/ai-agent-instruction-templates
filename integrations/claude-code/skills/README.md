# Claude Code Skills for Template Loading

## What These Skills Are

These skills are part of a **Claude Code plugin** that allows users to load AI agent instruction templates into their projects via Claude Code's plugin system.

When users add this repository as a Claude Code marketplace and install the plugin, they get access to skills namespaced under `ait` (AI Templates):

- `/ait:load-template` - Load a template into the current project
- `/ait:list-templates` - List available templates

## Important Distinction: Two Types of Skills

This framework uses "skills" in two different ways:

| Type | Description | Location |
|------|-------------|----------|
| **Skills for Delivery** | These skills (`load-template`, `list-templates`) that help load templates | This directory |
| **Skills as Dependencies** | External skills that templates may reference in their `template.yaml` | NOT in this repo |

**Skills as Dependencies** are capabilities like `github-pr` or `code-analysis` that a template might use during execution. These are provided by other plugins or Claude Code itself—not by this repository.

For details on declaring skill dependencies in templates, see [Skills as Dependencies](../../../README.md#skills-as-dependencies) in the root README.

## Installation of Skills for Template Delivery

### Quick Install with npx add-skill

**Prerequisites:**
- Node.js and npm installed on your system

The fastest way to install these skills is using `npx add-skill`:

```bash
# Install all skills from this repository
npx add-skill tkarakai/ai-agent-instruction-templates

# Or install specific skills
npx add-skill tkarakai/ai-agent-instruction-templates --skill load-template
npx add-skill tkarakai/ai-agent-instruction-templates --skill list-templates

# Or install both skills at once:
npx add-skill tkarakai/ai-agent-instruction-templates --skill load-template --skill list-templates
```

After installation, restart Claude Code and verify with `/skills`. You should see `load-template` and `list-templates` listed under "Plugin skills (ait)".

**Note:** Plugin skills might not appear in autocomplete when typing `/`. You must type the full command (e.g., `/ait:load-template`) or ask Claude to perform the task in natural language (e.g., "list the available templates").

### Manual Installation via Marketplace

#### 1. Add the Marketplace

In Claude Code, run:

```bash
/plugin marketplace add tkarakai/ai-agent-instruction-templates
```

#### 2. Install the Plugin

After adding the marketplace, install the plugin:

```bash
/plugin install ait@ai-agent-instruction-templates
```

#### 3. Restart and Verify

Restart Claude Code to load the new plugin, then verify installation:

```bash
/skills
```

You should see `load-template` and `list-templates` listed under "Plugin skills (ait)".

#### 4. Use the Skills

Once verified, the skills are available:

```bash
# List available templates
/ait:list-templates

# Load a template into your project
/ait:load-template Software-Technical-Planner

# Load a specific version
/ait:load-template Software-Technical-Planner@v1.0.0
```

**Note:** Plugin skills might not appear in autocomplete when typing `/`. You must type the full command (e.g., `/ait:load-template`) or ask Claude to perform the task in natural language (e.g., "list the available templates").

#### Plugin Files

- `.claude-plugin/marketplace.json` - Plugin registration
- `integrations/claude-code/skills/*/SKILL.md` - Individual skill definitions

## What These Skills Are NOT

**These skills are NOT used in this repository itself.**

Unlike typical skills that provide capabilities for the repo they reside in, these skills are:

1. **Hosted here** - in the template library repository
2. **Used elsewhere** - in target projects where users want to load templates

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  This Repository (ai-agent-instruction-templates)           │
│                                                             │
│  - Hosts templates in /templates/                           │
│  - Hosts these skills as a Claude Code plugin               │
│  - load.sh provides tool-agnostic loading                   │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ User adds marketplace & installs plugin
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Target Project (user's project)                            │
│                                                             │
│  User runs: /ait:load-template Software-Technical-Planner   │
│                                                             │
│  Result: Template downloaded to .agents/ directory          │
└─────────────────────────────────────────────────────────────┘
```

## Alternative: Tool-Agnostic Loading

These skills are a convenience for Claude Code users. The primary, tool-agnostic method is the `load.sh` script documented in the [Quick Start](../../../README.md#quick-start) section of the root README.

The script works with any AI tool, not just Claude Code.
