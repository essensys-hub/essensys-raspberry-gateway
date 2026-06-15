#!/usr/bin/env bash
# Validate outbound HTTPS connectivity from Essensys gateway to OVH hub (mon.essensys.fr).
# Usage: ./scripts/test-wan-https-ovh.sh [hub_url]
set -euo pipefail

HUB_URL="${1:-https://mon.essensys.fr}"
HUB_HOST="${HUB_URL#https://}"
HUB_HOST="${HUB_HOST#http://}"
HUB_HOST="${HUB_HOST%%/*}"

PASS=0
FAIL=0

ok() { echo "  OK: $*"; PASS=$((PASS + 1)); }
ko() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "=== Essensys WAN HTTPS prerequisite (hub: ${HUB_URL}) ==="

# P0 DNS
if IP=$(dig +short "${HUB_HOST}" 2>/dev/null | head -1) && [[ -n "${IP}" ]]; then
  ok "DNS ${HUB_HOST} -> ${IP}"
else
  ko "DNS resolution failed for ${HUB_HOST}"
fi

# P3 reject plain HTTP hub URL in config
if [[ "${HUB_URL}" == http://* ]]; then
  ko "hub_url must use HTTPS, got ${HUB_URL}"
else
  ok "hub_url uses HTTPS scheme"
fi

# P1 TLS
HTTP_CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "${HUB_URL}/" 2>/dev/null || echo "000")
if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "301" || "${HTTP_CODE}" == "302" ]]; then
  ok "HTTPS GET ${HUB_URL}/ -> ${HTTP_CODE}"
else
  ko "HTTPS GET ${HUB_URL}/ -> ${HTTP_CODE}"
fi

# P2 certificate subject
if curl -sS -I --max-time 15 "${HUB_URL}/" 2>&1 | grep -qi "HTTP/"; then
  ok "TLS handshake completed"
else
  ko "TLS handshake failed"
fi

# P3 HTTP should redirect or fail (agent must not use http://)
HTTP_PLAIN="http://${HUB_HOST}/"
HTTP_PLAIN_CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 "${HTTP_PLAIN}" 2>/dev/null || echo "000")
if [[ "${HTTP_PLAIN_CODE}" == "301" || "${HTTP_PLAIN_CODE}" == "302" ]]; then
  ok "Plain HTTP redirects (${HTTP_PLAIN_CODE}) — agent must still use HTTPS only"
elif [[ "${HTTP_PLAIN_CODE}" == "000" ]]; then
  ok "Plain HTTP unreachable — acceptable"
else
  ko "Plain HTTP returns ${HTTP_PLAIN_CODE} without redirect — verify agent never uses http://${HUB_HOST}"
fi

# P4 gateway API stub (401 without token is success)
GW_CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -X POST "${HUB_URL}/api/gateway/heartbeat" 2>/dev/null || echo "000")
if [[ "${GW_CODE}" == "401" || "${GW_CODE}" == "404" || "${GW_CODE}" == "200" ]]; then
  ok "POST /api/gateway/heartbeat -> ${GW_CODE} (401 expected before portal deploy)"
else
  ko "POST /api/gateway/heartbeat -> ${GW_CODE}"
fi

# P5 route via eth0 if present
if command -v ip >/dev/null 2>&1 && [[ -n "${IP:-}" ]]; then
  ROUTE_DEV=$(ip route get "${IP}" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
  if [[ -n "${ROUTE_DEV}" ]]; then
    if [[ "${ROUTE_DEV}" == eth1 ]]; then
      ko "Route to OVH uses eth1 (${ROUTE_DEV}) — expected eth0 for WAN egress"
    else
      ok "Route to OVH uses ${ROUTE_DEV}"
    fi
  else
    ok "Could not determine egress device (non-Linux or no route)"
  fi
fi

echo "=== Summary: ${PASS} passed, ${FAIL} failed ==="
if [[ "${FAIL}" -gt 0 ]]; then
  exit 1
fi
exit 0
