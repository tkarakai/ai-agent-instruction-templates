---
name: load-template
description: Load an AI agent instruction template into the current project. Use when you need structured instructions for a specific task like technical planning.
---

# Load Template

Load an AI agent instruction template into the current project's `.agents/` directory.

## Usage

Specify the template name, optionally with a version:

```
/load-template Software-Technical-Planner
/load-template Software-Technical-Planner@v1.0.0
```

## What This Does

1. Downloads the template files from GitHub
2. Creates `.agents/<template-name>/AGENTS.md` with agent instructions
3. Records version info in `.agents/.loaded-templates.yaml` for traceability
4. Recursively loads any template dependencies

## Execution

Run the loader script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- $ARGUMENTS
```

## After Loading

1. Read `.agents/<template-name>/AGENTS.md` for the agent instructions
2. Verify required input artifacts exist (documented in the instructions)
3. Follow the instructions to complete the task
4. Use `.agents/.loaded-templates.yaml` for commit/PR metadata

## Notes

- Templates are loaded into `.agents/` (should be gitignored)
- Dependencies declared in `template.yaml` are automatically loaded
- Use `/list-templates` to see available templates
