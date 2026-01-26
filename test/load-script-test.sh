#!/usr/bin/env bash
#
# Tests for load.sh
#
# Usage:
#   ./test/load-script-test.sh
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOAD_SCRIPT="$REPO_ROOT/load.sh"
TEST_DIR=$(mktemp -d)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors (disabled if not interactive)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((++TESTS_PASSED))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((++TESTS_FAILED))
}

run_test() {
    local name="$1"
    local expected_exit="$2"
    shift 2
    local cmd=("$@")

    ((++TESTS_RUN))
    log_test "$name"

    local exit_code=0
    "${cmd[@]}" > "$TEST_DIR/output.txt" 2>&1 || exit_code=$?

    if [ "$exit_code" -eq "$expected_exit" ]; then
        log_pass "$name"
        return 0
    else
        log_fail "$name (expected exit $expected_exit, got $exit_code)"
        echo "  Output:"
        sed 's/^/    /' "$TEST_DIR/output.txt"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    ((++TESTS_RUN))
    if [ -f "$file" ]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (file not found: $file)"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local test_name="$2"

    ((++TESTS_RUN))
    if [ -d "$dir" ]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (directory not found: $dir)"
        return 1
    fi
}

assert_output_contains() {
    local pattern="$1"
    local test_name="$2"

    ((++TESTS_RUN))
    if grep -qF -- "$pattern" "$TEST_DIR/output.txt"; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (pattern not found: $pattern)"
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((++TESTS_RUN))
    if [ "$expected" == "$actual" ]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (expected: '$expected', got: '$actual')"
        return 1
    fi
}

# =============================================================================
# Test: Help flag
# =============================================================================
test_help_flag() {
    echo ""
    echo "=== Test: Help flag ==="

    run_test "Help flag exits successfully" 0 bash "$LOAD_SCRIPT" --help
    assert_output_contains "Usage:" "Help output contains Usage"
    assert_output_contains "--verbose" "Help output contains --verbose"
    assert_output_contains "--dir" "Help output contains --dir"
}

# =============================================================================
# Test: Normal template loading (no dependencies)
# =============================================================================
test_normal_load() {
    echo ""
    echo "=== Test: Normal template loading ==="

    local target="$TEST_DIR/normal-load"
    rm -rf "$target"

    run_test "Load template successfully" 0 bash "$LOAD_SCRIPT" Software-Technical-Planner --dir "$target"
    assert_dir_exists "$target/Software-Technical-Planner" "Template directory created"
    assert_file_exists "$target/Software-Technical-Planner/AGENTS.md" "AGENTS.md downloaded"
    assert_file_exists "$target/.loaded-templates.yaml" "Manifest file created"
}

# =============================================================================
# Test: Non-existent template
# =============================================================================
test_nonexistent_template() {
    echo ""
    echo "=== Test: Non-existent template ==="

    local target="$TEST_DIR/nonexistent"
    rm -rf "$target"

    run_test "Non-existent template fails" 1 bash "$LOAD_SCRIPT" This-Template-Does-Not-Exist-12345 --dir "$target"
}

# =============================================================================
# Test: Custom directory
# =============================================================================
test_custom_directory() {
    echo ""
    echo "=== Test: Custom directory ==="

    local target="$TEST_DIR/my-custom-agents-dir"
    rm -rf "$target"

    run_test "Custom directory works" 0 bash "$LOAD_SCRIPT" Software-Technical-Planner --dir "$target"
    assert_dir_exists "$target" "Custom directory created"
    assert_file_exists "$target/Software-Technical-Planner/AGENTS.md" "Template in custom directory"
}

# =============================================================================
# Test: Manifest file format
# =============================================================================
test_manifest_format() {
    echo ""
    echo "=== Test: Manifest file format ==="

    local target="$TEST_DIR/manifest-test"
    rm -rf "$target"

    bash "$LOAD_SCRIPT" Software-Technical-Planner --dir "$target" > /dev/null 2>&1

    local manifest="$target/.loaded-templates.yaml"

    ((++TESTS_RUN))
    if grep -q "^primary: Software-Technical-Planner" "$manifest"; then
        log_pass "Manifest contains primary template"
    else
        log_fail "Manifest missing primary template"
    fi

    ((++TESTS_RUN))
    if grep -q "^loaded_at:" "$manifest"; then
        log_pass "Manifest contains loaded_at timestamp"
    else
        log_fail "Manifest missing loaded_at timestamp"
    fi

    ((++TESTS_RUN))
    if grep -q "version:" "$manifest"; then
        log_pass "Manifest contains version"
    else
        log_fail "Manifest missing version"
    fi

    ((++TESTS_RUN))
    if grep -q "commit:" "$manifest"; then
        log_pass "Manifest contains commit hash"
    else
        log_fail "Manifest missing commit hash"
    fi
}

