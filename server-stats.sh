#!/usr/bin/env bash
# =============================================================================
# server-stats.sh — Basic Server Performance Stats
# Compatible with any Linux distribution
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
bar() {                          # bar <used_pct>
  local pct=$1 filled=$(( $1 / 5 )) empty=$(( 20 - $1 / 5 ))
  local colour=$GREEN
  (( pct >= 80 )) && colour=$RED || (( pct >= 60 )) && colour=$YELLOW
  printf "${colour}["
  printf '%0.s█' $(seq 1 $filled 2>/dev/null) 2>/dev/null || true
  printf '%0.s░' $(seq 1 $empty  2>/dev/null) 2>/dev/null || true
  printf "]${RESET} ${BOLD}%d%%${RESET}" "$pct"
}

section() { echo -e "\n${CYAN}${BOLD}── $* ─────────────────────────────────────────${RESET}"; }
kv()      { printf "  ${DIM}%-28s${RESET} %s\n" "$1" "$2"; }

# ── Header ────────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗      ███████╗████████╗ █████╗ ████████╗███████╗"
echo "  ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗     ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝"
echo "  ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝     ███████╗   ██║   ███████║   ██║   ███████╗"
echo "  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗     ╚════██║   ██║   ██╔══██║   ██║   ╚════██║"
echo "  ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║     ███████║   ██║   ██║  ██║   ██║   ███████║"
echo "  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝"
echo -e "${RESET}"
printf "  ${DIM}Generated: %s   Host: %s${RESET}\n" "$(date '+%F %T %Z')" "$(hostname -f 2>/dev/null || hostname)"

# ═══════════════════════════════════════════════════════════════════════════════
# 1. SYSTEM OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
section "SYSTEM OVERVIEW"

OS="Unknown"
if   [[ -f /etc/os-release ]];   then OS=$(. /etc/os-release && echo "$PRETTY_NAME")
elif command -v lsb_release &>/dev/null; then OS=$(lsb_release -ds)
elif [[ -f /etc/redhat-release ]]; then OS=$(cat /etc/redhat-release)
fi
kv "OS:" "$OS"
kv "Kernel:" "$(uname -r)"
kv "Architecture:" "$(uname -m)"
kv "Hostname:" "$(hostname -f 2>/dev/null || hostname)"
kv "Uptime:" "$(uptime -p 2>/dev/null || uptime | sed 's/.*up /up /' | cut -d, -f1-2)"

# Load average
read -r l1 l5 l15 _ < /proc/loadavg
CPUS=$(nproc)
kv "CPU Cores:" "$CPUS"
kv "Load Average (1/5/15m):" "${l1}  ${l5}  ${l15}"

# ═══════════════════════════════════════════════════════════════════════════════
# 2. CPU USAGE
# ═══════════════════════════════════════════════════════════════════════════════
section "CPU USAGE"

# Sample /proc/stat over 1 second for an accurate idle delta
cpu_line_1=$(grep '^cpu ' /proc/stat)
sleep 1
cpu_line_2=$(grep '^cpu ' /proc/stat)

read -r _ u1 n1 s1 i1 w1 _ <<< "$cpu_line_1"
read -r _ u2 n2 s2 i2 w2 _ <<< "$cpu_line_2"

total1=$(( u1+n1+s1+i1+w1 ))
total2=$(( u2+n2+s2+i2+w2 ))
idle_delta=$(( i2 - i1 ))
total_delta=$(( total2 - total1 ))
(( total_delta == 0 )) && total_delta=1
cpu_used=$(( (total_delta - idle_delta) * 100 / total_delta ))
cpu_idle=$(( 100 - cpu_used ))

echo -e "  Total Usage   $(bar $cpu_used)"
kv "  Used:"  "${cpu_used}%"
kv "  Idle:"  "${cpu_idle}%"

# Per-core snapshot (optional enrichment)
if command -v mpstat &>/dev/null; then
  echo -e "  ${DIM}(per-core via mpstat)${RESET}"
  mpstat -P ALL 1 1 2>/dev/null | awk '/^[0-9]/ && $3!="CPU" {
    printf "    Core %-4s  Usr: %5s%%  Sys: %5s%%  Idle: %5s%%\n", $3,$4,$6,$13}' | head -n "$CPUS"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 3. MEMORY USAGE
# ═══════════════════════════════════════════════════════════════════════════════
section "MEMORY USAGE"

mem_total=$(grep MemTotal  /proc/meminfo | awk '{print $2}')
mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
mem_used=$(( mem_total - mem_avail ))
mem_pct=$(( mem_used * 100 / mem_total ))

to_human() { awk -v kb="$1" 'BEGIN{
  if(kb>=1048576) printf "%.2f GiB", kb/1048576
  else if(kb>=1024) printf "%.1f MiB", kb/1024
  else printf "%d KiB", kb }'; }

echo -e "  RAM Usage     $(bar $mem_pct)"
kv "  Total:"     "$(to_human $mem_total)"
kv "  Used:"      "$(to_human $mem_used)"
kv "  Available:" "$(to_human $mem_avail)"

