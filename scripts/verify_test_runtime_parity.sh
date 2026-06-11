#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

KUJO_BIN="${KUJO_BIN:-kujo}"

echo "[PARITY] Running default test runtime..."
DEFAULT_OUT="$($KUJO_BIN test 2>&1)"
echo "$DEFAULT_OUT"
if ! echo "$DEFAULT_OUT" | grep -q "Passed 7/7"; then
	echo "FAIL: default runtime did not report full pass set"
	exit 1
fi

echo "[PARITY] Running vm runtime..."
VM_OUT="$($KUJO_BIN test --runtime vm 2>&1)"
echo "$VM_OUT"
if ! echo "$VM_OUT" | grep -q "Passed 7/7"; then
	echo "FAIL: vm runtime did not report full pass set"
	exit 1
fi

if [ "${KUJO_EVAL_INCLUDE_INTERPRETER_PARITY:-0}" = "1" ]; then
	echo "[PARITY] Running interpreter runtime (advisory)..."
	INTERP_OUT="$($KUJO_BIN test --runtime interpreter 2>&1)"
	echo "$INTERP_OUT"
	if ! echo "$INTERP_OUT" | grep -q "Passed 7/7"; then
		echo "WARN: interpreter runtime did not report full pass set"
	fi
else
	echo "[PARITY] Skipping interpreter runtime advisory check (set KUJO_EVAL_INCLUDE_INTERPRETER_PARITY=1 to enable)"
fi

echo "PASS: test runtime parity verified (default and vm both pass 7/7)"
