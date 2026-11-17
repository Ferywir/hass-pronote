#!/usr/bin/env bash
# Smoke test of the integration: every module compiles, and imports against
# Home Assistant and the requirements declared in the manifest. It catches a
# bad merge (syntax error, lost import, name removed on one side), not a
# behaviour change.
#
# Usage: smoke-test.sh [repository root, default .]
set -euo pipefail

root=$(cd "${1:-.}" && pwd)
manifest="$root/custom_components/pronote/manifest.json"

python -m compileall -q "$root/custom_components"

mapfile -t requirements < <(jq -r '.requirements[]?' "$manifest")
python -m pip install --quiet --disable-pip-version-check homeassistant "${requirements[@]}"

cd "$root"
python - <<'PY'
import importlib
import pkgutil

import custom_components.pronote as integration

failed = []
for module in pkgutil.iter_modules(integration.__path__):
    name = f"custom_components.pronote.{module.name}"
    try:
        importlib.import_module(name)
        print(f"ok   {name}")
    except Exception as ex:  # noqa: BLE001
        failed.append(name)
        print(f"FAIL {name}: {type(ex).__name__}: {ex}")

if failed:
    raise SystemExit(f"{len(failed)} module(s) failed to import")
PY
