#!/bin/bash
# ============================================================================
#  🟢 GitHub Contribution Painter
#  Generate backdated commits to fill your GitHub contribution graph.
#
#  Usage:
#    Single date:  contribute.sh <DATE> <COUNT|random>
#    Week mode:    contribute.sh <DATE> --week <COUNT|random>
#    Date range:   contribute.sh <START_DATE> <END_DATE> <COUNT_PER_DAY|random>
#
#  Options:
#    -y, --yes     Skip confirmation prompt
#    --week        Generate commits for 7 days starting from DATE
#
#  COUNT can be a number or the keyword 'random' (picks 1–50 per day).
#
#  Date formats (all accepted, auto-detected):
#    yyyy-mm-dd    2026-01-15
#    dd-mm-yyyy    15-01-2026
#    yy-mm-dd      26-01-15      (2-digit year detected when first part > 31)
#    dd-mm-yy      15-01-26      (default for ambiguous 2-digit dates)
#
#  Examples:
#    contribute.sh 2026-01-15 5                  # 5 commits on Jan 15
#    contribute.sh 15-01-2026 5                  # same, dd-mm-yyyy format
#    contribute.sh 2026-01-15 random             # random 1–50 commits on Jan 15
#    contribute.sh 2026-01-15 --week random      # random commits/day for 7 days
#    contribute.sh 15-01-26 --week 5             # 5 commits/day for a week
#    contribute.sh 2026-01-01 2026-01-31 3       # 3 commits/day for all of January
#    contribute.sh 2026-01-01 2026-01-31 random  # random 1–50 commits each day
#    contribute.sh -y 2026-01-15 5               # skip confirmation
# ============================================================================

set -euo pipefail

# ── Target Repo (ALWAYS use this, regardless of where you run the script) ──
REPO_DIR="$HOME/projects/daily-contributions"
CONTRIB_FILE="$REPO_DIR/contributions.log"

# Verify the target repo exists and is a git repo
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo -e "\033[0;31mError:\033[0m Target repo not found at $REPO_DIR"
    echo "Run setup.sh first, or clone: git clone git@github.com:shard-c6/daily-contributions.git $REPO_DIR"
    exit 1
fi

# Verify remote points to the right place
REMOTE_URL=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")
if [[ "$REMOTE_URL" != *"daily-contributions"* ]]; then
    echo -e "\033[0;31mError:\033[0m Repo at $REPO_DIR does not point to daily-contributions!"
    echo "Remote: $REMOTE_URL"
    exit 1
fi

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
    echo -e "  ${CYAN}contribute.sh${NC} ${YELLOW}<DATE>${NC} ${YELLOW}<COUNT|random>${NC}                        # Single date"
    echo -e "  ${CYAN}contribute.sh${NC} ${YELLOW}<DATE>${NC} ${YELLOW}--week${NC} ${YELLOW}<COUNT|random>${NC}                  # 7 days from DATE"
    echo -e "  ${CYAN}contribute.sh${NC} ${YELLOW}<START>${NC} ${YELLOW}<END>${NC} ${YELLOW}[COUNT_PER_DAY|random]${NC}         # Date range"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${YELLOW}-y, --yes${NC}     Skip confirmation prompt"
    echo -e "  ${YELLOW}--week${NC}        Generate commits for 7 days starting from DATE"
    echo -e "  ${YELLOW}random${NC}        Use as COUNT to pick a random number between 1–50 per day"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  contribute.sh 2026-01-15 5"
    echo -e "  contribute.sh 15-01-2026 random"
    echo -e "  contribute.sh 2026-01-15 --week random"
    echo -e "  contribute.sh 15-01-26 --week 5"
    echo -e "  contribute.sh 2026-01-01 2026-01-31 3"
    echo -e "  contribute.sh 2026-01-01 2026-01-31 random"
    echo -e "  contribute.sh -y 2026-01-15 5"
    echo ""
    echo -e "${BOLD}Date formats:${NC} yyyy-mm-dd, dd-mm-yyyy, yy-mm-dd, dd-mm-yy"
    echo -e "${BOLD}Target repo:${NC} $REPO_DIR"
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

