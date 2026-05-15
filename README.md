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

## Development

```powershell
node .\scripts\validate-plugin.js
bash -n .\lib\repl-invoke.sh
bash -n .\hooks\scripts\session-start.sh
```

If Claude Code is installed locally, this package can also be checked with:

```powershell
claude plugin validate .
```

## Sources

- Claude Cowork plugins install plugins from the marketplace or uploaded plugin package.
- Claude plugins can include skills, MCP connectors, agents, and hooks.
- Plugin manifests use `.claude-plugin/plugin.json`; MCP connector config can be declared with `mcpServers`.

## License

MIT
