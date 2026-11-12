#!/usr/bin/env bash
set -euo pipefail
bin="${1:-./build/koronos-host}"
test -x "$bin"
"$bin" --help >/dev/null
info="$("$bin" info)"
grep -q '^kernel=Linux ' <<<"$info"
grep -q '^execution=unprivileged-linux-process$' <<<"$info"
profile="$("$bin" profile)"
grep -q '^profile=linux-hosted-v1$' <<<"$profile"
grep -q '^bare_metal_kernel=false$' <<<"$profile"
out="$("$bin" run -- /usr/bin/printf 'host-bridge-ok\n')"
printf 'process-adapter-output=%q\n' "$out"
[[ "$out" == "host-bridge-ok" ]]
set +e
"$bin" run -- /usr/bin/false
rc=$?
set -e
[[ "$rc" -eq 1 ]]
set +e
"$bin" run -- /definitely/not/a/koronos-command
rc=$?
set -e
[[ "$rc" -eq 127 ]]
echo "LinuxKoronos hosted runtime smoke tests passed"
