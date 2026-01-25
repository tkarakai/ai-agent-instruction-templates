#!/usr/bin/env bash
#
# Template Version Management Tool
#
# Usage:
#   ./version.sh <template-name> [OPTIONS]
#
# Options:
#   --major        Bump major version (X.0.0)
#   --minor        Bump minor version (x.Y.0)
#   --patch        Bump patch version (x.y.Z) [default]
#   --alpha        Add -alpha suffix
#   --beta         Add -beta suffix
#   --rc           Add -rc suffix
#   --dry-run      Show what would happen without making changes
#   -h, --help     Show this help
#
# Examples:
#   ./version.sh Software-Technical-Planner              # Interactive
#   ./version.sh Software-Technical-Planner --patch      # Bump patch
#   ./version.sh Software-Technical-Planner --minor      # Bump minor
#   ./version.sh Software-Technical-Planner --major      # Bump major
#   ./version.sh Software-Technical-Planner --patch --beta  # 1.0.1-beta
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

# Parse semantic version
# Returns: MAJOR MINOR PATCH PRERELEASE
parse_version() {
    local version="$1"

    # Remove 'v' prefix if present
    version="${version#v}"

    # Check for prerelease suffix
    local prerelease=""
    if [[ "$version" == *"-"* ]]; then
        prerelease="${version#*-}"
        version="${version%%-*}"
    fi

    # Parse X.Y.Z
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[3]}"
        PRERELEASE="$prerelease"
        return 0
    else
        return 1
    fi
}

# Get latest version tag for a template
get_latest_version() {
    local template_name="$1"

    # Find all version tags for this template
    local tags
    tags=$(git tag -l "${template_name}/v*" 2>/dev/null | sort -V | tail -1)

    if [ -n "$tags" ]; then
        # Extract version from tag (remove template-name/ prefix)
        echo "${tags#${template_name}/}"
    else
        echo ""
    fi
}

# Get version from template.yaml
get_yaml_version() {
    local template_name="$1"
    local yaml_file="${TEMPLATES_DIR}/${template_name}/template.yaml"

    if [ -f "$yaml_file" ]; then
        grep '^version:' "$yaml_file" | sed 's/version:[[:space:]]*//' | tr -d '"' | tr -d "'"
    else
        echo ""
    fi
}

# Update version in template.yaml
update_yaml_version() {
    local template_name="$1"
    local new_version="$2"
    local yaml_file="${TEMPLATES_DIR}/${template_name}/template.yaml"

    if [ ! -f "$yaml_file" ]; then
        log_error "template.yaml not found: $yaml_file"
        return 1
    fi

    # Use sed to update version line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version:.*/version: ${new_version}/" "$yaml_file"
    else
        sed -i "s/^version:.*/version: ${new_version}/" "$yaml_file"
    fi
}

# Bump version based on type
bump_version() {
    local current="$1"
    local bump_type="$2"
    local prerelease_type="$3"

    # If no current version, start at 0.0.1
    if [ -z "$current" ]; then
        if [ -n "$prerelease_type" ]; then
            echo "0.0.1-${prerelease_type}"
        else
            echo "0.0.1"
        fi
        return
    fi

    # Parse current version
    if ! parse_version "$current"; then
        log_error "Cannot parse version: $current"
        return 1
    fi

    # Calculate new version
    case "$bump_type" in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
    esac

    # Build new version string
    local new_version="${MAJOR}.${MINOR}.${PATCH}"
    if [ -n "$prerelease_type" ]; then
        new_version="${new_version}-${prerelease_type}"
    fi

    echo "$new_version"
}

# Interactive bump type selection
select_bump_type() {
    echo ""
    echo "Select version bump type:"
    echo "  1) patch  (x.y.Z) - Bug fixes, minor changes"
    echo "  2) minor  (x.Y.0) - New features, backwards compatible"
    echo "  3) major  (X.0.0) - Breaking changes"
    echo ""
    read -rp "Choice [1]: " choice

    case "${choice:-1}" in
        1) echo "patch" ;;
        2) echo "minor" ;;
        3) echo "major" ;;
        *) echo "patch" ;;
    esac
}

# Interactive prerelease selection
select_prerelease() {
    echo ""
    echo "Add prerelease suffix?"
    echo "  1) none   - Stable release"
    echo "  2) alpha  - Early testing"
    echo "  3) beta   - Feature complete, testing"
    echo "  4) rc     - Release candidate"
    echo ""
    read -rp "Choice [1]: " choice

    case "${choice:-1}" in
        1) echo "" ;;
        2) echo "alpha" ;;
        3) echo "beta" ;;
        4) echo "rc" ;;
        *) echo "" ;;
    esac
}

