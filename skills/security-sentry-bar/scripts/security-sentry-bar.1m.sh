#!/usr/bin/env bash
# <swiftbar.title>Security Sentry Bar</swiftbar.title>
# <swiftbar.version>1.0.0</swiftbar.version>
# <swiftbar.author>codex-goated-skills</swiftbar.author>
# <swiftbar.desc>Local-first macOS security posture monitor for connections, ports, agents, processes, and recent file changes.</swiftbar.desc>
# <swiftbar.refresh>60s</swiftbar.refresh>

set -u

PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

MODE="${1:-menu}"
GREEN="#30D158"
YELLOW="#FFD60A"
RED="#FF453A"
BLUE="#64D2FF"
GRAY="#8E8E93"
WARNINGS=0
DANGERS=0
NETWORK_COUNT=0
LISTEN_COUNT=0
LAUNCH_AGENT_COUNT=0
RECENT_FILE_COUNT=0
CONNECTION_LIMIT="${SECURITY_SENTRY_CONNECTION_LIMIT:-40}"
RECENT_LIMIT="${SECURITY_SENTRY_RECENT_LIMIT:-25}"
RECENT_MAXDEPTH="${SECURITY_SENTRY_RECENT_MAXDEPTH:-3}"
REVERSE_DNS="${SECURITY_SENTRY_REVERSE_DNS:-0}"
HOSTNAME_RESOLVE_LIMIT="${SECURITY_SENTRY_HOSTNAME_LIMIT:-8}"
HOSTNAME_LOOKUPS=0

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/security-sentry.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

swiftbar_text() {
  printf '%s' "$*" | sed 's/|/¦/g'
}

print_line() {
  printf '%s\n' "$*"
}

have_tool() {
  command -v "$1" >/dev/null 2>&1
}

safe_date() {
  date "+%Y-%m-%d %H:%M:%S"
}

mtime_epoch() {
  stat -f %m "$1" 2>/dev/null || printf '0'
}

display_path() {
  local path="$1"
  if [[ "$path" == "$HOME"* ]]; then
    printf '~%s' "${path#"$HOME"}"
  else
    printf '%s' "$path"
  fi
}

ip_to_int() {
  local ip="$1" a b c d
  IFS=. read -r a b c d <<EOF
$ip
EOF
  case "$a$b$c$d" in
    *[!0-9]*|'') return 1 ;;
  esac
  for octet in "$a" "$b" "$c" "$d"; do
    if (( octet < 0 || octet > 255 )); then
      return 1
    fi
  done
  printf '%u\n' $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

cidr_contains() {
  local ip="$1" cidr="$2" base prefix ip_int base_int mask
  base="${cidr%/*}"
  prefix="${cidr#*/}"
  [[ "$base" != "$cidr" ]] || return 1
  case "$prefix" in
    *[!0-9]*|'') return 1 ;;
  esac
  if (( prefix < 0 || prefix > 32 )); then
    return 1
  fi
  ip_int="$(ip_to_int "$ip")" || return 1
  base_int="$(ip_to_int "$base")" || return 1
  if (( prefix == 0 )); then
    mask=0
  else
    mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
  fi
  (( (ip_int & mask) == (base_int & mask) ))
}

user_suspicious_cidrs() {
  if [[ -n "${SECURITY_SENTRY_SUSPICIOUS_CIDRS:-}" ]]; then
    printf '%s\n' $SECURITY_SENTRY_SUSPICIOUS_CIDRS
  fi
  if [[ -f "$HOME/.security-sentry-ranges" ]]; then
    sed 's/#.*//' "$HOME/.security-sentry-ranges" | awk 'NF {print $1}'
  fi
}

reserved_cidrs() {
  cat <<'EOF'
0.0.0.0/8
100.64.0.0/10
169.254.0.0/16
192.0.2.0/24
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
EOF
}