# Swap
swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
swap_free=$(grep  SwapFree  /proc/meminfo | awk '{print $2}')
swap_used=$(( swap_total - swap_free ))

if (( swap_total > 0 )); then
  swap_pct=$(( swap_used * 100 / swap_total ))
  echo ""
  echo -e "  Swap Usage    $(bar $swap_pct)"
  kv "  Total:"  "$(to_human $swap_total)"
  kv "  Used:"   "$(to_human $swap_used)"
  kv "  Free:"   "$(to_human $swap_free)"
else
  kv "  Swap:" "not configured"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 4. DISK USAGE
# ═══════════════════════════════════════════════════════════════════════════════
section "DISK USAGE"

printf "  ${BOLD}%-22s %8s %8s %8s  %-22s${RESET}\n" "Filesystem" "Size" "Used" "Avail" "Usage"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^/dev/' \
  | sort -k6 \
  | while IFS= read -r line; do
      src=$(echo "$line" | awk '{print $1}')
      sz=$(echo "$line"  | awk '{print $2}')
      us=$(echo "$line"  | awk '{print $3}')
      av=$(echo "$line"  | awk '{print $4}')
      pc=$(echo "$line"  | awk '{print $5}' | tr -d '%')
      mp=$(echo "$line"  | awk '{print $6}')
      colour=$GREEN
      (( pc >= 90 )) && colour=$RED || (( pc >= 70 )) && colour=$YELLOW
      printf "  %-22s %8s %8s %8s  ${colour}%d%%${RESET} (%s)\n" \
        "$(basename "$src")" "$sz" "$us" "$av" "$pc" "$mp"
    done

# ═══════════════════════════════════════════════════════════════════════════════
# 5. TOP 5 PROCESSES — CPU
# ═══════════════════════════════════════════════════════════════════════════════
section "TOP 5 PROCESSES BY CPU"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "%CPU" "%MEM" "COMMAND"
ps aux --sort=-%cpu 2>/dev/null \
  | awk 'NR>1 {printf "  %-8s %-12s %6s %6s  %s\n", $2,$1,$3,$4,$11}' \
  | head -5

# ═══════════════════════════════════════════════════════════════════════════════
# 6. TOP 5 PROCESSES — MEMORY
# ═══════════════════════════════════════════════════════════════════════════════
section "TOP 5 PROCESSES BY MEMORY"

printf "  ${BOLD}%-8s %-12s %6s %6s  %s${RESET}\n" "PID" "USER" "%MEM" "%CPU" "COMMAND"
ps aux --sort=-%mem 2>/dev/null \
  | awk 'NR>1 {printf "  %-8s %-12s %6s %6s  %s\n", $2,$1,$4,$3,$11}' \
  | head -5

# ═══════════════════════════════════════════════════════════════════════════════
# 7. NETWORK INTERFACES
# ═══════════════════════════════════════════════════════════════════════════════
section "NETWORK INTERFACES"

if command -v ip &>/dev/null; then
  ip -brief addr show 2>/dev/null \
    | awk '{printf "  %-14s %-12s %s\n", $1, $2, $3}' \
    | grep -v '^  lo '
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 8. LOGGED-IN USERS
# ═══════════════════════════════════════════════════════════════════════════════
section "LOGGED-IN USERS"

who_out=$(who 2>/dev/null)
if [[ -n "$who_out" ]]; then
  printf "  ${BOLD}%-12s %-10s %-18s %s${RESET}\n" "USER" "TTY" "FROM" "LOGIN TIME"
  echo "$who_out" | awk '{printf "  %-12s %-10s %-18s %s %s\n", $1,$2,$5,$3,$4}'
else
  echo "  No users currently logged in."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 9. FAILED LOGIN ATTEMPTS  (last 24h)
# ═══════════════════════════════════════════════════════════════════════════════
section "FAILED LOGIN ATTEMPTS (last 24h)"

failed=0
if command -v journalctl &>/dev/null && journalctl --no-pager -q -S "24 hours ago" \
     -u ssh -u sshd 2>/dev/null | grep -qi "failed\|invalid"; then
  failed=$(journalctl --no-pager -q -S "24 hours ago" -u ssh -u sshd 2>/dev/null \
           | grep -ic "failed\|invalid" || true)
  echo -e "  ${YELLOW}${BOLD}$failed${RESET} failed SSH attempt(s) in the last 24 hours"
elif [[ -f /var/log/auth.log ]]; then
  failed=$(grep -c "Failed password\|Invalid user" /var/log/auth.log 2>/dev/null || true)
  echo -e "  ${YELLOW}${BOLD}$failed${RESET} failed login attempt(s) in /var/log/auth.log"
elif [[ -f /var/log/secure ]]; then
  failed=$(grep -c "Failed password\|Invalid user" /var/log/secure 2>/dev/null || true)
  echo -e "  ${YELLOW}${BOLD}$failed${RESET} failed login attempt(s) in /var/log/secure"
else
  echo "  Unable to determine (no readable auth log or journald available)."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Footer
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${DIM}  ─────────────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${DIM}Script completed in ${SECONDS}s  •  Run as: $(whoami)${RESET}\n"
