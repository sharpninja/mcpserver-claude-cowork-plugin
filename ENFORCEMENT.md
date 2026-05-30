# Per-Turn Enforcement Protocol (ClaudeCowork) - v4 Shared Protocol

This plugin implements the McpServer **v4 Shared Enforcement Protocol** for ClaudeCowork agent sessions.
See `packages/mcpserver-agent-core` (`@sharpninja/mcpserver-agent-core`) for the shared core reference.

ClaudeCowork consumes this plugin as an MCP server. The server does not (and cannot)
intercept ClaudeCowork's message loop - ClaudeCowork decides when to call MCP tools. This
document specifies the Per-User-Message contract that the ClaudeCowork **agent** must
follow, plus the helper scripts in `lib/` that automate the bookkeeping.

## Why this is required

`AGENTS-README-FIRST.yaml` in every MCP-enabled workspace mandates:

- **Rule 2**: Post a new session log turn before starting work on each user
  message.
- **Rule 10**: Do not ship code you have not verified compiles.
- **Before Delivering Output**: Session log must be current, decisions
  recorded, code compiles.

These rules are partially enforced by hooks in `hooks/hooks.json` for ClaudeCowork.
Additional compliance is agent-driven.

## The Three Scripts

The plugin ships three bash scripts in `lib/` that ClaudeCowork agents should invoke
per user message:

### Phase 1 - On user message receipt

```bash
echo '{"prompt":"<verbatim user message>"}' | bash ${CLAUDE_PLUGIN_ROOT}/lib/user-prompt-submit.sh
```

What it does:
- Reads the active `sessionId` from `cache/session-state.yaml`
- Builds a fresh `req-<yyyyMMddTHHmmssZ>-prompt-xxxx` requestId
- Invokes `workflow.sessionlog.beginTurn` via `mcpserver-repl`
- Writes `cache/current-turn.yaml` so Phase 3 can verify completion

### Phase 2 - After every code edit

```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":"<absolute path>"}}' \
  | bash ${CLAUDE_PLUGIN_ROOT}/lib/code-verify.sh
```

Runs `dotnet build` (for .NET files) or `tsc --noEmit` (for TypeScript)
against the containing project. Updates `cache/current-turn.yaml` with
`lastBuildStatus` and increments `codeEdits`. Appends a session log action
via `workflow.sessionlog.appendActions`.

### Phase 3 - Before final response

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/stop-gate.sh
```

Returns `decision: block` with reason if:
- Turn is still `in_progress` - agent forgot `workflow.sessionlog.completeTurn`
- `lastBuildStatus: failed` - build is broken

## sourceType

This plugin's agent identity is `ClaudeCowork`. Session logs created by this plugin
use `"sourceType": "ClaudeCowork"` in all MCP session-log API calls.

## See also

- `hooks/hooks.json` - hook configuration for lifecycle events
- `AGENTS-README-FIRST.yaml` in each workspace - authoritative contract
  these scripts implement.