# ── Date Normalization ──────────────────────────────────────────────────────
# Accepts: yyyy-mm-dd, dd-mm-yyyy, yy-mm-dd, dd-mm-yy
# Returns: YYYY-MM-DD on stdout, exit 0 on success, exit 1 on failure
normalize_date() {
    local input="$1"

    # Must match NN-NN-NN or NNNN-NN-NN or NN-NN-NNNN
    if [[ ! "$input" =~ ^[0-9]{2,4}-[0-9]{2}-[0-9]{2,4}$ ]]; then
        return 1
    fi

    local p1 p2 p3 year month day
    IFS='-' read -r p1 p2 p3 <<< "$input"

    if [[ ${#p1} -eq 4 ]]; then
        # yyyy-mm-dd
        year="$p1"; month="$p2"; day="$p3"
    elif [[ ${#p3} -eq 4 ]]; then
        # dd-mm-yyyy
        day="$p1"; month="$p2"; year="$p3"
    elif [[ ${#p1} -eq 2 && ${#p3} -eq 2 ]]; then
        # Ambiguous: yy-mm-dd vs dd-mm-yy
        # Heuristic: if first part > 31, it can't be a day → treat as yy-mm-dd
        if [[ $((10#$p1)) -gt 31 ]]; then
            year="20${p1}"; month="$p2"; day="$p3"
        else
            day="$p1"; month="$p2"; year="20${p3}"
        fi
    else
        return 1
    fi

    # Validate the resulting date
    local normalized="${year}-${month}-${day}"
    if date -j -f "%Y-%m-%d" "$normalized" "+%Y-%m-%d" &>/dev/null 2>&1; then
        echo "$normalized"
        return 0
    fi
    return 1
}

is_date() {
    normalize_date "$1" >/dev/null 2>&1
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

is_random() {
    [[ "$1" == "random" || "$1" == "RANDOM" || "$1" == "Random" ]]
}

# Generate a random number between 1 and 50
random_count() {
    echo $(( RANDOM % 50 + 1 ))
}

is_count_arg() {
    is_number "$1" || is_random "$1"
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

        GIT_AUTHOR_DATE="$timestamp" GIT_COMMITTER_DATE="$timestamp" \
        git -C "$REPO_DIR" commit --allow-empty \
            -m "contrib: ${target_date} [${i}/${count}]" \
            --date="$timestamp" \
            --quiet
    done

    echo -e "  ${GREEN}✓${NC} ${display_date}  →  ${BOLD}${count}${NC} commit(s)"
}

# ── Parse Flags ─────────────────────────────────────────────────────────────
SKIP_CONFIRM=false
while [[ $# -gt 0 && "$1" =~ ^- && ! $(normalize_date "$1" 2>/dev/null) ]]; do
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

# Normalize all date arguments upfront
if is_date "$1"; then
    ARG1=$(normalize_date "$1")
else
    ARG1="$1"
fi

if is_date "$1" && [[ "${2:-}" == "--week" ]]; then
    # ── Mode 3: Week mode ──────────────────────────────────────────────
    TARGET_DATE="$ARG1"
    WEEK_COUNT="${3:-1}"
    USE_RANDOM=false

    if is_random "$WEEK_COUNT"; then
        USE_RANDOM=true
    elif ! is_number "$WEEK_COUNT"; then
        echo -e "${RED}Error:${NC} commit count must be a number or 'random', got '${WEEK_COUNT}'"
        exit 1
    fi

    start_epoch=$(date -j -f "%Y-%m-%d" "$TARGET_DATE" "+%s")
    end_epoch=$((start_epoch + 6 * 86400))  # 7 days inclusive
    END_DATE=$(date -j -f "%s" "$end_epoch" "+%Y-%m-%d")

    echo ""
    if [[ "$USE_RANDOM" == true ]]; then
        echo -e "${BOLD}${CYAN}🟢 Generating random(1–50) commit(s)/day for 7 days: ${TARGET_DATE} → ${END_DATE}${NC}"
        echo -e "   ${YELLOW}7 days × random(1–50) commits each${NC}"
    else
        total_commits=$((7 * WEEK_COUNT))
        echo -e "${BOLD}${CYAN}🟢 Generating ${WEEK_COUNT} commit(s)/day for 7 days: ${TARGET_DATE} → ${END_DATE}${NC}"
        echo -e "   ${YELLOW}7 days × ${WEEK_COUNT} commits = ${total_commits} total commits${NC}"
    fi
    echo -e "   ${YELLOW}Target: $REPO_DIR${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────${NC}"

    confirm

    current_epoch=$start_epoch
    while [[ $current_epoch -le $end_epoch ]]; do
        current_date=$(date -j -f "%s" "$current_epoch" "+%Y-%m-%d")
        if [[ "$USE_RANDOM" == true ]]; then
            day_count=$(random_count)
        else
            day_count="$WEEK_COUNT"
        fi
        make_commits "$current_date" "$day_count"
        current_epoch=$((current_epoch + 86400))
    done

elif is_date "$1" && is_count_arg "$2"; then
    # ── Mode 1: Single date ─────────────────────────────────────────────
    TARGET_DATE="$ARG1"

    if is_random "$2"; then
        COMMIT_COUNT=$(random_count)
        COUNT_LABEL="random → ${COMMIT_COUNT}"
    else
        COMMIT_COUNT="$2"
        COUNT_LABEL="$COMMIT_COUNT"
    fi

    echo ""
    echo -e "${BOLD}${CYAN}🟢 Generating ${COUNT_LABEL} commits on ${TARGET_DATE}${NC}"
    echo -e "   ${YELLOW}Target: $REPO_DIR${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────${NC}"

    confirm

    make_commits "$TARGET_DATE" "$COMMIT_COUNT"

elif is_date "$1" && is_date "$2"; then
    # ── Mode 2: Date range ──────────────────────────────────────────────
    START_DATE="$ARG1"
    END_DATE=$(normalize_date "$2")
    COMMITS_PER_DAY="${3:-1}"
    USE_RANDOM=false

    if is_random "$COMMITS_PER_DAY"; then
        USE_RANDOM=true
    elif ! is_number "$COMMITS_PER_DAY"; then
        echo -e "${RED}Error:${NC} commits-per-day must be a number or 'random', got '${COMMITS_PER_DAY}'"
        exit 1
    fi

    start_epoch=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
    end_epoch=$(date -j -f "%Y-%m-%d" "$END_DATE" "+%s")

    if [[ $start_epoch -gt $end_epoch ]]; then
        echo -e "${RED}Error:${NC} start date must be before end date"
        exit 1
    fi

    total_days=$(( (end_epoch - start_epoch) / 86400 + 1 ))

    echo ""
    if [[ "$USE_RANDOM" == true ]]; then
        echo -e "${BOLD}${CYAN}🟢 Generating random(1–50) commit(s)/day from ${START_DATE} → ${END_DATE}${NC}"
        echo -e "   ${YELLOW}${total_days} days × random(1–50) commits each${NC}"
    else
        total_commits=$((total_days * COMMITS_PER_DAY))
        echo -e "${BOLD}${CYAN}🟢 Generating ${COMMITS_PER_DAY} commit(s)/day from ${START_DATE} → ${END_DATE}${NC}"
        echo -e "   ${YELLOW}${total_days} days × ${COMMITS_PER_DAY} commits = ${total_commits} total commits${NC}"
    fi
    echo -e "   ${YELLOW}Target: $REPO_DIR${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────${NC}"

    confirm

    current_epoch=$start_epoch

    while [[ $current_epoch -le $end_epoch ]]; do
        current_date=$(date -j -f "%s" "$current_epoch" "+%Y-%m-%d")
        if [[ "$USE_RANDOM" == true ]]; then
            day_count=$(random_count)
        else
            day_count="$COMMITS_PER_DAY"
        fi
        make_commits "$current_date" "$day_count"
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
git -C "$REPO_DIR" push -u origin main --quiet 2>/dev/null || git -C "$REPO_DIR" push origin main --quiet

echo -e "${GREEN}${BOLD}✅ Done!${NC} Contributions will appear on your GitHub profile shortly."
echo ""