classify_ip() {
  local ip="$1" cidr
  [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  while IFS= read -r cidr; do
    [[ -n "$cidr" ]] || continue
    if cidr_contains "$ip" "$cidr"; then
      printf 'danger|watchlist %s' "$cidr"
      return 0
    fi
  done < <(user_suspicious_cidrs)

  while IFS= read -r cidr; do
    [[ -n "$cidr" ]] || continue
    if cidr_contains "$ip" "$cidr"; then
      printf 'warning|reserved/bogon %s' "$cidr"
      return 0
    fi
  done < <(reserved_cidrs)

  return 1
}

resolve_hostname() {
  local ip="$1" hostname="" cached=""
  [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    printf 'unresolved'
    return
  }
  if [[ -f "$tmp_dir/host.cache" ]]; then
    cached="$(awk -F '|' -v ip="$ip" '$1 == ip {print $2; exit}' "$tmp_dir/host.cache")"
    if [[ -n "$cached" ]]; then
      printf '%s' "$cached"
      return
    fi
  fi
  if (( HOSTNAME_LOOKUPS >= HOSTNAME_RESOLVE_LIMIT )); then
    printf 'unresolved'
    return
  fi
  HOSTNAME_LOOKUPS=$((HOSTNAME_LOOKUPS + 1))
  if have_tool dscacheutil; then
    hostname="$(dscacheutil -q host -a ip_address "$ip" 2>/dev/null | awk '/^name:/ {print $2; exit}')"
  fi
  if [[ -z "$hostname" && "$REVERSE_DNS" == "1" ]] && have_tool host; then
    hostname="$(host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $5; exit}' | sed 's/\.$//')"
  fi
  [[ -n "$hostname" ]] || hostname="unresolved"
  printf '%s|%s\n' "$ip" "$hostname" >> "$tmp_dir/host.cache"
  printf '%s' "$hostname"
}

remote_from_lsof_name() {
  local name="$1" remote
  remote="${name#*->}"
  [[ "$remote" != "$name" ]] || return 1
  remote="${remote%% *}"
  remote="${remote//[\[\]]/}"
  printf '%s' "$remote"
}

ip_from_endpoint() {
  local endpoint="$1"
  printf '%s' "${endpoint%:*}"
}

port_from_endpoint() {
  local endpoint="$1"
  printf '%s' "${endpoint##*:}"
}

severity_prefix() {
  case "$1" in
    danger) printf '⚠️' ;;
    warning) printf '🟡' ;;
    *) printf '✅' ;;
  esac
}

severity_color() {
  case "$1" in
    danger) printf '%s' "$RED" ;;
    warning) printf '%s' "$YELLOW" ;;
    *) printf '%s' "$GREEN" ;;
  esac
}

note_warning() {
  WARNINGS=$((WARNINGS + 1))
}

note_danger() {
  DANGERS=$((DANGERS + 1))
}

