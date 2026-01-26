# Claude Code Skills for Template Loading

## What These Skills Are

These skills are part of a **Claude Code plugin** that allows users to load AI agent instruction templates into their projects via Claude Code's plugin system.

When users add this repository as a Claude Code marketplace and install the plugin, they get access to skills namespaced under `ait` (AI Templates):

- `/ait:load-template` - Load a template into the current project
- `/ait:list-templates` - List available templates

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

These skills are a convenience for Claude Code users. The primary, tool-agnostic method is the `load.sh` script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/.../load.sh)" -- Software-Technical-Planner
```

This works with any AI tool, not just Claude Code.
