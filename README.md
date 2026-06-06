# Super Orchestrator Skill for Antigravity

An advanced orchestration skill for the [Google Antigravity](https://antigravity.google) framework that dramatically reduces token usage, eliminates cloud API costs for common tasks, and maintains clean context windows by routing work to the cheapest capable tool.

## ✨ What's New (v2.0)

- **🆓 Free Model Routing** — Lightweight tasks (graph builds, web searches, simple edits) are now delegated to free opencode models (`nemotron-3-ultra-free`, `deepseek-v4-flash-free`, `mimo-v2.5-free`), saving real money on routine operations.
- **🔒 Safelock Protocol** — When opencode workers are used, the orchestrator acts as a pre-flight gatekeeper, classifying tasks by risk before running. High-risk ops are blocked and handled directly. Low/medium tasks auto-approve with `--yolo` to prevent interactive permission deadlocks.
- **🕷️ Auto-Setup** — A `setup.sh` script auto-installs all dependencies (Firecrawl Docker stack, code-review-graph, opencode) if they're missing on first run.
- **📊 Routing Matrix** — Clear task-to-worker decision table: graph MCP for architecture, Firecrawl for research, free opencode models for code tasks, `self` subagents for complex multi-file work.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  MASTER ORCHESTRATOR (YOU)                  │
│         High-level reasoning, architecture, safety         │
└──────────┬──────────────┬──────────────┬───────────────────┘
           │              │              │
     ┌─────▼──────┐ ┌─────▼──────┐ ┌───▼──────────────────┐
     │ code-review│ │ web-       │ │ opencode free worker │
     │ -graph MCP │ │ researcher │ │ (nemotron / deepseek)│
     │            │ │ subagent   │ │                      │
     │ Semantic   │ │ + Firecrawl│ │ Graph builds, edits, │
     │ codebase   │ │ localhost  │ │ formatting, linting  │
     │ indexing   │ │ :3002      │ │ --yolo, zero prompts │
     └────────────┘ └────────────┘ └──────────────────────┘
                                          │
                                   ┌──────▼──────────┐
                                   │ self subagent   │
                                   │ (branch workspace│
                                   │ for complex work)│
                                   └─────────────────┘
```

---

## 🚀 Quick Start

### 1. Install the skill

```bash
mkdir -p ~/.gemini/skills
cd ~/.gemini/skills
git clone https://github.com/nikhil49023/super-orchestrator-skill.git super-orchestrator
```

### 2. Run setup (auto-installs all dependencies)

```bash
bash ~/.gemini/skills/super-orchestrator/scripts/setup.sh
```

The setup script will:
- ✅ Verify Docker is installed and running
- ✅ Clone and start the Firecrawl Docker stack (port 3002) if not running
- ✅ Install `code-review-graph` MCP server via uv/pip
- ✅ Install `opencode` CLI and configure free models as default

### 3. Activate in Antigravity

Open Antigravity and prompt:

> *"Use the super-orchestrator skill to..."*

---

## 📦 Dependencies

| Dependency | Purpose | Auto-Installed? |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | Runs Firecrawl containers | ✅ (Linux) |
| [Firecrawl](https://github.com/mendableai/firecrawl) | Zero-cost local web scraping | ✅ via Docker |
| [code-review-graph](https://pypi.org/project/code-review-graph/) | Semantic codebase indexing MCP | ✅ via uv/pip |
| [opencode CLI](https://opencode.ai) | Free model task delegation | ✅ via npm |
| Antigravity `context-manager` skill | Context window compression | Manual (bundled in Antigravity) |

---

## 🆓 Free Model Assignment

The skill routes tasks to the cheapest capable model:

| Task | Model | Cost |
|---|---|---|
| Build code-review-graph | `opencode/nemotron-3-ultra-free` | **Free** |
| Web research summarization | `opencode/deepseek-v4-flash-free` | **Free** |
| Lint fixes, formatting | `opencode/mimo-v2.5-free` | **Free** |
| Complex refactors | Master agent or `self` subagent | Paid (unavoidable) |
| Architecture decisions | Master agent | Paid (unavoidable) |

---

## 🔒 Safelock: How Permission Gating Works

A known failure mode of opencode in automated contexts is **interactive permission prompts** — the CLI asks for approval but no human is watching, causing the process to hang forever.

The skill solves this at **two levels**:

1. **Pre-flight risk check** — Before running opencode, classify the task:
   - 🟢 LOW / 🟡 MEDIUM risk → run `opencode run --yolo` (auto-approve)
   - 🔴 HIGH risk → block, handle with direct write tools

2. **`--yolo` flag** — Always passed for automated invocations, preventing any interactive prompt from appearing.

```bash
# The standard safe invocation pattern
opencode run --yolo \
  --model opencode/nemotron-3-ultra-free \
  --dir /path/to/project \
  "Your task here"
```

---

## 🕷️ Firecrawl Setup Details

The skill relies on a **self-hosted Firecrawl** instance at `http://localhost:3002` for all web research. This avoids cloud search API costs entirely.

**Manual setup (if setup.sh isn't used):**
```bash
git clone https://github.com/mendableai/firecrawl.git ~/firecrawl-local
cd ~/firecrawl-local
docker compose up -d
```

**Health check:**
```bash
curl -X POST http://localhost:3002/v1/search \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "limit": 1}'
```

---

## 💡 Example Prompts

```
"Use the super-orchestrator skill to add a payment module to this Next.js app"

"Use the super-orchestrator skill to research the best vector DB options and 
 implement one in our Python backend"

"Use the super-orchestrator skill to refactor all API handlers to use async/await"
```

---

## 🗂️ Project Structure

```
super-orchestrator/
├── SKILL.md          # Main skill instructions for the agent
├── README.md         # This file
└── scripts/
    └── setup.sh      # Auto-installs all dependencies
```

---

## 📈 Estimated Token Savings

| Operation | Without Orchestration | With Orchestration | Savings |
|---|---|---|---|
| Understand 50-file codebase | ~15,000 tokens | ~200 tokens (graph query) | **98%** |
| Research 5 documentation pages | ~10,000 tokens | ~0 (Firecrawl local) | **100%** |
| Build code graph | ~5,000 tokens | ~0 (free model) | **100%** |
| Triage 10k-line log | ~12,000 tokens | ~300 (local-model-worker) | **97%** |

---

## 📄 License

MIT
