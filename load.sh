#!/usr/bin/env bash
#
# AI Agent Instructions Template Loader
#
# Usage:
#   Interactive mode (select from list):
#     bash -c "$(curl -fsSL URL/load.sh)"
#
#   Load specific template:
#     bash -c "$(curl -fsSL URL/load.sh)" -- Template-Name
#
#   Load specific version:
#     bash -c "$(curl -fsSL URL/load.sh)" -- Template-Name@v1.0.0
#
#   Load to custom directory:
#     bash -c "$(curl -fsSL URL/load.sh)" -- Template-Name --dir ./custom-dir
#

set -euo pipefail

# Configuration
REPO_OWNER="tkarakai"
REPO_NAME="ai-agent-instruction-templates"
DEFAULT_BRANCH="main"
DEFAULT_TARGET_DIR=".agents"

# Track loaded templates (to skip duplicates) and loading stack (to detect cycles)
declare -a LOADED_TEMPLATES=()
declare -a LOADING_STACK=()

# Colors (disabled if not interactive)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Parse template name and version
# Input: "Template-Name" or "Template-Name@v1.0.0"
# Sets: TEMPLATE_NAME, TEMPLATE_VERSION
parse_template_spec() {
    local spec="$1"
    if [[ "$spec" == *"@"* ]]; then
        TEMPLATE_NAME="${spec%@*}"
        TEMPLATE_VERSION="${spec#*@}"
    else
        TEMPLATE_NAME="$spec"
        TEMPLATE_VERSION=""
    fi
}

# Fetch list of available templates from GitHub
fetch_template_list() {
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/templates?ref=${DEFAULT_BRANCH}"

    curl -fsSL "$api_url" 2>/dev/null | \
        grep '"name"' | \
        sed 's/.*"name": "\([^"]*\)".*/\1/' | \
        grep -v '^\.' || {
            log_error "Failed to fetch template list from GitHub"
            exit 1
        }
}

# Interactive template selection
select_template() {
    if [ ! -t 0 ]; then
        log_error "Interactive mode requires a terminal. Please specify a template name."
        echo "Usage: bash -c \"\$(curl -fsSL URL)\" -- Template-Name"
        exit 1
    fi

    log_info "Fetching available templates..."

    local templates
    templates=$(fetch_template_list)

    if [ -z "$templates" ]; then
        log_error "No templates found"
        exit 1
    fi

    echo ""
    echo "Available templates:"
    echo "-------------------"

    local i=1
    local template_array=()
    while IFS= read -r template; do
        template_array+=("$template")
        echo "  $i) $template"
        ((i++))
    done <<< "$templates"

    echo ""
    read -rp "Select a template (1-$((i-1))): " selection

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -ge "$i" ]; then
        log_error "Invalid selection"
        exit 1
    fi

    TEMPLATE_NAME="${template_array[$((selection-1))]}"
    TEMPLATE_VERSION=""

    echo ""
    log_info "Selected: $TEMPLATE_NAME"
}

# Get the git ref to use (tag or branch)
get_git_ref() {
    local template_name="$1"
    local requested_version="$2"

    if [ -n "$requested_version" ]; then
        # Use the specified version tag
        echo "${template_name}/${requested_version}"
    else
        # Try to find the latest tag for this template
        local tags_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/git/refs/tags/${template_name}/"
        local latest_tag
        latest_tag=$(curl -fsSL "$tags_url" 2>/dev/null | \
            grep '"ref"' | \
            sed 's/.*"ref": "refs\/tags\/\([^"]*\)".*/\1/' | \
            grep "^${template_name}/v" | \
            sort -V | \
            tail -1)

        if [ -n "$latest_tag" ]; then
            echo "$latest_tag"
        else
            # No tags found, use default branch
            echo "$DEFAULT_BRANCH"
        fi
    fi
}

# Get the commit hash for traceability
get_commit_hash() {
    local ref="$1"
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits/${ref}"

    curl -fsSL "$api_url" 2>/dev/null | \
        grep '"sha"' | \
        head -1 | \
        sed 's/.*"sha": "\([^"]*\)".*/\1/' | \
        cut -c1-12
}

# Read version from template.yaml
get_template_version_from_yaml() {
    local ref="$1"
    local template_name="$2"
    local yaml_url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${ref}/templates/${template_name}/template.yaml"

    curl -fsSL "$yaml_url" 2>/dev/null | \
        grep '^version:' | \
        sed 's/version:[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'"
}

# Read dependencies from template.yaml
get_template_dependencies() {
    local ref="$1"
    local template_name="$2"
    local yaml_url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${ref}/templates/${template_name}/template.yaml"

    curl -fsSL "$yaml_url" 2>/dev/null | \
        sed -n '/^dependencies:/,/^[a-z]/p' | \
        grep '^\s*-' | \
        sed 's/^[[:space:]]*-[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'" || true
}

