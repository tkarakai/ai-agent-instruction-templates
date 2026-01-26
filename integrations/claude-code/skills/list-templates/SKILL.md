---
name: list-templates
description: List available AI agent instruction templates from the repository. Use to discover what templates can be loaded.
---

# List Templates

List available AI agent instruction templates from the repository.

## Usage

```
/list-templates
```

## Execution

Fetch the template list from GitHub:

```bash
curl -fsSL "https://api.github.com/repos/tkarakai/ai-agent-instruction-templates/contents/templates?ref=main" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/' | grep -v '^\.'
```

## Output Format

Display each available template with:
- Template name
- Brief description (from template.yaml if accessible)

Example:
```
Available templates:
- Software-Technical-Planner: Creates technical plans from specifications
```

## Next Steps

After listing templates:
1. Choose an instruction template that fits your role
2. Use `/load-template <name>` to load it
3. Optionally specify a version: `/load-template <name>@v1.0.0`

## Notes

- Instruction templates are versioned independently
- Use `@vX.Y.Z` suffix to load a specific version
- Omit version to get the latest
