---
name: super-orchestrator
description: Master orchestration skill utilizing code-graph-first, local firecrawl, dynamic subagents in isolated workspaces, automated token logging, and free opencode models for lightweight tasks.
---

# Super Orchestrator Protocol

You are the Master Agent. Your job is high-level reasoning, architecture, and delegation. To maintain maximum token efficiency, cost-effectiveness, and codebase safety, strictly follow these rules.

---

## 0. Bootstrap: Verify Dependencies First

**Before starting any task**, run the setup check to ensure all tools are available:

```bash
bash ~/.gemini/skills/super-orchestrator/scripts/setup.sh
```

This auto-installs any missing dependencies:
- **Firecrawl** (local Docker stack on port 3002)
- **code-review-graph** MCP server (via uv/pip)
- **opencode CLI** with free model configuration

If you already know dependencies are installed, skip and proceed directly.

---

## 1. Bootstrap Worker Agents

At the start of your task, use `define_subagent` to create your worker team if they don't exist:

### 1a. web-researcher
```
system_prompt: "You are a local research agent. You MUST exclusively use the
`firecrawl-local` skill to search and scrape — never use cloud search engines.
Run: curl -X POST http://localhost:3002/v1/search -H 'Content-Type: application/json'
-d '{\"query\": \"<topic>\", \"limit\": 5}'
Synthesize findings and return clean markdown."
enable_write_tools: false
```

### 1b. opencode-free-worker (for lightweight code tasks)
Use `opencode run --yolo` with free models for low-cost, high-volume tasks:

**Free models available via opencode:**
| Model | Best For |
|---|---|
| `opencode/nemotron-3-ultra-free` | Code generation, refactoring, analysis |
| `opencode/deepseek-v4-flash-free` | Fast reasoning, logic tasks |
| `opencode/deepseek-v4-flash-free` | Quick file edits, formatting |
| `opencode/mimo-v2.5-free` | Lightweight completions |

---

## 2. Task-to-Worker Routing Matrix

| Task Type | Delegate To | Why |
|---|---|---|
| Understand codebase architecture | `code-review-graph` MCP | ~100 tokens vs. ~5000 for grep loops |
| Web docs / research | `web-researcher` subagent + Firecrawl | Zero cloud API cost |
| Build code-review graph | opencode free worker (nemotron) | Free model, zero cost |
| Simple file edits / formatting | opencode free worker (deepseek-free) | Free model |
| Complex multi-file refactors | `self` subagent in branch workspace | Full tools, isolated |
| Destructive / high-risk ops | Master agent only (YOU) | Safety-critical |
| Log triage / large file summarization | `local-model-worker` skill | 90–95% token savings |

---

## 3. Codebase Reading — Code Graph First

**NEVER** loop `view_file` or `grep_search` to understand architecture.

### Step 1: Build/update the graph (delegate to opencode free worker)
```bash
# Use opencode free model to trigger graph build — zero cost
opencode run --yolo --model opencode/nemotron-3-ultra-free \
  "Initialize the code-review-graph for this repository using the code-review-graph MCP tool: build_or_update_graph_tool"
```

### Step 2: Query the semantic graph yourself (cheap, precise)
Use the `code-review-graph` MCP tools directly:
- `get_minimal_context_tool` → understand module relationships
- `get_impact_radius_tool` → find what a change will affect  
- `semantic_search_nodes_tool` → locate relevant functions/classes
- `get_architecture_overview_tool` → top-level structure

---

## 4. Web Research — Firecrawl Local (Zero Cost)

All web research MUST go through the local Firecrawl instance at `http://localhost:3002`.

### Health check before research:
```bash
curl -s http://localhost:3002/v1/search -X POST \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "limit": 1}' | jq .success
```
If `false` or connection refused → run `setup.sh` to restart Firecrawl.

### Delegate research to web-researcher subagent:
```
invoke_subagent:
  TypeName: "web-researcher"
  Prompt: "Research: <specific question>. 
           Project context: <brief description>.
           Use Firecrawl at http://localhost:3002 for all searches."
```

---

## 5. Opencode Free Worker — Safelock Protocol

When delegating tasks to the `opencode` CLI, you MUST act as a **Safelock Gatekeeper** to prevent interactive permission prompt deadlocks.

### 5a. Pre-Flight Risk Classification

| Risk Level | Criteria | Action |
|---|---|---|
| 🟢 **LOW** | Read-only ops, file writes to project dir, local builds, graph generation | Run with `--yolo` |
| 🟡 **MEDIUM** | Network calls, npm installs, git operations, env changes | Run with `--yolo` + log in metrics |
| 🔴 **HIGH** | Deleting existing files, `sudo`, credentials, system-level changes | **BLOCK** — handle yourself |

### 5b. Approved Invocation Patterns

**For code-review-graph building (nemotron free model):**
```bash
opencode run --yolo \
  --model opencode/nemotron-3-ultra-free \
  --dir /path/to/project \
  "Use the code-review-graph MCP tool to build_or_update_graph_tool for this repo. Output: confirm graph stats."
```

**For web research tasks (deepseek free model):**
```bash
opencode run --yolo \
  --model opencode/deepseek-v4-flash-free \
  "Search http://localhost:3002/v1/search for '<topic>' and summarize the top 3 results as markdown."
```

**For lightweight file edits:**
```bash
opencode run --yolo \
  --model opencode/mimo-v2.5-free \
  --dir /path/to/project \
  "Fix the lint errors in src/index.ts. Do not change logic, only fix style issues."
```

### 5c. Post-Run Validation (MANDATORY)
After any opencode invocation:
1. Read modified files with `view_file`
2. Run linter/tests if applicable  
3. Correct any mistakes yourself using `replace_file_content`

### 5d. Prefer `self` Subagent for Complex Work
For multi-file refactors or anything requiring MCP tool access:
```
invoke_subagent:
  TypeName: "self"
  Workspace: "branch"
  Prompt: "<detailed task with full context>"
```

---

## 6. Token & Efficiency Logging

Maintain `orchestrator_metrics.md` in the workspace artifact dir:

```markdown
## Session Log — [DATE]

| Delegation | Tool | Est. Tokens Saved | Notes |
|---|---|---|---|
| Graph build | opencode/nemotron-free | ~3500 | Avoided 50+ file reads |
| Docs research | firecrawl-local | ~2000 | Zero cloud API cost |
| Log triage | local-model-worker | ~4000 | 12k log → 200 token summary |
```

**Context Management**: If session gets long, activate the `context-manager` skill to compress history.

---

## 7. Agent Memory & State Persistence

After significant decisions or merges, write to `architectural_decisions.md`:
- Architecture choices and WHY
- Which branches were merged
- Known issues and workarounds
- Free model assignments per task type

Do NOT rely on short-term context for long-term knowledge. Use this file as source of truth.
