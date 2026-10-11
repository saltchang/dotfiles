#!/bin/bash
# Make the host fcitx5 GTK3 IM module loadable inside Steam's runtime container
# (steamrt3c ships glib 2.66 and no fcitx module). See README.md next to this file.
#
#   build.sh          rebuild into $OUT; a build that fails the symbol check is discarded
#                     and the previous one is kept
#   build.sh --check  exit 0 only if $OUT matches the installed fcitx5-gtk and every symbol
#                     it needs exists in the installed Steam runtime
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
OUT=${STEAM_FCITX5_OUT:-$HOME/.local/share/steam-fcitx5}
host_mod=/usr/lib/gtk-3.0/3.0.0/immodules/im-fcitx5.so
host_lib=/usr/lib/libFcitx5GClient.so.2

# Resolve a soname to the copy the container will load. pressure-vessel takes glibc and the
# GCC runtime from whichever side is newer (the host, on Arch); everything else comes from
# the runtime when it ships it (only versioned file names exist on disk), else the host.
resolve_lib() {
    local rt=$1 so=$2 f
    case $so in libc.so.* | libm.so.* | libstdc++.so.* | libgcc_s.so.*) echo "/usr/lib/$so"; return ;; esac
    for f in "$rt/$so" "$rt/$so".*; do [ -e "$f" ] && { echo "$f"; return; }; done
    if [ -e "/usr/lib/$so" ]; then echo "/usr/lib/$so"; fi
}

# The GModule version check is disabled, so a symbol missing here would only crash Steam
# when first called. Refuse such a build instead.
check_symbols() {
    local dir=$1 rt need have missing so lib
    rt=$(ls -d "$HOME"/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/steamrt*_platform_*/files/lib/x86_64-linux-gnu 2>/dev/null | sort -V | tail -1 || true)
    [ -n "$rt" ] || { echo "steam-fcitx5: Steam runtime not found" >&2; return 1; }
    need=$(nm -D --undefined-only "$dir/im-fcitx5.so" "$dir/libFcitx5GClient.so.2" |
        awk '$1 == "U" { sub(/@.*/, "", $2); print $2 }' | sort -u)
    have=$({
        nm -D --defined-only "$dir/libglibshim.so" "$dir/libFcitx5GClient.so.2"
        for so in $(readelf -d "$dir/im-fcitx5.so" "$dir/libFcitx5GClient.so.2" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | sort -u); do
            lib=$(resolve_lib "$rt" "$so")
            if [ -n "$lib" ]; then nm -D --defined-only "$lib"; fi
        done
    } | awk 'NF >= 3 { sub(/@.*/, "", $3); print $3 }' | sort -u)
    missing=$(comm -23 <(echo "$need") <(echo "$have"))
    [ -z "$missing" ] || { echo "steam-fcitx5: missing in Steam runtime (add to glib-shim.c?):" $missing >&2; return 1; }
}

if [ "${1:-}" = --check ]; then
    [ -f "$OUT/immodules.cache" ] && sha256sum --status -c "$OUT/source.sha256" && check_symbols "$OUT"
    exit
fi

mkdir -p "$(dirname "$OUT")"
tmp=$(mktemp -d "$OUT.new.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

gcc -shared -fPIC -O2 -o "$tmp/libglibshim.so" "$src/glib-shim.c" -lglib-2.0
cp "$host_mod" "$host_lib" "$tmp/"
# Hide the GModule version check (it demands glib >= build version); same-length rename keeps the ELF intact.
LC_ALL=C sed -i 's/g_module_check_init/g_module_check_inix/' "$tmp/im-fcitx5.so"
for f in im-fcitx5.so libFcitx5GClient.so.2; do
    patchelf --set-rpath '$ORIGIN' --add-needed libglibshim.so "$tmp/$f"
done
check_symbols "$tmp"

cat >"$tmp/immodules.cache" <<EOF
"$OUT/im-fcitx5.so"
"fcitx" "Fcitx5 (Flexible Input Method Framework5)" "fcitx5" "/usr/share/locale" "ja:ko:zh:*"
"fcitx5" "Fcitx5 (Flexible Input Method Framework5)" "fcitx5" "/usr/share/locale" "ja:ko:zh:*"
EOF
sha256sum "$host_mod" "$host_lib" >"$tmp/source.sha256"

# A running Steam keeps its mapped copy of the old files, so swapping the directory is safe.
rm -rf "$OUT.old"
[ -d "$OUT" ] && mv "$OUT" "$OUT.old"
mv "$tmp" "$OUT"
rm -rf "$OUT.old"
echo "steam-fcitx5: built $OUT"
