#!/usr/bin/env bash
# check-thresholds.sh — Parse JMeter JTL CSV results, print a summary table,
# and exit non-zero if any performance threshold is violated.
#
# Usage: check-thresholds.sh <results-directory>
#
# Thresholds enforced:
#   Average response time  < 500 ms
#   p95 response time      < 1000 ms
#   Error rate             < 1%
#   Throughput             >= 10 req/s
set -euo pipefail

# ── Thresholds ─────────────────────────────────────────────────────────────────
readonly AVG_THRESHOLD_MS=500
readonly P95_THRESHOLD_MS=1000
readonly ERROR_RATE_THRESHOLD_PCT=1
readonly THROUGHPUT_THRESHOLD_RPS=10

# ── Locate JTL CSV file ────────────────────────────────────────────────────────
RESULTS_DIR="${1:?Usage: check-thresholds.sh <results-directory>}"
JTL_FILE=$(find "$RESULTS_DIR" -maxdepth 2 -name "*.csv" -print0 \
  | xargs -0 ls -t 2>/dev/null \
  | head -1)

if [[ -z "$JTL_FILE" ]]; then
  echo "ERROR: No JTL CSV file found in ${RESULTS_DIR}"
  exit 1
fi

echo "Parsing: ${JTL_FILE}"

# ── Pass 1: compute totals from JTL CSV ───────────────────────────────────────
# Expected columns: timeStamp(1), elapsed(2), ..., success(8)
read -r TOTAL ERRORS SUM_ELAPSED MIN_TS MAX_TS MAX_ELAPSED <<< "$(
  awk -F',' 'NR > 1 {
    ts = $1 + 0; e = $2 + 0; s = $8
    total++
    sum += e
    if (s == "false") errors++
    if (total == 1 || ts < min_ts) min_ts = ts
    if (total == 1 || ts > max_ts) { max_ts = ts; max_e = e }
  }
  END { print total+0, errors+0, sum+0, min_ts+0, max_ts+0, max_e+0 }' \
  "$JTL_FILE"
)"

if [[ "${TOTAL:-0}" -eq 0 ]]; then
  echo "ERROR: No samples found in ${JTL_FILE}"
  exit 1
fi

# ── Pass 2: compute p95 ────────────────────────────────────────────────────────
P95_IDX=$(( (TOTAL * 95 + 99) / 100 ))
[[ "$P95_IDX" -lt 1 ]] && P95_IDX=1
P95_MS=$(awk -F',' 'NR > 1 { print $2 + 0 }' "$JTL_FILE" | sort -n | sed -n "${P95_IDX}p")

# ── Derived metrics ────────────────────────────────────────────────────────────
AVG_MS=$(awk "BEGIN { printf \"%.0f\", ${SUM_ELAPSED} / ${TOTAL} }")
ERROR_RATE_PCT=$(awk "BEGIN { printf \"%.2f\", (${ERRORS} / ${TOTAL}) * 100 }")
DURATION_MS=$(( MAX_TS - MIN_TS + MAX_ELAPSED ))
DURATION_S=$(awk "BEGIN { printf \"%.1f\", ${DURATION_MS} / 1000 }")
THROUGHPUT=$(awk "BEGIN { d = ${DURATION_MS} / 1000; if (d > 0) printf \"%.2f\", ${TOTAL} / d; else print \"0.00\" }")

# ── Print summary table ────────────────────────────────────────────────────────
echo ""
echo "------------------------------------------------------------"
echo "         JMeter Performance Threshold Summary"
echo "------------------------------------------------------------"
printf "  Total samples : %d\n"   "$TOTAL"
printf "  Test duration : %s s\n" "$DURATION_S"
echo "------------------------------------------------------------"
printf "  %-26s %8s ms   (< %d ms)\n"       "Avg Response Time"  "$AVG_MS"         "$AVG_THRESHOLD_MS"
printf "  %-26s %8s ms   (< %d ms)\n"       "p95 Response Time"  "$P95_MS"         "$P95_THRESHOLD_MS"
printf "  %-26s %9s%%   (< %d%%)\n"         "Error Rate"         "$ERROR_RATE_PCT" "$ERROR_RATE_THRESHOLD_PCT"
printf "  %-26s %6s req/s   (>= %d req/s)\n" "Throughput"        "$THROUGHPUT"     "$THROUGHPUT_THRESHOLD_RPS"
echo "------------------------------------------------------------"
echo ""

# ── Evaluate thresholds ────────────────────────────────────────────────────────
FAILED=0

check_lt() {
  local label="$1" value="$2" threshold="$3" unit="$4"
  local result
  result=$(awk -v v="$value" -v t="$threshold" 'BEGIN { print (v < t) ? "pass" : "fail" }')
  if [[ "$result" == "fail" ]]; then
    echo "  FAIL: ${label} is ${value}${unit} (threshold: < ${threshold}${unit})"
    FAILED=1
  fi
}

check_ge() {
  local label="$1" value="$2" threshold="$3" unit="$4"
  local result
  result=$(awk -v v="$value" -v t="$threshold" 'BEGIN { print (v >= t) ? "pass" : "fail" }')
  if [[ "$result" == "fail" ]]; then
    echo "  FAIL: ${label} is ${value}${unit} (threshold: >= ${threshold}${unit})"
    FAILED=1
  fi
}

check_lt "Avg Response Time" "$AVG_MS"         "$AVG_THRESHOLD_MS"         " ms"
check_lt "p95 Response Time" "$P95_MS"         "$P95_THRESHOLD_MS"         " ms"
check_lt "Error Rate"        "$ERROR_RATE_PCT" "$ERROR_RATE_THRESHOLD_PCT" "%"
check_ge "Throughput"        "$THROUGHPUT"     "$THROUGHPUT_THRESHOLD_RPS" " req/s"

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "  All thresholds passed."
  exit 0
else
  echo "  One or more thresholds FAILED. See above for details."
  exit 1
fi
