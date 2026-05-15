#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const errors = [];

function readJson(relativePath) {
  const fullPath = path.join(root, relativePath);
  try {
    return JSON.parse(fs.readFileSync(fullPath, "utf8"));
  } catch (error) {
    errors.push(`${relativePath}: ${error.message}`);
    return null;
  }
}

function requirePath(relativePath) {
  if (!fs.existsSync(path.join(root, relativePath))) {
    errors.push(`missing ${relativePath}`);
  }
}

const plugin = readJson(".claude-plugin/plugin.json");
const marketplace = readJson(".claude-plugin/marketplace.json");
const mcp = readJson(".mcp.json");
const hooks = readJson("hooks/hooks.json");

if (plugin) {
  if (plugin.name !== "mcpserver-cowork") {
    errors.push(`plugin name must be mcpserver-cowork, got ${plugin.name}`);
  }

  for (const field of ["skills", "hooks", "mcpServers", "userConfig"]) {
    if (!Object.prototype.hasOwnProperty.call(plugin, field)) {
      errors.push(`plugin.json missing ${field}`);
    }
  }

  if (!plugin.userConfig?.workspace_path?.required) {
    errors.push("workspace_path userConfig must be required");
  }
}

if (marketplace) {
  if (marketplace.name !== "mcpserver-cowork") {
    errors.push(`marketplace name must be mcpserver-cowork, got ${marketplace.name}`);
  }
  if (!marketplace.metadata?.description) {
    errors.push("marketplace metadata.description is required");
  }
  const entry = marketplace.plugins?.find((item) => item.name === "mcpserver-cowork");
  if (!entry) {
    errors.push("marketplace missing mcpserver-cowork plugin entry");
  } else if (entry.source !== "./") {
    errors.push(`marketplace source must be ./, got ${entry.source}`);
  }
}

if (mcp) {
  const server = mcp.mcpServers?.mcpserver;
  if (!server) {
    errors.push(".mcp.json missing mcpServers.mcpserver");
  } else {
    if (server.command !== "mcpserver-repl") {
      errors.push(`mcpserver command must be mcpserver-repl, got ${server.command}`);
    }
    if (!Array.isArray(server.args) || !server.args.includes("--agent-stdio")) {
      errors.push("mcpserver args must include --agent-stdio");
    }
    if (server.env?.MCP_SESSION_AGENT !== "ClaudeCowork") {
      errors.push("MCP_SESSION_AGENT must be ClaudeCowork");
    }
    if (server.env?.MCP_WORKSPACE_PATH !== "${user_config.workspace_path}") {
      errors.push("MCP_WORKSPACE_PATH must come from user_config.workspace_path");
    }
  }
}

if (hooks && !hooks.hooks) {
  errors.push("hooks/hooks.json missing hooks object");
}

for (const skill of ["todo", "session", "requirements", "graphrag"]) {
  requirePath(`skills/${skill}/SKILL.md`);
}

for (const script of [
  "lib/repl-invoke.sh",
  "lib/marker-resolver.sh",
  "lib/pending-import-to-yaml.js",
  "lib/sessionlog-submit-body.js",
  "hooks/scripts/session-start.sh",
  "hooks/scripts/stop-gate.sh"
]) {
  requirePath(script);
}

if (errors.length > 0) {
  console.error(errors.join("\n"));
  process.exit(1);
}

console.log("mcpserver-cowork plugin structure is valid");