known_listener() {
  case "$1" in
    AirPlayXPCHelper|ControlCenter|Dropbox|Docker|Finder|Google|GoogleSoftwareUpdateDaemon|rapportd|sharingd|Spotify|syncthing|tailscaled|UniversalControl|WiFiAgent)
      return 0
      ;;
    com.docker*|com.apple*|mDNSResponder|sshd)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_unusual_path() {
  local path="$1"
  case "$path" in
    "$HOME/.local"*|/tmp/*|/private/tmp/*|/var/tmp/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

collect_network_connections() {
  print_line "Network Connections"
  if ! have_tool lsof; then
    note_warning
    print_line "🟡 lsof is not available, connection scan skipped | color=$YELLOW"
    return
  fi

  local raw_file="$tmp_dir/connections.raw"
  lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR > 1 {name=""; for (i=9; i<=NF; i++) name=name $i " "; print $1 "|" $2 "|" name}' > "$raw_file"
  NETWORK_COUNT="$(wc -l < "$raw_file" | tr -d ' ')"
  print_line "Total established connections: $NETWORK_COUNT | color=$BLUE"

  if [[ "$NETWORK_COUNT" -eq 0 ]]; then
    print_line "✅ No established TCP connections found | color=$GREEN"
    return
  fi

  local shown=0 command pid name remote ip port host severity reason classification class_sev class_reason prefix color label
  while IFS='|' read -r command pid name; do
    [[ -n "$name" ]] || continue
    remote="$(remote_from_lsof_name "$name" 2>/dev/null || true)"
    [[ -n "$remote" ]] || continue
    ip="$(ip_from_endpoint "$remote")"
    port="$(port_from_endpoint "$remote")"
    host="$(resolve_hostname "$ip")"
    severity="safe"
    reason="443/80"

    if [[ "$port" != "443" && "$port" != "80" ]]; then
      severity="warning"
      reason="non-web port $port"
    fi

    classification="$(classify_ip "$ip" 2>/dev/null || true)"
    if [[ -n "$classification" ]]; then
      class_sev="${classification%%|*}"
      class_reason="${classification#*|}"
      if [[ "$class_sev" == "danger" ]]; then
        severity="danger"
        reason="$class_reason"
      elif [[ "$severity" != "danger" ]]; then
        severity="warning"
        reason="$class_reason"
      fi
    fi

    case "$severity" in
      danger) note_danger ;;
      warning) note_warning ;;
    esac

    prefix="$(severity_prefix "$severity")"
    color="$(severity_color "$severity")"
    label="$(swiftbar_text "$prefix $command[$pid] -> $ip:$port ($host) - $reason")"
    print_line "$label | color=$color"
    shown=$((shown + 1))
    if (( shown >= CONNECTION_LIMIT )); then
      break
    fi
  done < "$raw_file"

  if (( NETWORK_COUNT > shown )); then
    print_line "… $((NETWORK_COUNT - shown)) more connections hidden; raise SECURITY_SENTRY_CONNECTION_LIMIT to show more | color=$GRAY"
  fi
}

collect_listening_ports() {
  print_line "Listening Ports"
  if ! have_tool lsof; then
    note_warning
    print_line "🟡 lsof is not available, listening-port scan skipped | color=$YELLOW"
    return
  fi

  local raw_file="$tmp_dir/listeners.raw"
  lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR > 1 {name=""; for (i=9; i<=NF; i++) name=name $i " "; print $1 "|" $2 "|" name}' > "$raw_file"
  LISTEN_COUNT="$(wc -l < "$raw_file" | tr -d ' ')"
  print_line "Total listening sockets: $LISTEN_COUNT | color=$BLUE"

  if [[ "$LISTEN_COUNT" -eq 0 ]]; then
    print_line "✅ No listening TCP ports found | color=$GREEN"
    return
  fi

  local command pid name endpoint port severity reason prefix color
  while IFS='|' read -r command pid name; do
    endpoint="$(printf '%s' "$name" | awk '{print $2}' | sed 's/[\[\]]//g')"
    port="$(port_from_endpoint "$endpoint")"
    severity="safe"
    reason="expected or privileged"

    if [[ "$port" =~ ^[0-9]+$ ]] && (( port > 1024 )); then
      if known_listener "$command"; then
        reason="known listener"
      else
        severity="warning"
        reason="unexpected high port"
      fi
    fi

    [[ "$severity" == "warning" ]] && note_warning
    prefix="$(severity_prefix "$severity")"
    color="$(severity_color "$severity")"
    print_line "$(swiftbar_text "$prefix $command[$pid] listening on $endpoint - $reason") | color=$color"
  done < "$raw_file"
}

collect_launch_agents() {
  print_line "Launch Agents"
  local now path modified age pretty any=0
  now="$(date +%s)"
  for dir in "$HOME/Library/LaunchAgents" "/Library/LaunchAgents"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r path; do
      any=1
      LAUNCH_AGENT_COUNT=$((LAUNCH_AGENT_COUNT + 1))
      modified="$(mtime_epoch "$path")"
      age=$((now - modified))
      pretty="$(display_path "$path")"
      if (( age <= 86400 )); then
        note_warning
        print_line "$(swiftbar_text "🟡 $pretty - changed in last 24h") | color=$YELLOW"
      else
        print_line "$(swiftbar_text "✅ $pretty") | color=$GREEN"
      fi
    done < <(find "$dir" -maxdepth 1 -type f -name '*.plist' -print 2>/dev/null | sort)
  done

  if [[ "$any" -eq 0 ]]; then
    print_line "✅ No LaunchAgents found in checked locations | color=$GREEN"
  else
    print_line "Total LaunchAgent plists: $LAUNCH_AGENT_COUNT | color=$BLUE"
  fi
}

render_process_row() {
  local pid="$1" cpu="$2" mem="$3" command="$4" path severity reason prefix color
  path="$command"
  severity="safe"
  reason="normal path"
  if is_unusual_path "$path"; then
    severity="danger"
    reason="unusual executable path"
    note_danger
  fi
  prefix="$(severity_prefix "$severity")"
  color="$(severity_color "$severity")"
  print_line "$(swiftbar_text "$prefix pid $pid cpu $cpu% mem $mem% - $command - $reason") | color=$color"
  if [[ "$severity" == "danger" ]]; then
    print_line "$(swiftbar_text "  path: $(display_path "$path")") | color=$RED"
  fi
}

collect_processes() {
  print_line "Running Processes"
  if ! have_tool ps; then
    note_warning
    print_line "🟡 ps is not available, process scan skipped | color=$YELLOW"
    return
  fi

  print_line "Top CPU | color=$BLUE"
  while read -r pid cpu mem command _rest; do
    [[ -n "${pid:-}" ]] || continue
    render_process_row "$pid" "$cpu" "$mem" "$command"
  done < <(ps -axo pid=,pcpu=,pmem=,command= -r 2>/dev/null | head -n 10)

  print_line "Top Memory | color=$BLUE"
  while read -r pid cpu mem command _rest; do
    [[ -n "${pid:-}" ]] || continue
    render_process_row "$pid" "$cpu" "$mem" "$command"
  done < <(ps -axo pid=,pcpu=,pmem=,command= 2>/dev/null | sort -k3 -nr | head -n 10)
}

collect_recent_files() {
  print_line "Recent File Changes"
  local file shown=0 pretty
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    RECENT_FILE_COUNT=$((RECENT_FILE_COUNT + 1))
    pretty="$(display_path "$file")"
    if [[ "$file" == "$HOME/Library/LaunchAgents/"* || "$file" == /tmp/* || "$file" == /private/tmp/* || "$file" == /var/tmp/* ]]; then
      note_warning
      print_line "$(swiftbar_text "🟡 $pretty") | color=$YELLOW"
    else
      print_line "$(swiftbar_text "✅ $pretty") | color=$GREEN"
    fi
    shown=$((shown + 1))
    if (( shown >= RECENT_LIMIT )); then
      break
    fi
  done < <(recent_file_candidates)

  if [[ "$RECENT_FILE_COUNT" -eq 0 ]]; then
    print_line "✅ No recent files found within scan limits | color=$GREEN"
  elif (( RECENT_FILE_COUNT >= RECENT_LIMIT )); then
    print_line "… more recent files may exist; raise SECURITY_SENTRY_RECENT_LIMIT to show more | color=$GRAY"
  fi
}

recent_file_candidates() {
  if have_tool mdfind; then
    mdfind -onlyin "$HOME" 'kMDItemFSContentChangeDate >= $time.now(-3600)' 2>/dev/null |
      grep -Ev '/(\.cache|\.git|node_modules|DerivedData|\.venv|vendor|Library/Caches|\.Trash)(/|$)' |
      sort
    return
  fi

  find "$HOME" \
    -maxdepth "$RECENT_MAXDEPTH" \
    \( -path "$HOME/.cache" -o -path "$HOME/.git" -o -path "$HOME/.Trash" -o -path "$HOME/Library/Caches" -o -name node_modules -o -name .git -o -name DerivedData -o -name .venv -o -name vendor \) -prune \
    -o -type f -mmin -60 -print 2>/dev/null | sort
}

collect_all() {
  collect_network_connections > "$tmp_dir/network.menu"
  collect_listening_ports > "$tmp_dir/ports.menu"
  collect_launch_agents > "$tmp_dir/agents.menu"
  collect_processes > "$tmp_dir/processes.menu"
  collect_recent_files > "$tmp_dir/recent.menu"
}

render_menu() {
  collect_all

  local label color sfimage
  if (( DANGERS > 0 )); then
    label="⚠️ Security $DANGERS"
    color="$RED"
    sfimage="exclamationmark.shield.fill"
  elif (( WARNINGS > 0 )); then
    label="🟡 Security $WARNINGS"
    color="$YELLOW"
    sfimage="shield.lefthalf.filled"
  else
    label="✅ Security"
    color="$GREEN"
    sfimage="checkmark.shield.fill"
  fi

  print_line "$label | color=$color sfimage=$sfimage"
  print_line "---"
  print_line "Security Sentry Bar | color=$BLUE"
  print_line "Last scan: $(safe_date) | color=$GRAY"
  print_line "Warnings: $WARNINGS  Dangers: $DANGERS | color=$color"
  print_line "Run Full Scan | bash=$0 param1=full-scan terminal=true refresh=true"
  print_line "Refresh Now | refresh=true"
  print_line "---"
  cat "$tmp_dir/network.menu"
  print_line "---"
  cat "$tmp_dir/ports.menu"
  print_line "---"
  cat "$tmp_dir/agents.menu"
  print_line "---"
  cat "$tmp_dir/processes.menu"
  print_line "---"
  cat "$tmp_dir/recent.menu"
  print_line "---"
  print_line "Configure suspicious CIDRs in ~/.security-sentry-ranges | color=$GRAY"
}

render_full_scan() {
  collect_all
  cat <<EOF
Security Sentry Bar full scan
Scanned: $(safe_date)

Summary
- Established connections: $NETWORK_COUNT
- Listening sockets: $LISTEN_COUNT
- LaunchAgent plists: $LAUNCH_AGENT_COUNT
- Recent file rows shown: $RECENT_FILE_COUNT
- Warnings: $WARNINGS
- Dangers: $DANGERS

Notes
- Non-80/443 established connections are warnings by design.
- User-supplied suspicious CIDRs are dangers.
- Reserved or bogon remote ranges are warnings.
- This scan is local-first and does not fetch a threat feed.

EOF
  sed 's/ | color=.*$//' "$tmp_dir/network.menu"
  printf '\n'
  sed 's/ | color=.*$//' "$tmp_dir/ports.menu"
  printf '\n'
  sed 's/ | color=.*$//' "$tmp_dir/agents.menu"
  printf '\n'
  sed 's/ | color=.*$//' "$tmp_dir/processes.menu"
  printf '\n'
  sed 's/ | color=.*$//' "$tmp_dir/recent.menu"
}

case "$MODE" in
  full-scan|scan|full)
    render_full_scan
    ;;
  menu|"")
    render_menu
    ;;
  *)
    printf 'Unknown mode: %s\n' "$MODE" >&2
    exit 2
    ;;
esac
