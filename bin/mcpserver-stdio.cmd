@echo off
:: mcpserver-stdio.cmd -- Windows wrapper: launch mcpserver-repl in stdio MCP mode.
::
:: Called by the plugin .mcp.json "command" entry. Cowork passes workspace env
:: vars (MCP_WORKSPACE_PATH, MCP_SESSION_AGENT, etc.) to this process.
::
:: Prerequisite: mcpserver-repl must be installed as a .NET global tool.
::   dotnet tool install --global McpServer.Repl
::
:: To install automatically via the bundled helper:
::   powershell -ExecutionPolicy Bypass -File "%~dp0..\lib\ensure-repl.ps1"
::
:: Troubleshoot: run this script directly in a terminal; any startup errors
:: appear on stderr before the process blocks waiting for MCP JSON-RPC input.

setlocal

where mcpserver-repl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [mcpserver-cowork] ERROR: mcpserver-repl not found on PATH. 1>&2
    echo [mcpserver-cowork] Install with: dotnet tool install --global McpServer.Repl 1>&2
    echo [mcpserver-cowork] Or run the bundled installer: 1>&2
    echo [mcpserver-cowork]   powershell -ExecutionPolicy Bypass -File "%~dp0..\lib\ensure-repl.ps1" 1>&2
    echo [mcpserver-cowork] After install, restart the plugin or re-open the workspace. 1>&2
    exit /b 1
)

mcpserver-repl --agent-stdio
