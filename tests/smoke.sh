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

# The adapter must preserve argv boundaries and must not reinterpret shell syntax.
out="$("$bin" run -- /usr/bin/printf '%s|%s' 'two words' ';not-a-shell-command')"
[[ "$out" == 'two words|;not-a-shell-command' ]]

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

# Signal termination is propagated using the conventional 128 + signal status.
set +e
"$bin" run -- /bin/sh -c 'kill -TERM "$$"'
rc=$?
set -e
[[ "$rc" -eq 143 ]]

echo "LinuxKoronos hosted runtime smoke tests passed"
