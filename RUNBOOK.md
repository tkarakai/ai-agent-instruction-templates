# Runbook: Using Agent Instruction Templates

This guide walks through the workflow for using agent instruction templates in your projects.

## Important: These Are Recommendations

Everything in this runbook represents **suggested practices**. Adapt the workflow to your needs:

- **Environment isolation**: Use git worktrees, branches, or work directly
- **Commit conventions**: Follow the suggested format or create your own
- **Cleanup**: Delete templates after use or keep them

## Prerequisites

- Git installed and configured
- `curl` available (if using the loader script)
- A git repository where you want to run an agent

## Workflow Overview

1. (Optional) Create an isolated environment for agent work
2. Load the template into your project
3. Configure your AI tool to use the instructions
4. Run the agent
5. Review and commit changes (with template reference)
6. Create a PR
7. (Optional) Clean up the temporary files

## Step 1: Create an Isolated Environment (Recommended)

Isolating agent work from your main working directory helps keep things organized and makes it easy to discard work if something goes wrong.

### Option A: Git Worktree (Recommended)

A git worktree provides a separate working directory on its own branch:

```bash
# From your main repository
cd /path/to/your/project

# Create a new branch and worktree for the agent
git worktree add ../project-agent-work -b agent/feature-name

# Enter the worktree
cd ../project-agent-work
```

**Benefits:**
- Completely isolated from your main working directory
- Easy to discard: just remove the worktree
- Agent can make commits without affecting your work

### Option B: Git Branch

If worktrees feel like overkill, a simple branch works too:

```bash
git checkout -b agent/feature-name
```

### Option C: Work Directly

For simple tasks or when you're confident in the agent's work, you can work directly on your current branch.

## Step 2: Load the Template

Copy the template files into your project.

### Using the Loader Script

```bash
# Interactive mode - browse available templates
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)"

# Load a specific template (latest version)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- Software-Technical-Planner

# Load a specific version
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- Software-Technical-Planner@v1.0.0
```

### Manual Copy

Alternatively, clone the repository and copy files:

```bash
cp -r /path/to/templates/Software-Technical-Planner/files/ .agents/Software-Technical-Planner/
```

### What Gets Created

```
.agents/
├── Software-Technical-Planner/    # Primary template
│   └── AGENTS.md                  # Main instructions
├── Code-Style-Guide/              # Dependency (if any)
│   └── AGENTS.md
└── .loaded-templates.yaml         # Manifest of loaded templates
```

### Gitignore (Recommended)

Add `.agents/` to your `.gitignore`:

```bash
echo ".agents/" >> .gitignore
```

## Step 3: Configure Your AI Tool

Point your AI tool to the primary template's instructions.

### Claude Code

Add to your project's `CLAUDE.md`:

```markdown
Read and follow the instructions in .agents/Software-Technical-Planner/AGENTS.md
```

### Cursor

Add to `.cursorrules`:

```
Follow instructions in .agents/Software-Technical-Planner/AGENTS.md
```

### Other Tools

Tell the agent directly:

> Follow the instructions in .agents/Software-Technical-Planner/AGENTS.md

### Multiple Templates

If dependencies were loaded, the primary template's `AGENTS.md` will reference them. Point your tool to the primary template only.

## Step 4: Verify Input Artifacts

Before running the agent, ensure required input artifacts exist. Check the template's README for what inputs are expected.

Common inputs:
- `SPEC.md` - Specification or intent document
- `PLAN.md` - Technical plan (from a previous agent)
- Existing code the agent will modify

## Step 5: Run the Agent

Start your AI tool and let it work. The agent will:

1. Read the primary template's `AGENTS.md`
2. Reference dependency templates as needed
3. Check for required input artifacts
4. Perform its task
5. Produce output artifacts

**Tips:**
- Let the agent work autonomously when possible
- Review its progress periodically
- The agent should create atomic, well-described commits

## Step 6: Record Template Usage (Recommended)

Including template reference information in commits aids traceability and debugging.

### Reading Template Info

```bash
cat .agents/.loaded-templates.yaml
```

### Commit Message Format (Suggested)

