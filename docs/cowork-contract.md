# Claude Cowork Contract

This plugin is a Cowork packaging layer over the same McpServer contract used by the Claude Code plugin.

## Trust

1. The target workspace path comes from plugin `userConfig.workspace_path`.
2. The workspace must contain `AGENTS-README-FIRST.yaml`.
3. Marker HMAC verification and `/health?nonce=` verification must pass before any MCP write.
4. When trust fails, the plugin must preserve local failsafe data and avoid write attempts.

## Tool Transport

The packaged MCP connector starts:

```json
{
  "command": "mcpserver-repl",
  "args": ["--agent-stdio"]
}
```

The following environment values are passed to the connector:

- `MCP_WORKSPACE_PATH`
- `MCPSERVER_WORKSPACE_PATH`
- `COWORK_WORKSPACE_PATH`
- `MCP_SESSION_AGENT=ClaudeCowork`
- `PLUGIN_AGENT_NAME=ClaudeCowork`
- `MCP_SESSION_TITLE`

## Failsafe Behavior

The copied shim layer keeps the repaired local safety mechanisms:

- bounded REPL calls
- marker-auth HTTP fallback only after plugin/REPL failure
- response-body preservation for HTTP diagnostics
- pending-import conversion for stranded `.mcpServer` handoffs
- TODO request-wrapper and JSON-as-YAML shaping
- requirements wiki ZIP verification path

Outage data belongs under the workspace-local `.mcpServer` or cache/handoff path and must not be discarded.

## Reload Validation

Before resuming normal MCP writes after install or update, validate:

1. marker trust
2. `workflow.sessionlog.queryHistory`
3. `workflow.todo.query`
4. `workflow.requirements.generateDocument` with `format: wiki`, `docType: all`, and ZIP signature `504b0304`
