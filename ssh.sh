#!/bin/bash
# ============================================================
#  GitHub SSH Diagnostics Script
# ============================================================

SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

section() { echo -e "\n$SEP\n🔍  $1\n$SEP"; }

section "1. SYSTEM INFO"
echo "Date     : $(date)"
echo "Hostname : $(hostname)"
echo "User     : $(whoami)"
echo "OS       : $(uname -a)"

section "2. SSH KEY CHECK (~/.ssh)"
ls -la ~/.ssh/ 2>/dev/null || echo "  [!] ~/.ssh directory not found"
echo ""
echo "  Public keys found:"
ls ~/.ssh/*.pub 2>/dev/null || echo "  [!] No .pub keys found"

section "3. SSH CONFIG FILE"
if [ -f ~/.ssh/config ]; then
    cat ~/.ssh/config
else
    echo "  [!] No ~/.ssh/config file found"
fi

section "4. SSH AGENT STATUS"
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "  [!] SSH_AUTH_SOCK not set — ssh-agent may not be running"
else
    echo "  SSH_AUTH_SOCK = $SSH_AUTH_SOCK"
    echo ""
    echo "  Keys loaded in agent:"
    ssh-add -l 2>/dev/null || echo "  [!] No keys loaded or agent not accessible"
fi

section "5. DNS RESOLUTION — github.com"
echo "  nslookup:"
nslookup github.com 2>/dev/null || echo "  [!] nslookup failed"
echo ""
echo "  dig (short):"
dig +short github.com 2>/dev/null || echo "  [!] dig not available"

section "6. PING TEST — github.com"
ping -c 3 -W 3 github.com 2>/dev/null || echo "  [!] Ping failed (may be blocked by firewall)"

section "7. PORT CONNECTIVITY TESTS"
echo "  Testing port 22 (standard SSH):"
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/github.com/22' 2>/dev/null \
    && echo "  ✅  Port 22 is OPEN" \
    || echo "  ❌  Port 22 is BLOCKED or unreachable"

echo ""
echo "  Testing port 443 (HTTPS fallback for SSH):"
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/ssh.github.com/443' 2>/dev/null \
    && echo "  ✅  Port 443 (ssh.github.com) is OPEN" \
    || echo "  ❌  Port 443 (ssh.github.com) is BLOCKED or unreachable"

echo ""
echo "  Testing port 80 (basic internet check):"
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/github.com/80' 2>/dev/null \
    && echo "  ✅  Port 80 is OPEN (internet works)" \
    || echo "  ❌  Port 80 also blocked — possible network issue"

section "8. TRACEROUTE to github.com (first 15 hops)"
traceroute -m 15 github.com 2>/dev/null || \
    tracepath -m 15 github.com 2>/dev/null || \
    echo "  [!] traceroute/tracepath not available"

section "9. SSH VERBOSE CONNECTION TEST (port 22)"
echo "  Running: ssh -vT -o ConnectTimeout=8 git@github.com"
echo ""
ssh -vT -o ConnectTimeout=8 git@github.com 2>&1 | head -60 || true

section "10. SSH VERBOSE CONNECTION TEST via port 443 (fallback)"
echo "  Running: ssh -vT -p 443 -o ConnectTimeout=8 git@ssh.github.com"
echo ""
ssh -vT -p 443 -o ConnectTimeout=8 git@ssh.github.com 2>&1 | head -60 || true

section "11. ENVIRONMENT — PROXY SETTINGS"
echo "  http_proxy  : ${http_proxy:-not set}"
echo "  https_proxy : ${https_proxy:-not set}"
echo "  HTTP_PROXY  : ${HTTP_PROXY:-not set}"
echo "  HTTPS_PROXY : ${HTTPS_PROXY:-not set}"
echo "  no_proxy    : ${no_proxy:-not set}"

section "12. NETWORK INTERFACES"
ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "  [!] ip/ifconfig not available"

section "13. DEFAULT ROUTE / GATEWAY"
ip route show 2>/dev/null || route -n 2>/dev/null || echo "  [!] route info unavailable"

section "14. FIREWALL (iptables — may need sudo)"
sudo iptables -L OUTPUT -n 2>/dev/null | grep -E "(22|443|DROP|REJECT)" \
    || echo "  [!] Cannot read iptables (try running script with sudo)"

section "✅  DIAGNOSTICS COMPLETE"
echo "  Paste the full output above to Claude for analysis."
echo ""
