#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

KUJO_BIN="${KUJO_BIN:-kujo}"

clear_runtime_outputs() {
	find tests -maxdepth 1 -name "*.out" -type f -delete
}

echo "[PARITY] Running default test runtime..."
clear_runtime_outputs
DEFAULT_UPDATE_OUT="$($KUJO_BIN test --update --runtime vm 2>&1)"
DEFAULT_OUT="$($KUJO_BIN test 2>&1)"
echo "$DEFAULT_OUT"
if ! grep -q "Passed 7/7" <<< "$DEFAULT_OUT"; then
	echo "$DEFAULT_UPDATE_OUT"
	echo "FAIL: default runtime did not report full pass set"
	exit 1
fi

echo "[PARITY] Running vm runtime..."
clear_runtime_outputs
VM_UPDATE_OUT="$($KUJO_BIN test --update --runtime vm 2>&1)"
VM_OUT="$($KUJO_BIN test --runtime vm 2>&1)"
echo "$VM_OUT"
if ! grep -q "Passed 7/7" <<< "$VM_OUT"; then
	echo "$VM_UPDATE_OUT"
	echo "FAIL: vm runtime did not report full pass set"
	exit 1
fi

if [ "${KUJO_EVAL_INCLUDE_INTERPRETER_PARITY:-0}" = "1" ]; then
	echo "[PARITY] Running interpreter runtime (advisory)..."
	clear_runtime_outputs
	INTERP_UPDATE_OUT="$($KUJO_BIN test --update --runtime interpreter 2>&1)"
	INTERP_OUT="$($KUJO_BIN test --runtime interpreter 2>&1)"
	echo "$INTERP_OUT"
	if ! grep -q "Passed 7/7" <<< "$INTERP_OUT"; then
		echo "$INTERP_UPDATE_OUT"
		echo "WARN: interpreter runtime did not report full pass set"
	fi
else
	echo "[PARITY] Skipping interpreter runtime advisory check (set KUJO_EVAL_INCLUDE_INTERPRETER_PARITY=1 to enable)"
fi

clear_runtime_outputs
echo "PASS: test runtime parity verified (default and vm both pass 7/7)"
