# Software Technical Planner

Creates a technical plan from a specification document, decomposing it into actionable tasks.

## Purpose

This agent reads a specification or intent document and produces a detailed technical plan. It bridges the gap between "what we want to build" and "how we'll build it."

## When to Use

- Starting a new feature or project
- Before handing off to an implementation agent
- When you need to break down a complex requirement into tasks

## Input Artifacts

| Artifact | Required | Description |
|----------|----------|-------------|
| `SPEC.md` | Yes | The specification or intent document describing what needs to be built |
| `CONSTITUTION.md` | No | Architectural constraints, coding standards, or guidelines the plan must respect |

### SPEC.md Format

The specification should include:

- **Goal**: What are we trying to achieve?
- **Context**: Why is this needed? What problem does it solve?
- **Requirements**: Functional and non-functional requirements
- **Constraints**: Limitations, dependencies, or boundaries
- **Success Criteria**: How do we know when it's done?

### CONSTITUTION.md Format (Optional)

If provided, this document contains:

- Architectural principles to follow
- Technology choices and constraints
- Coding standards and conventions
- Security or compliance requirements

## Output Artifacts

| Artifact | Description |
|----------|-------------|
| `PLAN.md` | The technical plan with decomposed tasks |

### PLAN.md Format

The output plan includes:

1. **Summary**: Brief overview of the approach
2. **Architecture Decisions**: Key technical choices made
3. **Task Breakdown**: Ordered list of implementation tasks
4. **Dependencies**: What each task depends on
5. **Risks**: Potential issues and mitigations
6. **Open Questions**: Items needing clarification

## Sequence Dependencies

These are **not enforced by tooling**, but document the expected workflow:

| Before This Agent | After This Agent |
|-------------------|------------------|
| Human creates SPEC.md | Code-Implementer reads PLAN.md |
| (Optional) Architect creates CONSTITUTION.md | Code-Reviewer validates against PLAN.md |

The handoff happens through git: this agent commits `PLAN.md`, the PR is merged, and the next agent pulls to find it.

## Include Dependencies

This template currently has no include-style dependencies. If it did, they would be listed in `template.yaml` and automatically loaded alongside this template.

## Example Usage

1. Create `SPEC.md` in your project:

```markdown
# Feature: User Authentication

## Goal
Implement user authentication for the web application.

## Requirements
- Users can sign up with email and password
- Users can log in and log out
- Sessions persist across browser refreshes
- Password reset via email

## Constraints
- Must use existing PostgreSQL database
- No third-party auth providers (for now)
- Must pass security audit
```

2. Load the template:

```bash
bash -c "$(curl -fsSL .../load.sh)" -- Software-Technical-Planner
```

3. Configure your AI tool to read `.agents/Software-Technical-Planner/AGENTS.md`

4. Run your AI agent

5. Review the generated `PLAN.md`

6. Create a PR with the plan, then hand off to an implementation agent

## Notes

- The agent will ask clarifying questions if the spec is ambiguous
- Plans are meant to be reviewed and refined by humans before implementation
- Consider the plan a starting point, not a rigid contract
- Template reference information should be included in commits/PRs for traceability
