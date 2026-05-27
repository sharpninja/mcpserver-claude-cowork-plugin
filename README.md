# McpServer Claude Cowork Plugin

Connect [Claude Cowork](https://claude.ai) to [McpServer](https://github.com/sharpninja/McpServer) for workspace-scoped TODO management, session logging, requirements tracking, and GraphRAG knowledge graph operations.

This is the Cowork-oriented sibling of `mcpserver-claude-code-plugin`. It keeps the same marker-trusted MCP contract and repaired fallback behavior, but it does not assume a Claude Code project launch environment.

## Features

- Installs as a Claude plugin package with `.claude-plugin/plugin.json`.
- Prompts for a `workspace_path` pointing at a workspace that contains `AGENTS-README-FIRST.yaml`.
- Bundles an `mcpserver` stdio connector using `mcpserver-repl --agent-stdio`.
- Keeps the repaired local failsafe behavior from the Claude Code plugin: bounded REPL calls, HTTP fallback diagnostics, pending import transformation, TODO shaping, and session-log recovery support.
- Provides four skills: TODO, Session Log, Requirements, and GraphRAG.
- Provides hooks for environments that enable Cowork plugin hooks; hooks degrade to local handoff/cache files instead of dropping data when McpServer is unavailable.

## Prerequisites

- McpServer running with the target workspace registered.
- The target workspace must contain a current `AGENTS-README-FIRST.yaml`.
- `mcpserver-repl` must be available on PATH for the local Cowork runtime.
- If using a remote/custom Cowork connector path instead of local stdio, the server must be reachable from Anthropic's network as described in the Cowork plugin docs.

## Install In Cowork

1. Package this directory:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\package-plugin.ps1
```

2. In Claude Desktop, open Cowork, then `Customize` -> `Plugins`.
3. Upload `dist\mcpserver-cowork-plugin.zip`.
4. Set `workspace_path` to the absolute local workspace path, for example `F:\GitHub\McpServer`.
5. Reload/validate before writing MCP data:
   - marker trust succeeds
   - `workflow.sessionlog.queryHistory` succeeds
   - `workflow.todo.query` succeeds
   - `workflow.requirements.generateDocument` with `format: wiki`, `docType: all` returns ZIP bytes

## Install From A Marketplace Repository

Cowork can add a GitHub repository as a plugin marketplace. This workspace includes `.claude-plugin/marketplace.json` with a single `mcpserver-cowork` entry pointing at the repository root. If this repository is published, add it from the Cowork plugin UI and install `mcpserver-cowork` from that marketplace.

## Cowork Contract

The Cowork variant intentionally separates two paths:

- The MCP connector path exposes `mcpserver-repl --agent-stdio` to Cowork as the tool transport.
- The hook/skill helper path uses the repaired shell shims for local marker bootstrap, session-log turn tracking, TODO shaping, requirements ZIP fallback, and outage handoff files.

The plugin must not bypass `AGENTS-README-FIRST.yaml` trust. If marker verification or health nonce verification fails, MCP writes must stop and local handoff/failsafe files must be retained for later import.

## Local stdio MCP - how it works

Cowork loads the MCP server entry from `.mcp.json` at plugin install time:

```json
"command": "${CLAUDE_PLUGIN_ROOT}/bin/mcpserver-stdio.cmd",
"args": []
```

`${CLAUDE_PLUGIN_ROOT}` is expanded by Cowork to the plugin's installed root.
The wrapper calls `mcpserver-repl --agent-stdio` and fails with a clear message
if the tool is not on PATH.

**macOS/Linux:** Change `command` to `${CLAUDE_PLUGIN_ROOT}/bin/mcpserver-stdio.sh`
in `.mcp.json` before packaging, then rebuild the zip.

### Verify that local MCP is enabled

Cowork Desktop supports local stdio MCP servers by default. Admin-managed
Cowork instances may disable local MCP via policy. To check:

1. In Cowork go to **Customize > Connectors** (or **Plugins > mcpserver-cowork**).
2. If the connector shows "Local MCP disabled by policy" or does not list the
   `mcpserver` connector, contact your Cowork administrator.

### Diagnose wrapper startup outside Cowork

Run the wrapper directly to see any startup error before Cowork gets involved:

```powershell
# Windows - should block waiting for MCP JSON-RPC input (no immediate output = good)
$env:MCP_WORKSPACE_PATH = "F:\path\to\your\workspace"
$env:MCP_SESSION_AGENT  = "ClaudeCowork"
.\bin\mcpserver-stdio.cmd
# Ctrl-C to exit

# If mcpserver-repl is missing, the wrapper exits 1 and prints:
#   [mcpserver-cowork] ERROR: mcpserver-repl not found on PATH.
```

```bash
# macOS/Linux
MCP_WORKSPACE_PATH=/path/to/workspace MCP_SESSION_AGENT=ClaudeCowork \
  bash bin/mcpserver-stdio.sh
# Ctrl-C to exit
```

### Install mcpserver-repl

```powershell
# Requires .NET SDK 8+
dotnet tool install --global McpServer.Repl

# Or use the bundled helper
powershell -ExecutionPolicy Bypass -File lib\ensure-repl.ps1   # Windows
bash lib/ensure-repl.sh                                         # Unix
```

After install, restart the plugin or re-open the Cowork workspace.

### Known limitations

| Limitation | Detail |
|------------|--------|
| Admin policy | Local MCP must be permitted in Cowork Desktop settings. Cloud/enterprise Cowork may disable local stdio connectors. |
| PATH dependency | The wrapper relies on `mcpserver-repl` being on the system PATH (installed as a .NET global tool). If PATH is modified after Cowork starts, restart Cowork. |
| Windows primary | `.mcp.json` references `mcpserver-stdio.cmd`. macOS/Linux users must change `command` to `mcpserver-stdio.sh` and repackage. |
| Cloud connectors | A Cowork custom cloud connector cannot reach a local stdio process. This plugin is a local-only integration; no HTTPS connector path is included. |

## Development

```powershell
node .\scripts\validate-plugin.js
bash -n .\lib\repl-invoke.sh
bash -n .\hooks\scripts\session-start.sh
```

If Claude Code is installed locally, this package can also be checked with:

```powershell
claude plugin validate .
claude plugin validate .\.claude-plugin\plugin.json   # also validates hooks.json
```

## Sources

- Claude Cowork plugins install plugins from the marketplace or uploaded plugin package.
- Claude plugins can include skills, MCP connectors, agents, and hooks.
- Plugin manifests use `.claude-plugin/plugin.json`; MCP connector config can be declared with `mcpServers`.

## License

MIT
