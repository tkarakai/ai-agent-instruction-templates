# AI Agent Instructions Templates

A library of reusable, versioned instruction templates for AI coding agents.

## Overview

This repository provides self-contained instruction sets that can be temporarily loaded into any project to guide AI agents through specific tasks. Templates define what an agent does, what inputs it expects, and what outputs it produces.

## Concept & Rationale

### The Problem

When using AI coding agents, you often need to provide detailed instructions for complex tasks. These instructions:
- Get copy-pasted between projects, leading to drift
- Clutter project repositories with operational tooling
- Lack versioning and traceability
- Are hard to share and improve collaboratively

### The Solution

This framework treats agent instructions like external dependencies:

1. **Temporary presence** - Templates are copied into a project while an agent works, then removed when done. The project references which template was used (in commits/PRs) but doesn't permanently store the instructions.

2. **Independent versioning** - Each template has its own semantic version tracked via git tags. Templates evolve independently of the projects that use them.

3. **Traceability** - Commits and PRs reference template name, version, and commit hash. This provides full audit trail without storing redundant copies.

4. **Reusability** - Teams converge on shared templates rather than maintaining separate instruction sets per project.

Think of it like using a linter: you don't commit ESLint's source code into your project—you reference a version and let it do its job.

### Guidance, Not Enforcement

This framework provides **recommendations and conventions**, not enforced tooling:

- Use git worktrees, branches, or work directly—whatever suits your workflow
- Use the provided loader script or copy files manually
- Follow the suggested commit conventions or adapt them
- Keep instructions after the agent finishes or delete them

## Usage

### Quick Start

```bash
# Load a template into your project
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- Software-Technical-Planner

# Load a specific version
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- Software-Technical-Planner@v1.0.0
```

This creates:
```
.agents/
├── Software-Technical-Planner/    # Primary template
│   └── AGENTS.md                  # Instructions for the agent
└── .loaded-templates.yaml         # Manifest for traceability
```

Then point your AI tool to `.agents/Software-Technical-Planner/AGENTS.md`.

### Detailed Instructions

See **[RUNBOOK.md](RUNBOOK.md)** for complete workflow documentation:
- Setting up isolated environments (worktrees, branches)
- Loading and configuring templates
- Running agents
- Recording template usage in commits/PRs
- Chaining multiple agents
- Cleanup

### Tool Integration

Templates are tool-agnostic. Point your AI tool to the instructions:

| Tool | Integration |
|------|-------------|
| Claude Code | Add `Read .agents/<template>/AGENTS.md` to `CLAUDE.md` |
| Cursor | Reference from `.cursorrules` |
| GitHub Copilot | Reference in `.github/copilot-instructions.md` |
| Other | Tell the agent directly |

## Repository Structure

```
ai-agent-instruction-templates/
├── README.md                    # This file
├── RUNBOOK.md                   # Usage workflow guide
├── load.sh                      # Template loader (for users)
├── dev/
│   └── version.sh               # Version management (for maintainers)
└── templates/
    └── <template-name>/
        ├── README.md            # Documentation (not copied)
        ├── template.yaml        # Metadata (not copied)
        └── files/               # Copied to target project
            └── AGENTS.md
```

## Contributing

### Creating a New Template

1. Create a directory under `templates/` with a descriptive kebab-case name:
   ```bash
   mkdir -p templates/My-New-Template/files
   ```

2. Create `template.yaml` with metadata:
   ```yaml
   name: My-New-Template
   version: 0.1.0
   description: Brief description of what this template does

   inputs:
     - name: INPUT_FILE.md
       required: true
       description: What this input contains

   outputs:
     - name: OUTPUT_FILE.md
       description: What the agent produces

   # Include-style dependencies (loaded alongside this template)
   # Format: TemplateName or TemplateName@vX.Y.Z
   dependencies: []
   ```

3. Create `README.md` documenting the template:
   - Purpose and use case
   - Input artifacts (what must exist before agent starts)
   - Output artifacts (what agent produces)
   - Sequence dependencies (what should run before/after—not enforced)
   - Example usage

4. Create `files/AGENTS.md` with the agent instructions:
   - Clear, actionable directives
   - Reference to input/output artifacts
   - Commit message format including template info
   - Checklist for completion

5. Create the initial version:
   ```bash
   ./dev/version.sh My-New-Template --patch
   ```

### Template Checklist

- [ ] `template.yaml` with name, version, description, inputs, outputs
- [ ] `README.md` documenting purpose, artifacts, and usage
- [ ] `files/AGENTS.md` with clear instructions
- [ ] Instructions reference `.loaded-templates.yaml` for commit metadata
- [ ] Git tag created via `dev/version.sh`

### Versioning Templates

Use `dev/version.sh` to manage versions:

```bash
# Interactive mode
./dev/version.sh My-Template

# Specific bump type
./dev/version.sh My-Template --patch    # x.y.Z - bug fixes
./dev/version.sh My-Template --minor    # x.Y.0 - new features
./dev/version.sh My-Template --major    # X.0.0 - breaking changes

# Pre-release versions
./dev/version.sh My-Template --patch --alpha
./dev/version.sh My-Template --minor --beta
./dev/version.sh My-Template --patch --rc

# Preview without making changes
./dev/version.sh My-Template --patch --dry-run
```

The script:
- Discovers the latest version (or starts at 0.0.1 for new templates)
- Updates `template.yaml`
- Commits the change
- Creates a git tag: `Template-Name/vX.Y.Z`
- Updates the `Template-Name/latest` tag

**Version tags use template name prefix:**
```
Software-Technical-Planner/v1.0.0
Software-Technical-Planner/v1.1.0
Code-Implementer/v1.0.0
```

### Updating a Template

1. Make changes to files in `templates/<name>/`
2. Update the version: `./dev/version.sh <name> --patch`
3. Push changes and tags:
   ```bash
   git push origin main
   git push origin <name>/vX.Y.Z
   git push -f origin <name>/latest
   ```

### Deleting a Template

1. Remove the template directory
2. Optionally delete the git tags:
   ```bash
   git tag -d Template-Name/v1.0.0
   git push origin --delete Template-Name/v1.0.0
   ```

Note: Deleted templates may still be referenced by old commits/PRs in other projects. The references remain valid for traceability even if the template is removed.

### Dependencies Between Templates

**Include-style dependencies** are loaded together. Declare them in `template.yaml`:

```yaml
dependencies:
  - Code-Style-Guide              # Latest version
  - Security-Checklist@v1.0.0     # Specific version
```

When the loader processes a template:
1. The primary template is downloaded
2. Dependencies are fetched recursively
3. Each gets its own subdirectory under `.agents/`
4. All are recorded in `.loaded-templates.yaml`

Circular dependencies are detected and will cause the loader to abort.

**Sequence dependencies** (e.g., "run Planner before Implementer") are documented in each template's README but not enforced. Handoff happens through git commits.

## Customization

Templates follow the [shadcn](https://ui.shadcn.com/) model: once copied into a project, you own the files. Users can modify `.agents/*/AGENTS.md` freely. Customizations are not tracked upstream.