# Check if template is already loaded (skip gracefully)
is_already_loaded() {
    local template_name="$1"
    if [ ${#LOADED_TEMPLATES[@]} -eq 0 ]; then
        return 1
    fi
    for loaded in "${LOADED_TEMPLATES[@]}"; do
        if [ "$loaded" == "$template_name" ]; then
            return 0
        fi
    done
    return 1
}

# Check for circular dependency (only in current recursion stack)
check_circular_dependency() {
    local template_name="$1"
    if [ ${#LOADING_STACK[@]} -eq 0 ]; then
        return 0
    fi
    for loading in "${LOADING_STACK[@]}"; do
        if [ "$loading" == "$template_name" ]; then
            log_error "Circular dependency detected: $template_name"
            exit 1
        fi
    done
}

# Download template files to its own subdirectory
download_template() {
    local ref="$1"
    local template_name="$2"
    local target_dir="$3"

    local template_target="${target_dir}/${template_name}"
    local files_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/templates/${template_name}/files?ref=${ref}"

    # Create template-specific directory
    mkdir -p "$template_target"

    # Get list of files
    local files
    files=$(curl -fsSL "$files_url" 2>/dev/null | grep '"download_url"' | sed 's/.*"download_url": "\([^"]*\)".*/\1/')

    if [ -z "$files" ]; then
        log_error "No files found in template '${template_name}/files/'"
        exit 1
    fi

    # Download each file
    while IFS= read -r file_url; do
        if [ -n "$file_url" ] && [ "$file_url" != "null" ]; then
            local filename
            filename=$(basename "$file_url")
            log_info "  Downloading ${template_name}/${filename}..."
            curl -fsSL "$file_url" -o "${template_target}/${filename}"
        fi
    done <<< "$files"
}

# Load a single template (and its dependencies recursively)
# Arguments: template_spec, target_dir, is_primary, parent_template
load_template() {
    local template_spec="$1"
    local target_dir="$2"
    local is_primary="$3"
    local parent_template="${4:-}"

    # Parse template spec
    local template_name template_version
    if [[ "$template_spec" == *"@"* ]]; then
        template_name="${template_spec%@*}"
        template_version="${template_spec#*@}"
    else
        template_name="$template_spec"
        template_version=""
    fi

    # Skip if already loaded (handles diamond dependencies gracefully)
    if is_already_loaded "$template_name"; then
        log_info "Template already loaded: ${template_name} (skipping)"
        return 0
    fi

    # Check for circular dependency in current loading chain
    check_circular_dependency "$template_name"
    LOADING_STACK+=("$template_name")

    log_info "Loading template: ${template_name}"

    # Determine git ref
    local git_ref
    git_ref=$(get_git_ref "$template_name" "$template_version")
    log_info "  Using ref: ${git_ref}"

    # Get commit hash
    local commit_hash
    commit_hash=$(get_commit_hash "$git_ref")

    # Get version from template.yaml
    local yaml_version
    yaml_version=$(get_template_version_from_yaml "$git_ref" "$template_name")

    # Download template files
    download_template "$git_ref" "$template_name" "$target_dir"

    # Record in manifest
    local manifest_file="${target_dir}/.loaded-templates.yaml"

    if [ "$is_primary" == "true" ]; then
        # Create new manifest with primary template
        cat > "$manifest_file" << EOF
primary: ${template_name}
loaded_at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
templates:
  - name: ${template_name}
    version: ${yaml_version}
    commit: ${commit_hash}
    source: https://github.com/${REPO_OWNER}/${REPO_NAME}
EOF
    else
        # Append dependency to existing manifest
        cat >> "$manifest_file" << EOF
  - name: ${template_name}
    version: ${yaml_version}
    commit: ${commit_hash}
    source: https://github.com/${REPO_OWNER}/${REPO_NAME}
    dependency_of: ${parent_template}
EOF
    fi

    # Load dependencies
    local deps
    deps=$(get_template_dependencies "$git_ref" "$template_name")

    if [ -n "$deps" ]; then
        while IFS= read -r dep; do
            if [ -n "$dep" ]; then
                log_info "Loading dependency: $dep"
                load_template "$dep" "$target_dir" "false" "$template_name"
            fi
        done <<< "$deps"
    fi

    # Mark as loaded and remove from loading stack
    LOADED_TEMPLATES+=("$template_name")
    unset 'LOADING_STACK[${#LOADING_STACK[@]}-1]'
}

# Main
main() {
    local template_spec=""
    local target_dir="$DEFAULT_TARGET_DIR"
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                set -x
                shift
                ;;
            --dir|-d)
                target_dir="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS] [TEMPLATE[@VERSION]]"
                echo ""
                echo "Options:"
                echo "  -v, --verbose      Enable verbose output"
                echo "  -d, --dir DIR      Target directory (default: .agents)"
                echo "  -h, --help         Show this help"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Interactive mode"
                echo "  $0 Software-Technical-Planner         # Load latest version"
                echo "  $0 Software-Technical-Planner@v1.0.0  # Load specific version"
                echo "  $0 Template-Name --dir ./my-dir       # Custom target directory"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                template_spec="$1"
                shift
                ;;
        esac
    done

    # Interactive mode if no template specified
    if [ -z "$template_spec" ]; then
        select_template
        template_spec="$TEMPLATE_NAME"
    fi

    log_info "Target directory: ${target_dir}"

    # Create target directory
    mkdir -p "$target_dir"

    # Load the primary template (and its dependencies)
    load_template "$template_spec" "$target_dir" "true"

    # Parse template name for final message
    local primary_name
    if [[ "$template_spec" == *"@"* ]]; then
        primary_name="${template_spec%@*}"
    else
        primary_name="$template_spec"
    fi

    echo ""
    log_success "Template loaded successfully!"
    echo ""
    echo "Files installed to: ${target_dir}/"
    echo ""
    echo "Primary template: ${primary_name}"
    echo "Instructions at:  ${target_dir}/${primary_name}/AGENTS.md"
    echo ""
    echo "Next steps:"
    echo "  1. Add '${target_dir}/' to your .gitignore (if not already)"
    echo "  2. Configure your AI tool to read ${target_dir}/${primary_name}/AGENTS.md"
    echo "  3. Run your agent"
    echo ""
    echo "Template manifest: ${target_dir}/.loaded-templates.yaml"
}

main "$@"
