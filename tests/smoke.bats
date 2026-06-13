#!/usr/bin/env bats
# smoke.bats - Model C per-repo smoke test.
#
# Proves the migrated hook wrappers wire up to the canonical synced lib
# (lib/hook-lib.sh + lib/plugin-env.sh) and emit valid, schema-shaped output
# when run cold: empty stdin, NO marker reachable, cache isolated to a temp
# dir via PLUGIN_ROOT_OVERRIDE. Host-neutral: locates the session-start and
# user-prompt-submit wrappers in either the claude-family (hooks/scripts/)
# or codex (lib/) position.
#
# These 4 tests replace the per-repo shared-lib bats (superseded by the 307
# core fixtures in McpServer-lifecycle/plugins/core/test-fixtures).

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Isolated, marker-free environment. PLUGIN_ROOT_OVERRIDE anchors CACHE_DIR
    # into the temp dir (resolve-cache-dir precedence #2); HOME + start_dir
    # point at the same empty tree so the upward marker walk finds nothing.
    SMOKE_TMP="$(mktemp -d)"
    export HOME="$SMOKE_TMP"
    export PLUGIN_ROOT_OVERRIDE="$SMOKE_TMP"
    export MCP_WORKSPACE_START_DIR="$SMOKE_TMP"
    export MCPSERVER_WORKSPACE_PATH=""
    export MCP_WORKSPACE_PATH=""
    export MCP_CACHE_DIR_OVERRIDE=""
}

teardown() {
    [ -n "${SMOKE_TMP:-}" ] && rm -rf "$SMOKE_TMP"
}

# Resolve a hook wrapper across hosts: claude-family hooks/scripts/<name>.sh
# (depth ../..) or codex lib/<name>.sh (depth ..).
_wrapper_path() {
    local name="$1"
    if [ -f "$REPO_ROOT/hooks/scripts/${name}.sh" ]; then
        printf '%s' "$REPO_ROOT/hooks/scripts/${name}.sh"
    elif [ -f "$REPO_ROOT/lib/${name}.sh" ]; then
        printf '%s' "$REPO_ROOT/lib/${name}.sh"
    else
        return 1
    fi
}

@test "session-start wrapper exists in a known host position" {
    run _wrapper_path session-start
    [ "$status" -eq 0 ]
    [ -f "$output" ]
}

@test "session-start wrapper runs cold: exit 0 and valid JSON on stdout" {
    local wrapper
    wrapper="$(_wrapper_path session-start)"
    run bash "$wrapper" < /dev/null
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    printf '%s' "$output" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))'
}

@test "user-prompt-submit wrapper exists in a known host position" {
    run _wrapper_path user-prompt-submit
    [ "$status" -eq 0 ]
    [ -f "$output" ]
}

@test "user-prompt-submit wrapper runs cold: exit 0 and valid JSON on stdout" {
    local wrapper
    wrapper="$(_wrapper_path user-prompt-submit)"
    run bash "$wrapper" < /dev/null
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    printf '%s' "$output" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))'
}
