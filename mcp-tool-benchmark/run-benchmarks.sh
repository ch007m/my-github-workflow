#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_CONFIG="$SCRIPT_DIR/mcp-servers.json"
RESULTS_FILE="$SCRIPT_DIR/benchmark-results.csv"
PROMPT="Analyze /tmp and report your findings following the skill instructions"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

run_scenario() {
    local name="$1"
    local skill_path="$2"
    local mcp_config="${3:-}"

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Scenario: ${name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local -a cmd=(acp run -a claude-acp -v --backup no)
    cmd+=(-s "$skill_path")
    if [[ -n "$mcp_config" ]]; then
        cmd+=(--mcp-server-config "$mcp_config")
    fi
    cmd+=(-p "$PROMPT")

    echo -e "${YELLOW}Command:${NC} ${cmd[*]}"
    echo ""

    local start_time
    start_time=$(date +%s)

    local output
    output=$("${cmd[@]}" 2>&1) || true

    local end_time
    end_time=$(date +%s)
    local elapsed_s=$(( end_time - start_time ))

    echo "$output"

    # Extract last usage line: [Usage] used=24540 size=200000 cost={amount=0.087753, currency=USD}
    local last_usage
    last_usage=$(echo "$output" | grep '\[Usage\]' | tail -1 || echo "")

    local tokens_used="N/A"
    local context_size="N/A"
    local cost="N/A"

    if [[ -n "$last_usage" ]]; then
        tokens_used=$(echo "$last_usage" | sed -n 's/.*used=\([0-9]*\).*/\1/p')
        context_size=$(echo "$last_usage" | sed -n 's/.*size=\([0-9]*\).*/\1/p')
        cost=$(echo "$last_usage" | sed -n 's/.*amount=\([0-9.]*\).*/\1/p')
        if [[ -z "$cost" ]]; then
            cost="N/A"
        else
            local currency
            currency=$(echo "$last_usage" | sed -n 's/.*currency=\([A-Z]*\).*/\1/p')
            cost="${cost} ${currency}"
        fi
        [[ -z "$tokens_used" ]] && tokens_used="N/A"
        [[ -z "$context_size" ]] && context_size="N/A"
    fi

    # Count tool calls (unique tool invocations, not updates)
    local tool_calls
    tool_calls=$(echo "$output" | grep -c '\[ToolCall\]' || echo "0")

    echo -e "\n${CYAN}── Results ─────────────────────────────────${NC}"
    printf "  %-16s %s\n" "Elapsed time:"  "${elapsed_s}s"
    printf "  %-16s %s\n" "Tokens used:"   "$tokens_used"
    printf "  %-16s %s\n" "Context size:"  "$context_size"
    printf "  %-16s %s\n" "Tool calls:"    "$tool_calls"
    printf "  %-16s %s\n" "Cost:"          "$cost"
    echo ""

    echo "${name}|${elapsed_s}s|${tokens_used}|${tool_calls}|${cost}" >> "$RESULTS_FILE"
}

# ── Main ──────────────────────────────────────────────────────────────────

rm -f "$RESULTS_FILE"
echo "Scenario|Elapsed|Tokens|Tool Calls|Cost" > "$RESULTS_FILE"

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ACP MCP Server Benchmark Suite                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo -e "Prompt: ${PROMPT}"

# Scenario 1: Agent uses MCP filesystem server tools
run_scenario \
    "1. MCP Server" \
    "$SCRIPT_DIR/scenario1-skill" \
    "$MCP_CONFIG"

# Scenario 2: Skill prescribes explicit bash commands (same ops as MCP, no MCP)
run_scenario \
    "2. Skill with explicit commands (no MCP)" \
    "$SCRIPT_DIR/scenario2-skill"

# Scenario 3: Agent decides freely which built-in tools to use (no MCP)
run_scenario \
    "3. Agent tools (no MCP)" \
    "$SCRIPT_DIR/scenario3-skill"

# ── Summary ───────────────────────────────────────────────────────────────

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                         Summary                                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
column -t -s'|' "$RESULTS_FILE"
echo -e "\nResults saved to: ${RESULTS_FILE}"
