#!/bin/bash
# ============================================================================
#  🟢 GitHub Contribution Painter
#  Generate backdated commits to fill your GitHub contribution graph.
#
#  Usage:
#    Single date:  ./contribute.sh <DATE> <COUNT>
#    Date range:   ./contribute.sh <START_DATE> <END_DATE> <COUNT_PER_DAY>
#
#  Options:
#    -y, --yes     Skip confirmation prompt
#
#  Examples:
#    ./contribute.sh 2026-01-15 5              # 5 commits on Jan 15
#    ./contribute.sh 2026-01-01 2026-01-31 3   # 3 commits/day for all of January
#    ./contribute.sh 2026-06-01 2026-06-30     # 1 commit/day for June (default)
#    ./contribute.sh -y 2026-01-15 5           # skip confirmation
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRIB_FILE="$SCRIPT_DIR/contributions.log"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ─────────────────────────────────────────────────────────────────
usage() {
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}./contribute.sh${NC} ${YELLOW}<DATE>${NC} ${YELLOW}<COUNT>${NC}                           # Single date"
    echo -e "  ${CYAN}./contribute.sh${NC} ${YELLOW}<START>${NC} ${YELLOW}<END>${NC} ${YELLOW}[COUNT_PER_DAY]${NC}            # Date range"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${YELLOW}-y, --yes${NC}   Skip confirmation prompt"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ./contribute.sh 2026-01-15 5"
    echo -e "  ./contribute.sh 2026-01-01 2026-01-31 3"
    echo -e "  ./contribute.sh 2026-06-01 2026-06-30"
    echo -e "  ./contribute.sh -y 2026-01-15 5"
    echo ""
    echo -e "${BOLD}Date format:${NC} YYYY-MM-DD"
    exit 1
}

confirm() {
    if [[ "$SKIP_CONFIRM" == true ]]; then
        return 0
    fi
    echo ""
    echo -e "  ${RED}⚠  This action is irreversible — commits cannot be undone.${NC}"
    echo -e -n "  ${BOLD}Proceed? [y/N]:${NC} "
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "  ${YELLOW}Aborted.${NC}"
        exit 0
    fi
    echo ""
}

is_date() {
    if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        date -j -f "%Y-%m-%d" "$1" "+%Y-%m-%d" &>/dev/null 2>&1
        return $?
    fi
    return 1
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

make_commits() {
    local target_date="$1"
    local count="$2"
    local display_date
    display_date=$(date -j -f "%Y-%m-%d" "$target_date" "+%a %b %d, %Y" 2>/dev/null || echo "$target_date")

    for ((i = 1; i <= count; i++)); do
        # Randomize the time within the day for realism
        local hour=$((RANDOM % 14 + 8))   # 08:00 – 21:59
        local minute=$((RANDOM % 60))
        local second=$((RANDOM % 60))
        local timestamp="${target_date}T$(printf '%02d:%02d:%02d' $hour $minute $second)"

        echo "${timestamp} | commit #${i}/${count}" >> "$CONTRIB_FILE"

        export GIT_AUTHOR_DATE="$timestamp"
        export GIT_COMMITTER_DATE="$timestamp"

        git add -A
        git commit --allow-empty \
            -m "contrib: ${target_date} [${i}/${count}]" \
            --date="$timestamp" \
            --quiet
    done

    echo -e "  ${GREEN}✓${NC} ${display_date}  →  ${BOLD}${count}${NC} commit(s)"
}

# ── Parse Flags ─────────────────────────────────────────────────────────────
SKIP_CONFIRM=false
while [[ $# -gt 0 && "$1" =~ ^- ]]; do
    case "$1" in
        -y|--yes) SKIP_CONFIRM=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown flag:${NC} $1"; usage ;;
    esac
done

# ── Parse Arguments ─────────────────────────────────────────────────────────
if [[ $# -lt 2 ]]; then
    usage
fi

if is_date "$1" && is_number "$2"; then
    # ── Mode 1: Single date ─────────────────────────────────────────────
    TARGET_DATE="$1"
    COMMIT_COUNT="$2"

    echo ""
    echo -e "${BOLD}${CYAN}🟢 Generating ${COMMIT_COUNT} commits on ${TARGET_DATE}${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────${NC}"

    confirm

    cd "$SCRIPT_DIR"
    make_commits "$TARGET_DATE" "$COMMIT_COUNT"

elif is_date "$1" && is_date "$2"; then
    # ── Mode 2: Date range ──────────────────────────────────────────────
    START_DATE="$1"
    END_DATE="$2"
    COMMITS_PER_DAY="${3:-1}"

    if ! is_number "$COMMITS_PER_DAY"; then
        echo -e "${RED}Error:${NC} commits-per-day must be a number, got '${COMMITS_PER_DAY}'"
        exit 1
    fi

    start_epoch=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
    end_epoch=$(date -j -f "%Y-%m-%d" "$END_DATE" "+%s")

    if [[ $start_epoch -gt $end_epoch ]]; then
        echo -e "${RED}Error:${NC} start date must be before end date"
        exit 1
    fi

    total_days=$(( (end_epoch - start_epoch) / 86400 + 1 ))
    total_commits=$((total_days * COMMITS_PER_DAY))

    echo ""
    echo -e "${BOLD}${CYAN}🟢 Generating ${COMMITS_PER_DAY} commit(s)/day from ${START_DATE} → ${END_DATE}${NC}"
    echo -e "   ${YELLOW}${total_days} days × ${COMMITS_PER_DAY} commits = ${total_commits} total commits${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────${NC}"

    confirm

    cd "$SCRIPT_DIR"
    current_epoch=$start_epoch

    while [[ $current_epoch -le $end_epoch ]]; do
        current_date=$(date -j -f "%s" "$current_epoch" "+%Y-%m-%d")
        make_commits "$current_date" "$COMMITS_PER_DAY"
        current_epoch=$((current_epoch + 86400))
    done
else
    echo -e "${RED}Error:${NC} Could not parse arguments."
    echo ""
    usage
fi

# ── Push ────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo -e "${CYAN}Pushing to origin/main...${NC}"
git push -u origin main --quiet 2>/dev/null || git push origin main --quiet

echo -e "${GREEN}${BOLD}✅ Done!${NC} Contributions will appear on your GitHub profile shortly."
echo ""
