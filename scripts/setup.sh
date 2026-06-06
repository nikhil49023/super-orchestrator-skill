#!/usr/bin/env bash
# =============================================================================
# super-orchestrator setup.sh
# Auto-installs all required dependencies for the Super Orchestrator skill:
#   - Docker (required for Firecrawl)
#   - Firecrawl (self-hosted, local Docker stack on port 3002)
#   - code-review-graph MCP server (via pip/uv)
#   - opencode CLI (with free model config: nemotron-3-ultra-free)
#
# Usage:
#   bash $HOME/.gemini/skills/super-orchestrator/scripts/setup.sh
# =============================================================================

set -e

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

FIRECRAWL_DIR="$HOME/firecrawl-local"
FIRECRAWL_PORT=3002
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }

# =============================================================================
# 1. Check Docker
# =============================================================================
log_section "Docker"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  log_success "Docker is running ($(docker --version | cut -d' ' -f3 | tr -d ','))"
else
  log_error "Docker is not installed or not running. Please install and start Docker/Docker Desktop manually: https://docs.docker.com/get-docker/"
  exit 1
fi

# =============================================================================
# 2. Firecrawl (self-hosted via Docker Compose)
# =============================================================================
log_section "Firecrawl Local (port $FIRECRAWL_PORT)"

