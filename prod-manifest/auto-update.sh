#!/bin/bash
# auto-update.sh —— 服务器自更新（不需要任何人点按钮）
# 机制：读线上 manifest → 比对本地版本 → 有新版就取件+校验+备用+重启+探活，失败自动回滚
# 设计底线：sha256 不符绝不替换；健康检查不过自动还原；全程写日志。
set -u
T=/www/wwwroot/moonarmor
DEP=$T/.deploy
LOG=$DEP/auto-update.log
VERF=$DEP/version.txt
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/prod-manifest"
MAN="$BASE/version.json?ref=main"
say(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

mkdir -p "$DEP"
REMOTE=$(curl -fsSL --max-time 30 -H "Accept: application/vnd.github.raw" "$MAN" 2>/dev/null)
if [ -z "$REMOTE" ]; then say "拉 manifest 失败，跳过本轮"; exit 0; fi
RVER=$(echo "$REMOTE" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$RVER" ] && { say "manifest 里没有 version，跳过"; exit 0; }
LVER=$(cat "$VERF" 2>/dev/null || echo "none")
if [ "$RVER" = "$LVER" ]; then exit 0; fi
say "发现新版本：$LVER → $RVER"

B=$DEP/bak-$(date +%s); mkdir -p "$B"
python3 - "$REMOTE" > /tmp/autoupd.list <<'PY'
import sys, json
j=json.loads(sys.argv[1])
for f in j.get("files",[]):
    print(f["file"]+"|"+f["obj"]+"|"+f["sha"])
PY
ok=0; fail=0
while IFS='|' read -r local obj sha; do
  [ -z "$local" ] && continue
  url="$BASE/$obj?ref=main"
  if ! curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "$url" -o /tmp/au.gz 2>/dev/null; then
    say "取件失败 $local"; fail=1; break
  fi
  gunzip -cf /tmp/au.gz > /tmp/au.out 2>/dev/null || { say "解压失败 $local"; fail=1; break; }
  got=$(sha256sum /tmp/au.out | cut -d' ' -f1)
  if [ "$got" != "$sha" ]; then say "sha 不符 $local（期望 ${sha:0:12} 实际 ${got:0:12}）"; fail=1; break; fi
  case "$local" in *.js) node --check /tmp/au.out 2>/dev/null || { say "语法失败 $local"; fail=1; break; };; esac
  [ -f "$T/$local" ] && cp -a "$T/$local" "$B/$(echo $local | tr '/' '_')"
  mkdir -p "$(dirname "$T/$local")"
  install -m 644 /tmp/au.out "$T/$local" || { say "写入失败 $local"; fail=1; break; }
  say "已更新 $local"; ok=$((ok+1))
done < /tmp/autoupd.list

if [ "$fail" != "0" ]; then
  say "更新失败，开始回滚"
  for f in "$B"/*; do [ -f "$f" ] || continue; n=$(basename "$f"); rel=$(echo "$n" | tr '_' '/'); cp -a "$f" "$T/$rel" 2>/dev/null; done
  systemctl restart moonarmor 2>/dev/null
  say "回滚完成："$(systemctl is-active moonarmor 2>/dev/null); exit 2
fi

systemctl restart moonarmor || { say "重启失败，回滚"; exit 3; }
sleep 3
ST=$(systemctl is-active moonarmor 2>/dev/null)
if [ "$ST" != "active" ]; then
  say "服务未起来（$ST），回滚"
  for f in "$B"/*; do [ -f "$f" ] || continue; n=$(basename "$f"); rel=$(echo "$n" | tr '_' '/'); cp -a "$f" "$T/$rel" 2>/dev/null; done
  systemctl restart moonarmor; say "回滚完成："$(systemctl is-active moonarmor 2>/dev/null); exit 4
fi
echo "$RVER" > "$VERF"
say "更新成功：$ok 个文件，版本 $RVER，服务 active"
