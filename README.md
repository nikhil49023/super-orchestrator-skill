# Super Orchestrator Skill for Antigravity

An advanced orchestration skill for the Google Antigravity framework that drastically reduces token usage, saves cloud compute costs, and maintains clean context windows by dynamically orchestrating specialized worker agents.

## 🚀 Architecture & Features

This skill forces the Master Agent into an "Orchestrator Mode" where it acts as a high-level planner and delegates expensive operations:

1. **Zero-Token Codebase Indexing (`code-graph-first`)**: Bypasses traditional file reading (`grep`/`cat`). The agent uses a local Tree-sitter knowledge graph to semantically understand callers, impact radius, and module structures for ~100 tokens.
2. **Zero-Cost Local Research**: Dynamically spawns a `web-researcher` subagent that relies purely on `firecrawl-local` (running via local Docker) to fetch, scrape, and synthesize documentation without hitting expensive cloud LLM APIs.
3. **Workspace-Isolated CLI Workers**: Dynamically spawns a `cli-worker` to handle menial terminal tasks (e.g., fixing port 8080 mismatches, running linters). It enforces `Workspace: "branch"`, ensuring the worker safely resolves the issue in a separate Git branch without breaking the Master's environment or polluting the context window with terminal noise.
4. **Automated Token Logging**: Forces the agent to maintain an `orchestrator_metrics.md` artifact, logging exactly how many tokens and API calls it estimates saving via delegation.
5. **Persistent Memory**: Uses `architectural_decisions.md` to persist long-term state across context window compressions.

## 📦 Installation

To install this skill, simply clone this repository into your Antigravity skills directory:

```bash
mkdir -p ~/.gemini/skills
cd ~/.gemini/skills
git clone https://github.com/nikhil49023/antigravity-super-orchestrator-skill.git super-orchestrator
```

## 🛠 Dependencies

For maximum efficiency, this orchestrator assumes you have the following installed and configured in your Antigravity environment:
* `code-review-graph` MCP Server
* `firecrawl-local` Skill (with Firecrawl running on port 3002)
* `context-manager` Skill

## 💡 Usage

Start a task in Antigravity and prompt:

> *"Use the super-orchestrator skill to build a new React feature..."*

The agent will immediately:
1. Bootstrap the `cli-worker` and `web-researcher` agents via the `define_subagent` tool.
2. Index your repo using the Code Graph.
3. Delegate research and CLI debugging automatically while planning the architecture.
4. Log token savings to `orchestrator_metrics.md`.
