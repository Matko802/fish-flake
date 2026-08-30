#!/bin/sh
DIR="$1"
mkdir -p "$DIR"
MONS=$(mmsg get all-monitors 2>/dev/null)
NAMES=$(printf '%s' "$MONS" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//g')
for n in $NAMES; do
  grim -o "$n" -t png "$DIR/ss-$n.png" 2>/dev/null
done
ALL=$(mmsg get all-clients 2>/dev/null)
CLIENTS=$(printf '%s' "$ALL" | sed 's/.*"clients":\[//; s/\]}.*//')
echo "{"
echo '  "monitors": ['
first=1
for n in $NAMES; do
  [ $first -eq 0 ] && printf ',\n'
  first=0
  mmsg get monitor "$n" 2>/dev/null
done
echo ''
echo '  ],'
echo '  "windows": ['
first=1
printf '%s' "$CLIENTS" | sed 's/},{/}\n{/g' | while IFS= read -r obj; do
  [ -z "$obj" ] && continue
  fid=$(printf '%s' "$obj" | grep -o '"foreign_toplevel_id":"[^"]*"' | sed 's/"foreign_toplevel_id":"//;s/"//g')
  appid=$(printf '%s' "$obj" | grep -o '"appid":"[^"]*"' | sed 's/"appid":"//;s/"//g')
  title=$(printf '%s' "$obj" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"//g')
  [ $first -eq 0 ] && printf ',\n'
  first=0
  printf '{"foreign_toplevel_id":"%s","appid":"%s","title":"%s"}' "$fid" "$appid" "$title"
done
echo ''
echo '  ]'
echo '}'
