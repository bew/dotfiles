# Shell Script Writing & Testing Guide

This guide documents the shell scripting style and testing practices used in this repository.

## Important Note for AI Agents

**CRITICAL**: When you detect file changes (via git status, file modifications, etc.), it means the user made manual edits.
**ALWAYS respect user edits** and do not revert them unless they directly conflict with the current task requirements.

**If you are unsure** whether user edits should be kept or if they conflict with the task, **ASK THE USER** before making changes.

## Shell Script Writing Style

### General Principles

1. **Always use `#!/usr/bin/env bash`** as the shebang
2. **Write for maintainability** - Assume scripts will be maintained and extended in the long run. Prioritize clarity and good structure over brevity
3. **Use functions** - Split scripts into logical functions for better organization and testability
4. **Use descriptive function names** - Functions should clearly indicate what they do, with a verb
5. **Use the `function` keyword** - Prefer `function name() { ... }` over `name() { ... }`
6. **Local variables** - Always use `local` for function-scoped variables
7. **Assign function parameters to local variables** - Never use plain `$1`, `$2`, etc. directly in function bodies
8. **Quote variables** - Always use `"$variable"` to handle spaces correctly
9. **Use `[[ ... ]]` over `[ ... ]` for conditions** - Modern bash conditional expressions are safer
10. **No trailing whitespace** - Lines should not contain only whitespace; trim whitespace-only lines

### Code Organization

Scripts should follow this structure:

```bash
#!/usr/bin/env bash

# Script description, when to use
# Brief explanation of what it does & how

set -euo pipefail # Safe, strict script execution

function echo_err() {
  echo >&2 "$*"
}

function usage_and_exit() {
    local status="$1"
    cat >&2 <<'EOF'
Usage: script ARGS...

Description of the script.

EXAMPLES:
  script example1    - What this does
  script example2    - What this does
EOF
    exit "$status"
}

function helper_function() {
    local arg1="$1"
    # ...
}

function main() {
    if [[ $# -eq 0 ]]; then
        usage_and_exit 1
    fi

    # Main logic
}

main "$@"
```

### Common Function Names

Use these standard function names across scripts for consistency:

**Core functions:**
- `main` - Entry point, called with `main "$@"` at the end of script
- `usage_and_exit` - Display usage/help and exit with status code
- `echo_err` - Output to stderr (helper for error messages)

**Domain-specific helpers:**
- `get_*` - Functions that compute/retrieve a value (e.g. `get_color_flag`, `get_charset`)
- `check_*` - Validation functions (e.g. `check_is_number`)
- `parse_*` - Parsing functions (e.g. `parse_args`)

**Test helpers (in `.bats` files):**
- `setup` - Runs before each test
- `setup_*` - Setup helper functions (e.g. `setup_test_random_input_file`)
- `run_*` - Test execution helpers, when wrapping is necessary (e.g. `run_script`, `run_script_failed`)
- `assert_*` - Assertion helpers (e.g. `assert_length`, `assert_has_chars`)

### Specific Style Rules

**Code Section Separators**:
Use consistent separators to organize code into logical sections.
NOTE: This is not needed at all for simple scripts with less that 5-7 functions.

```bash
# Some other code

# ------------------------------------------------------------------------------
# Section Name

# Code for this section...
```

- In test files (`.bats`): Use separators to group tests by general topics
- Keep section names concise and descriptive

**Global Variables**:
- Use SCREAMING_SNAKE_CASE for all global variables
- Super globals (constants used throughout the script) should be defined at the top of the file, immediately after the script header comment and `set` command
- Super globals should be documented either inline or with a comment above
- Mutable globals (used for storing parsed arguments) should be declared in `main()` or `parse_args()` functions

```bash
#!/usr/bin/env bash

set -euo pipefail

# Script directory and path to the script being tested
SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/script-name"

function main() {
    # Mutable globals for argument parsing
    LENGTH=32
    USE_ONLY_MODE=false
    # ...
}
```

**Error Messages**:
Always provide clear, actionable error messages.

```bash
# Good - explains what's wrong and how to fix it
echo_err "Error: --len requires an argument"
echo_err "Example: gen-random-string --len 16"

# Good - provides context and guidance
echo_err "Error: Unknown charset rule: $rule"
echo_err "Run with --help to see available rules"

# Bad - too vague, not actionable
echo_err "Error: Invalid input"
```

**Function Parameters**:
Always assign parameters to local variables at the start of functions.
Never use `$1`, `$2`, .. directly in the function body (except for tiny one-line functions).

```bash
# Good
function process_file() {
    local file_path="$1"
    local mode="$2"

    if [[ -f "$file_path" ]]; then
        echo "Processing $file_path in $mode mode"
    fi
}

# Bad - using $1, $2 directly
function process_file() {
    if [[ -f "$1" ]]; then
        echo "Processing $1 in $2 mode"
    fi
}
```

**Avoid Multiline Conditions**:
When conditions involve computations or function calls, extract the computation to a local variable first, then use a straightforward condition.

