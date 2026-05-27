#!/usr/bin/env bash
# mcpserver-stdio.sh -- Unix wrapper: launch mcpserver-repl in stdio MCP mode.
#
# Called by the plugin .mcp.json "command" entry on macOS/Linux. Cowork passes
# workspace env vars (MCP_WORKSPACE_PATH, MCP_SESSION_AGENT, etc.) to this
# process.
#
# On Windows use bin/mcpserver-stdio.cmd and set "command" in .mcp.json to:
#   "${CLAUDE_PLUGIN_ROOT}/bin/mcpserver-stdio.cmd"
# On macOS/Linux change "command" in .mcp.json to:
#   "${CLAUDE_PLUGIN_ROOT}/bin/mcpserver-stdio.sh"
#
# Prerequisite: mcpserver-repl must be installed as a .NET global tool.
#   dotnet tool install --global McpServer.Repl
#
# To install automatically via the bundled helper:
#   bash "$(dirname "$0")/../lib/ensure-repl.sh"
#
# Troubleshoot: run this script directly in a terminal; any startup errors
# appear on stderr before the process blocks waiting for MCP JSON-RPC input.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v mcpserver-repl >/dev/null 2>&1; then
    printf '[mcpserver-cowork] ERROR: mcpserver-repl not found on PATH.\n' >&2
    printf '[mcpserver-cowork] Install with: dotnet tool install --global McpServer.Repl\n' >&2
    printf '[mcpserver-cowork] Or run the bundled installer:\n' >&2
    printf '[mcpserver-cowork]   bash "%s/../lib/ensure-repl.sh"\n' "$SCRIPT_DIR" >&2
    printf '[mcpserver-cowork] After install, restart the plugin or re-open the workspace.\n' >&2
    exit 1
fi

exec mcpserver-repl --agent-stdio