# =============================================================================
# Test: Dependency parsing - empty array
# =============================================================================
test_dependency_parsing_empty() {
    echo ""
    echo "=== Test: Dependency parsing - empty array ==="

    local result
    result=$(echo -e "name: Test\nversion: 1.0.0\ndependencies: []\nskills: []" | \
        sed -n '/^dependencies:/,/^[a-z]/p' | \
        grep '^\s*-' | \
        sed 's/^[[:space:]]*-[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'" || true)

    assert_equals "" "$result" "Empty dependencies array returns empty string"
}

# =============================================================================
# Test: Dependency parsing - multi-line format
# =============================================================================
test_dependency_parsing_multiline() {
    echo ""
    echo "=== Test: Dependency parsing - multi-line format ==="

    local result
    result=$(echo -e "name: Test\nversion: 1.0.0\ndependencies:\n  - Template-A\n  - Template-B@v1.0.0\nskills: []" | \
        sed -n '/^dependencies:/,/^[a-z]/p' | \
        grep '^\s*-' | \
        sed 's/^[[:space:]]*-[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'")

    local expected="Template-A
Template-B@v1.0.0"

    assert_equals "$expected" "$result" "Multi-line dependencies parsed correctly"
}

# =============================================================================
# Test: Dependency parsing - quoted values
# =============================================================================
test_dependency_parsing_quoted() {
    echo ""
    echo "=== Test: Dependency parsing - quoted values ==="

    local result
    result=$(echo -e "name: Test\nversion: 1.0.0\ndependencies:\n  - \"Template-A\"\n  - 'Template-B@v1.0.0'\nskills: []" | \
        sed -n '/^dependencies:/,/^[a-z]/p' | \
        grep '^\s*-' | \
        sed 's/^[[:space:]]*-[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'")

    local expected="Template-A
Template-B@v1.0.0"

    assert_equals "$expected" "$result" "Quoted dependencies parsed correctly"
}

# =============================================================================
# Test: Dependency parsing - preserves template name with dashes
# =============================================================================
test_dependency_parsing_preserves_dashes() {
    echo ""
    echo "=== Test: Dependency parsing - preserves dashes in names ==="

    local result
    result=$(echo -e "name: Test\nversion: 1.0.0\ndependencies:\n  - My-Template-With-Many-Dashes\nskills: []" | \
        sed -n '/^dependencies:/,/^[a-z]/p' | \
        grep '^\s*-' | \
        sed 's/^[[:space:]]*-[[:space:]]*//' | \
        tr -d '"' | \
        tr -d "'")

    assert_equals "My-Template-With-Many-Dashes" "$result" "Template name with dashes preserved"
}

# =============================================================================
# Test: Script handles empty arrays without error (set -u compatibility)
# =============================================================================
test_empty_array_handling() {
    echo ""
    echo "=== Test: Empty array handling (bash -u compatibility) ==="

    # This test verifies the script doesn't fail on first run when arrays are empty
    local target="$TEST_DIR/empty-array-test"
    rm -rf "$target"

    # Run with set -u explicitly to ensure compatibility
    run_test "Script handles empty arrays" 0 bash -u "$LOAD_SCRIPT" Software-Technical-Planner --dir "$target"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "========================================"
    echo "load.sh Test Suite"
    echo "========================================"
    echo "Test directory: $TEST_DIR"
    echo "Script under test: $LOAD_SCRIPT"

    # Run all tests
    test_help_flag
    test_normal_load
    test_nonexistent_template
    test_custom_directory
    test_manifest_format
    test_dependency_parsing_empty
    test_dependency_parsing_multiline
    test_dependency_parsing_quoted
    test_dependency_parsing_preserves_dashes
    test_empty_array_handling

    # Summary
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "${RED}FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        exit 0
    fi
}

main "$@"