```bash
# Good - computation in variable, then simple condition
function validate_input() {
    local input="$1"
    local is_valid
    is_valid=$(check_format "$input" && check_length "$input")

    if [[ -n "$is_valid" ]]; then
        process_input "$input"
    fi
}

# Good - for simple checks with functions
function main() {
    if [[ $# -gt 0 ]] && check_is_number "$1"; then
        length="$1"
        shift
    fi
}

# Bad - multiline condition with embedded logic
function validate_input() {
    local input="$1"

    if [[ -n "$(check_format "$input" && \
              check_length "$input")" ]]; then
        process_input "$input"
    fi
}
```

**Capturing Command Output while checking execution success**:
When capturing command output in a variable, handle potential failures properly.
If you need to pass options to `set` temporarily, disable them before the command and re-enable after.

```bash
# When a command in a pipeline might fail (e.g., head causing SIGPIPE)
# Always explain WHY we disable something
local output
set +o pipefail
output=$(some_command | head -n1)
set -o pipefail

# When you need to capture output from a command that might fail
# This is needed as a separate line to avoid swallowing errors (`local ...` always succeeds)
local charset
charset=$(get_charset "$rule")  # Will fail with 'set -e' if function exits with non-zero

# To check command success when capturing output, use separate check:
local result
if ! result=$(potentially_failing_command 2>&1); then
    echo_err "Error: Getting stuff failed: $result"
    exit 1
fi
```

### Example well-written scripts

See these scripts in `bin/` for complete examples (with BATS tests):
- `envrg` - Environment variable grepper with smart-case, color handling, on-demand stdin piping
- `gen-random-string` - Flexible random string generator with charset rules


## Testing with Bats

### Documentation

**IMPORTANT**: Make sure to read the official documentation before implementing BATS tests!

https://bats-core.readthedocs.io/en/stable/writing-tests.html

### Test File Structure

Test files should be named `the-script-being-tested.bats` (same name as the script with `.bats` extension).

```bash
# Test suite for `the-script-being-tested` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

# Require BATS 1.5.0+ for flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/the-script-being-tested"

function setup() {
    # Setup shared across ALL tests
    # Do NOT add test-specific preparation here
}

@test "topic: description of test" {
    # Each test sets its own specific environment
    # Run the script
    run -0 "$SCRIPT_PATH" args...
    # Asserts
    [[ "$output" == "hello" ]]
}
```

### Key Testing Principles

#### 1. Setup Function is for ALL Tests

The `setup()` function should only contain preparation shared by ALL tests. **DO NOT** add test-specific setup (environment variables, files, etc.) in `setup()`.

```bash
function setup() {
    # Shared setup for all tests
    # Setup clean environment (init common env vars, create common files in $BATS_TEST_TMPDIR, etc.)
}

@test "the-topic: test-case summary" {
    # Test-specific preparation here
    export TEST_VAR="value"
    # ... test code
}
```

#### 2. Custom assert functions

Custom assert functions can be written to refactor tests checks, they must be prefixed with `assert_`.

Example:
```bash
function assert_length() {
    local output="$1"
    local expected="$2"
    [[ "${#output}" -eq "$expected" ]]
}
```

#### 3. Test Naming Convention

Use the format `"topic: summary"` for test names.

Common test topics:
- `helpers`, for eventual tests on the eventual `assert_` functions (should be the first tests)
- `cli`, for tests on command-line argument and general flags handling
- `defaults`, for tests on default behavior without flags
- `error`, for tests on error handling and validation
- `usage`, for tests on help and usage messages
- `edge`, for tests on edge cases and unusual inputs
- `integration`, for tests on integrating with other tools / piping / chaining

Examples:
```bash
@test "defaults: generates 32-char string" { ... }
@test "cli: accepts length as positional argument" { ... }
@test "error: rejects invalid length" { ... }
@test "usage: -h displays usage message" { ... }
```

#### 4. Use `run` with Exit Code and --separate-stderr

When testing stderr output, use the `--separate-stderr` flag (refer to bats docs):

```bash
run -0 --separate-stderr "$SCRIPT_PATH" args
[[ "$output" == "stdout content" ]]
[[ "$stderr" == "stderr content" ]]
```

#### 5. Testing with Pipes

For piping, refer to the bats documentation on `bats_pipe`, using `\|` (escaped pipe).

### Test Organization

Group tests by topic using the naming convention from section 3 above.

### Running Tests

```bash
bats script.bats              # Run all tests
bats script.bats -f "topic"   # Run tests matching pattern
```

## Common Pitfalls

1. **Don't add test-specific setup to `setup()` function** - Only shared setup belongs there
2. **Don't use plain `$1`, `$2` in function bodies** - Always assign to local variables first
3. **Don't forget test naming convention** - Use `"topic: description"` format
4. **Don't skip reading the docs** - Refer to bats documentation for features like `bats_pipe`, `--separate-stderr`, etc.

## References

- BATS Core Documentation: https://bats-core.readthedocs.io/

## Example well-written scripts with tests

- `bin/envrg` & `bin/envrg.bats` - Environment variable grepper ,with comprehensive tests
- `bin/gen-random-string` & `bin/gen-random-string.bats` - Random string generator, with test helpers