```
feat: implement user authentication

Generated with ai-agent-instruction-templates

Agent: Claude Opus 4 (claude-opus-4-20250514)

Templates used:
- Software-Technical-Planner v1.0.0 (abc123def456)
- Code-Style-Guide v2.1.0 (def456abc789)

Source: https://github.com/tkarakai/ai-agent-instruction-templates
```

Including the agent's LLM name and version helps with:
- Understanding what model produced the work
- Debugging model-specific behaviors
- Tracking improvements as models evolve

## Step 7: Create a Pull Request

### PR Description (Suggested Format)

```markdown
## Summary

[Description of what the agent accomplished]

## Changes

- [List of key changes]

## Agent Information

| Field | Value |
|-------|-------|
| Agent | Claude Opus 4 (claude-opus-4-20250514) |
| Primary Template | Software-Technical-Planner v1.0.0 |
| Dependencies | Code-Style-Guide v2.1.0 |
| Template Commits | abc123, def456 |
| Source | [ai-agent-instruction-templates](https://github.com/tkarakai/ai-agent-instruction-templates) |

## Testing

- [ ] [How to test the changes]
```

### Create PR via CLI

```bash
git push -u origin agent/feature-name
gh pr create --title "feat: feature name" --body-file pr-description.md
```

## Step 8: Review and Merge

Standard review process:

1. Code review by team members
2. CI/CD checks pass
3. Address feedback (agent can help with revisions)
4. Approve and merge

## Step 9: Clean Up (Optional)

### If Using Worktrees

```bash
cd /path/to/your/project
git worktree remove ../project-agent-work
git branch -d agent/feature-name
```

### If Using Branches

```bash
git checkout main
git pull
git branch -d agent/feature-name
```

### Keeping Instructions

If you prefer to keep `.agents/` for reference, that's fine. Since it's gitignored, it won't affect your repository.

## Chaining Agents (Sequence Dependencies)

When multiple agents work in sequence, outputs from one become inputs for the next. This is coordinated through git, not enforced by tooling.

### Example: Planner → Implementer

**Agent 1: Technical Planner**

```bash
# Set up environment
git worktree add ../project-planning -b agent/plan-feature
cd ../project-planning

# Ensure SPEC.md exists

# Load template
bash -c "$(curl -fsSL .../load.sh)" -- Software-Technical-Planner

# Run agent → produces PLAN.md
# Create PR, review, merge
```

**Agent 2: Code Implementer**

```bash
# After planner's PR is merged
git worktree add ../project-implement -b agent/implement-feature
cd ../project-implement

# Pull to get merged PLAN.md
git pull origin main

# Load template
bash -c "$(curl -fsSL .../load.sh)" -- Code-Implementer

# Run agent → reads PLAN.md, produces code
# Create PR, review, merge
```

### Key Points

1. Each agent works in its own environment
2. Outputs are committed and merged before next agent starts
3. Next agent pulls to receive previous outputs
4. Each PR is reviewed independently

## Troubleshooting

### Template not loading

```bash
# Check connectivity
curl -I https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh

# Verbose output
bash -c "$(curl -fsSL https://...)" -- --verbose Software-Technical-Planner
```

### Agent not finding instructions

- Verify `.agents/<template>/AGENTS.md` exists
- Check your AI tool is configured with the correct path
- Ensure you're in the correct directory

### Missing input artifacts

- Check the template's README for required inputs
- Run prerequisite agents first if needed
- Create required files manually if appropriate

### Merge conflicts

If multiple agents work on overlapping areas:

1. Merge the first PR
2. Rebase the second branch: `git rebase main`
3. Resolve conflicts
4. Continue with the second PR

## Quick Reference

```bash
# Create isolated environment
git worktree add ../agent-work -b agent/task-name
cd ../agent-work

# Load template
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tkarakai/ai-agent-instruction-templates/main/load.sh)" -- Template-Name

# Gitignore
echo ".agents/" >> .gitignore

# Configure tool (Claude example)
echo "Read and follow instructions in .agents/Template-Name/AGENTS.md" >> CLAUDE.md

# ... run agent ...

# Create PR
git push -u origin agent/task-name
gh pr create

# Cleanup (after merge)
cd /path/to/main/repo
git worktree remove ../agent-work
git branch -d agent/task-name
```