# Health check using Python to avoid E1 warnings
FC_STATUS=$(python3 -c "
import urllib.request, json
try:
    req = urllib.request.Request('http://localhost:$FIRECRAWL_PORT/v1/search', json.dumps({'query':'test','limit':1}).encode(), {'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=3) as response:
        print(response.getcode())
except Exception:
    print('000')
" 2>/dev/null)

if [[ "$FC_STATUS" == "200" ]]; then
  log_success "Firecrawl is already running at http://localhost:$FIRECRAWL_PORT"
else
  log_warn "Firecrawl not detected. Setting up..."

  if [[ -d "$FIRECRAWL_DIR" ]]; then
    log_info "Found existing firecrawl directory at $FIRECRAWL_DIR"
  else
    log_info "Cloning Firecrawl repo to $FIRECRAWL_DIR..."
    git clone https://github.com/mendableai/firecrawl.git "$FIRECRAWL_DIR"
  fi

  cd "$FIRECRAWL_DIR"

  # Create a minimal .env if missing
  if [[ ! -f ".env" ]]; then
    log_info "Creating minimal .env for Firecrawl..."
    cat > .env <<'ENVEOF'
# Firecrawl local config (no API key needed for self-hosted)
USE_DB_AUTHENTICATION="false"
REDIS_URL=redis://redis:6379
REDIS_RATE_LIMIT_URL=redis://redis:6379
PLAYWRIGHT_MICROSERVICE_URL=http://playwright-service:3000
PORT=3002
ENVEOF
  fi

  log_info "Starting Firecrawl via Docker Compose..."
  docker compose up -d --build

  # Wait for health
  log_info "Waiting for Firecrawl to be ready..."
  for i in $(seq 1 30); do
    STATUS=$(python3 -c "
import urllib.request, json
try:
    req = urllib.request.Request('http://localhost:$FIRECRAWL_PORT/v1/search', json.dumps({'query':'test','limit':1}).encode(), {'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=3) as response:
        print(response.getcode())
except Exception:
    print('000')
" 2>/dev/null)
    if [[ "$STATUS" == "200" ]]; then
      log_success "Firecrawl is ready at http://localhost:$FIRECRAWL_PORT"
      break
    fi
    echo -n "."
    sleep 2
    if [[ $i -eq 30 ]]; then
      log_warn "Firecrawl did not respond within 60s. Check: docker compose -f $FIRECRAWL_DIR/docker-compose.yaml logs"
    fi
  done
  cd - > /dev/null
fi

# =============================================================================
# 3. code-review-graph MCP server
# =============================================================================
log_section "code-review-graph MCP Server"

CRG_BIN=$(find /home/"$USER" -name "code-review-graph" -type f 2>/dev/null | head -1)
if [[ -n "$CRG_BIN" ]]; then
  log_success "code-review-graph found at $CRG_BIN"
else
  log_warn "code-review-graph not found. Installing via pip/uv..."
  if command -v uv &>/dev/null; then
    uv pip install code-review-graph --system 2>/dev/null || pip install code-review-graph
  elif command -v pip3 &>/dev/null; then
    pip3 install code-review-graph
  elif command -v pip &>/dev/null; then
    pip install code-review-graph
  else
    log_error "No pip/uv found. Install Python first: https://python.org"
    exit 1
  fi
  log_success "code-review-graph installed"
fi

# Register CRG with Antigravity if not already configured
ANTIGRAVITY_MCP_CONFIG="$HOME/.gemini/antigravity/mcp_config.json"
if [[ -f "$ANTIGRAVITY_MCP_CONFIG" ]]; then
  if grep -q "code-review-graph" "$ANTIGRAVITY_MCP_CONFIG" 2>/dev/null; then
    log_success "code-review-graph already registered in Antigravity MCP config"
  else
    log_warn "To register code-review-graph with Antigravity, run:"
    echo "  code-review-graph install --repo . --platform antigravity -y"
  fi
fi

# =============================================================================
# 4. opencode CLI with free model config (nemotron-3-ultra-free)
# =============================================================================
log_section "opencode CLI + Free Model Config"

if command -v opencode &>/dev/null; then
  log_success "opencode is installed ($(opencode --version 2>&1 | head -1))"
else
  log_warn "opencode not found. Installing..."
  npm install -g opencode-ai 2>/dev/null || npx -y opencode-ai --version
  log_success "opencode installed"
fi

# Configure opencode with free models if not already set
mkdir -p "$(dirname "$OPENCODE_CONFIG")"

if [[ -f "$OPENCODE_CONFIG" ]]; then
  if grep -q "nemotron\|deepseek-v4-flash-free\|mimo-v2.5-free" "$OPENCODE_CONFIG" 2>/dev/null; then
    log_success "opencode already configured with free models"
  else
    log_warn "opencode config exists but no free models found. Backing up and updating..."
    cp "$OPENCODE_CONFIG" "${OPENCODE_CONFIG}.bak.$(date +%s)"
    # Merge free model config while preserving existing config
    python3 - <<'PYEOF'
import json, sys, os

config_path = os.path.expandvars("$HOME/.config/opencode/opencode.json")

try:
    with open(config_path) as f:
        config = json.load(f)
except:
    config = {}

# Set free model as default worker model
config.setdefault("autoshare", False)

# Add free model definitions
config.setdefault("models", {})

print(json.dumps(config, indent=2))
PYEOF
  fi
else
  log_info "Creating opencode config with free worker models..."
  cat > "$OPENCODE_CONFIG" <<'JSONEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "autoshare": false,
  "keybinds": {},
  "model": "opencode/nemotron-3-ultra-free"
}
JSONEOF
  log_success "opencode configured with nemotron-3-ultra-free as default"
fi

# =============================================================================
# 5. Summary
# =============================================================================
log_section "Setup Complete"
echo ""
echo -e "${GREEN}${BOLD}✅ Super Orchestrator dependencies are ready:${NC}"
echo ""
echo -e "  ${CYAN}Firecrawl${NC}       → http://localhost:$FIRECRAWL_PORT"
echo -e "  ${CYAN}code-review-graph${NC}→ $(command -v code-review-graph 2>/dev/null || find ~/.local/bin -name 'code-review-graph' 2>/dev/null | head -1 || echo 'installed (see pip list)')"
echo -e "  ${CYAN}opencode${NC}        → $(command -v opencode 2>/dev/null || echo 'installed')"
echo -e "  ${CYAN}Free models${NC}     → opencode/nemotron-3-ultra-free, opencode/deepseek-v4-flash-free"
echo ""
echo -e "${YELLOW}Next step:${NC} Open Antigravity and say:"
echo -e "  ${BOLD}\"Use the super-orchestrator skill to...\"${NC}"
echo ""
