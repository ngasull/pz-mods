{ pkgs, lib, ... }:
let
  MOD_FOLDERS = [
    "IconsInventory"
    "IconsInventory_ItemRarityUI"
    "IconsInventory_KnownAndCollected"
    "IconsInventory_P4HasBeenRead"
    "IconsInventory_SeedSeasonIndicator"
    "SideBySideContainers"
    "StaticBags"
  ];

  prepare = pkgs.writeShellScriptBin "pz-mod-prepare" ''
    set -e
    if [ -z "$PZ_HOST" ] ; then echo "PZ_HOST must be set"; exit 1 ; fi
    if [ $# -lt 1 ] ; then exit 1 ; fi
    name="$1"
    destdir="$PZ_HOST/Workshop/$name"
    moddir="$PZ_MODS/$name"

    if [ ! -e "$destdir" ] ; then
      mkdir -p "$destdir/Contents/mods"
      linkcommand="New-Item -Path C:\\Users\\$WSL_HOST_USER\\Zomboid\\Workshop\\$name\\Contents\\mods\\$name -ItemType SymbolicLink -Value C:\\Users\\$WSL_HOST_USER\\Zomboid\\mods\\$name"
      echo "# Now run as admin powershell: (already in clipboard)"
      echo "$linkcommand"
      echo -n "$linkcommand" | clip.exe
    fi

    rsync -rtDu "$moddir/Workshop/" "$destdir/"
  '';

  publish = pkgs.writeShellScriptBin "pz-mod-publish" ''
    set -e
    if [ $# -lt 1 ] ; then exit 1 ; fi
    name="$1"
    tmpdir="$(mktemp -d -p "$(pwd)" --suffix=publish-mod)"
    moddir="$PZ_MODS/$name"

    if [ ! -f "$moddir/Workshop/preview.png" ] ; then
      echo Missing $preview
      exit 1
    fi

    source "$moddir/Workshop/workshop.ini"
    if [ -z "$id" -o -z "$title" ] ; then
      echo Missing info in workshop.ini
      exit 1
    fi
    if [ $id -eq 0 ] ; then
      echo "Won't use steamcmd to first publish mod (can't set tags)"
      exit 1
    fi

    description="$(sed 's/\([\\\\"]\)/\\\1/g' "$moddir/Workshop/''${name}_en.bbcode")"
    changes="$(sed 's/\([\\\\"]\)/\\\1/g' "$moddir/Workshop/changes.txt")"
    mkdir -p "$moddir/Workshop/changelog"

    mkdir -p "$tmpdir/Contents/mods"
    # Copy. Symlinks aren't followed
    cp -r "$moddir/mod" "$tmpdir/Contents/mods/$name"

    vdf="$tmpdir/workshop_item.vdf"
    echo -ne '"workshopitem"
    {
    \t"appid"\t\t"108600"
    \t"publishedfileid"\t\t"'$id'"
    \t"contentfolder"\t\t"'$tmpdir'/Contents"
    \t"visibility"\t\t"0"
    \t"previewfile"\t\t"'"$moddir/Workshop/preview.png"'"
    \t"title"\t\t"'$title'"
    \t"description"\t\t"'"$description"'"
    \t"changenote"\t\t"'"$changes"'"
    }' > "$vdf"

    ${pkgs.steamcmd}/bin/steamcmd +login blint6 +workshop_build_item "$vdf" +quit

    rm -rf "$tmpdir"
    mv "$moddir/Workshop/changes.txt" "$moddir/Workshop/changelog/changes_$(date +%Y%m%d-%H%M).txt"
    touch "$moddir/Workshop/changes.txt.next"
  '';

  sync-host-folder = pkgs.writeShellScriptBin "sync-host-folder" ''
    if [ -z "$PZ_HOST" ] ; then echo "PZ_HOST must be set"; exit 1 ; fi
    if [ $# -lt 1 ] ; then exit 1 ; fi
    DIR="$1"
    shift
    exec rsync -rtDu --delete $@ "$PZ_MODS/$DIR/mod/" "$PZ_HOST/mods/$DIR/"
  '';

  sync-host = pkgs.writeShellScriptBin "sync-host" ''
    set -e
    ${lib.strings.join "\n" (
      map (folder: "${sync-host-folder}/bin/sync-host-folder ${folder} &") MOD_FOLDERS
    )}
    wait
  '';

  # Credit: https://stackoverflow.com/questions/28195821/how-can-i-interrupt-or-debounce-an-inotifywait-loop#answer-69945839
  sync-host-watcher = pkgs.writeShellScriptBin "sync-host-watcher" ''
    if [ -z "$PZ_HOST" ] ; then echo "PZ_HOST must be set"; exit 1 ; fi
    if [ $# -lt 1 ] ; then exit 1 ; fi
    ${sync-host-folder}/bin/sync-host-folder "$1"
    while read -r path; do
      timeout 0.5 cat | wc -l > /dev/null
      ${sync-host-folder}/bin/sync-host-folder "$1"
    done < <(
      ${pkgs.inotify-tools}/bin/inotifywait -q -m -r -e modify,create,close_write,delete,move --format "%w%f" $PZ_MODS/$1/mod/
    )
  '';

  sync-host-watch-all = pkgs.writeShellScriptBin "sync-host-watch-all" ''
    if [ -z "$PZ_HOST" ] ; then echo "PZ_HOST must be set"; exit 1 ; fi
    pid=
    ${lib.strings.join "\n" (
      map (folder: ''
        ${sync-host-watcher}/bin/sync-host-watcher ${folder} &
        pid="$pid $!"
      '') MOD_FOLDERS
    )}
    trap "kill $pid 2>/dev/null || true" INT TERM
    wait
  '';

  hxw = pkgs.writeShellScriptBin "hx" ''
    set -e
    if [[ -n "$PZ_HOST" && -n "$PZ_MODS" && ! -e "$PZ_MODS/.helix/watcher.pid" ]]; then
      mkdir -p "$PZ_MODS/.helix"
      ${sync-host-watch-all}/bin/sync-host-watch-all &
      pid=$!
      pidfile="$PZ_MODS/.helix/watchall.pid"
      echo $pid > "$pidfile"
      trap "rm -f '$pidfile'; kill $pid 2>/dev/null || true" EXIT INT TERM
    fi
    /etc/profiles/per-user/$USER/bin/hx "$@"
  '';
in
[
  hxw
  prepare
  publish
  sync-host
  sync-host-watcher
  sync-host-watch-all
]