# Main
main() {
    local template_name=""
    local bump_type=""
    local prerelease_type=""
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --major) bump_type="major"; shift ;;
            --minor) bump_type="minor"; shift ;;
            --patch) bump_type="patch"; shift ;;
            --alpha) prerelease_type="alpha"; shift ;;
            --beta) prerelease_type="beta"; shift ;;
            --rc) prerelease_type="rc"; shift ;;
            --dry-run) dry_run=true; shift ;;
            -h|--help)
                echo "Usage: $0 <template-name> [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --major        Bump major version (X.0.0)"
                echo "  --minor        Bump minor version (x.Y.0)"
                echo "  --patch        Bump patch version (x.y.Z) [default]"
                echo "  --alpha        Add -alpha suffix"
                echo "  --beta         Add -beta suffix"
                echo "  --rc           Add -rc suffix"
                echo "  --dry-run      Show what would happen without making changes"
                echo "  -h, --help     Show this help"
                echo ""
                echo "Examples:"
                echo "  $0 Software-Technical-Planner              # Interactive"
                echo "  $0 Software-Technical-Planner --patch      # Bump patch"
                echo "  $0 Software-Technical-Planner --minor --beta  # Minor beta release"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                template_name="$1"
                shift
                ;;
        esac
    done

    # Validate template name
    if [ -z "$template_name" ]; then
        log_error "Template name required"
        echo "Usage: $0 <template-name> [OPTIONS]"
        exit 1
    fi

    # Check template exists
    if [ ! -d "${TEMPLATES_DIR}/${template_name}" ]; then
        log_error "Template not found: ${template_name}"
        echo "Available templates:"
        ls -1 "${TEMPLATES_DIR}" 2>/dev/null | grep -v '^\.' | sed 's/^/  /'
        exit 1
    fi

    # Check template.yaml exists
    if [ ! -f "${TEMPLATES_DIR}/${template_name}/template.yaml" ]; then
        log_error "template.yaml not found for: ${template_name}"
        exit 1
    fi

    # Get current versions
    local tag_version yaml_version current_version
    tag_version=$(get_latest_version "$template_name")
    yaml_version=$(get_yaml_version "$template_name")

    log_info "Template: ${template_name}"
    log_info "Latest tag version: ${tag_version:-none}"
    log_info "YAML version: ${yaml_version:-none}"

    # Determine current version (prefer tag, fall back to yaml)
    current_version="${tag_version:-$yaml_version}"

    # Interactive mode if no bump type specified
    if [ -z "$bump_type" ]; then
        bump_type=$(select_bump_type)
    fi

    if [ -z "$prerelease_type" ]; then
        # Only ask for prerelease if not specified on command line
        # Check if any prerelease flag was given
        if [[ ! " $* " =~ " --alpha " ]] && [[ ! " $* " =~ " --beta " ]] && [[ ! " $* " =~ " --rc " ]]; then
            prerelease_type=$(select_prerelease)
        fi
    fi

    # Calculate new version
    local new_version
    new_version=$(bump_version "$current_version" "$bump_type" "$prerelease_type")

    if [ -z "$new_version" ]; then
        log_error "Failed to calculate new version"
        exit 1
    fi

    echo ""
    log_info "Current version: ${current_version:-0.0.0}"
    log_info "New version: ${new_version}"
    log_info "Tag: ${template_name}/v${new_version}"

    if [ "$dry_run" = true ]; then
        echo ""
        log_warn "Dry run - no changes made"
        echo ""
        echo "Would execute:"
        echo "  1. Update template.yaml version to ${new_version}"
        echo "  2. Commit: 'chore(${template_name}): bump version to ${new_version}'"
        echo "  3. Create tag: ${template_name}/v${new_version}"
        echo "  4. Update tag: ${template_name}/latest"
        exit 0
    fi

    # Confirm
    echo ""
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Aborted"
        exit 0
    fi

    # Update template.yaml
    log_info "Updating template.yaml..."
    update_yaml_version "$template_name" "$new_version"

    # Git operations
    log_info "Committing changes..."
    git add "${TEMPLATES_DIR}/${template_name}/template.yaml"
    git commit -m "chore(${template_name}): bump version to ${new_version}"

    log_info "Creating tag: ${template_name}/v${new_version}"
    git tag -a "${template_name}/v${new_version}" -m "Release ${template_name} v${new_version}"

    log_info "Updating latest tag: ${template_name}/latest"
    git tag -f "${template_name}/latest" -m "Latest release of ${template_name}"

    echo ""
    log_success "Version ${new_version} created successfully!"
    echo ""
    echo "To push changes:"
    echo "  git push origin main"
    echo "  git push origin ${template_name}/v${new_version}"
    echo "  git push -f origin ${template_name}/latest"
}

main "$@"
