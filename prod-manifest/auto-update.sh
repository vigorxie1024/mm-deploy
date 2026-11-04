#!/bin/bash
# auto-update.sh v2 —— 10 秒级自更新
# 变快的关键：轮询用 raw.githubusercontent.com（不限流），不是 GitHub API（匿名 60 次/小时）
# 探测文件只有一行版本号（ver.txt，几十字节），确认有新版本后才拉完整载荷。
set -u
T=/www/wwwroot/moonarmor
DEP=$T/.deploy
LOG=$DEP/auto-update.log
VERF=$DEP/version.txt
RAW=https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/prod-manifest
JSD=https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/prod-manifest
API=https://api.github.com/repos/vigorxie1024/mm-deploy/contents/prod-manifest
say(){ echo "[$(date '+%F %T')] $*" >> "$LOG"; }

mkdir -p "$DEP"
# ① 只取一行版本号（三路回退，raw 优先）
RV=$(curl -fsSL --max-time 8 "$RAW/ver.txt" 2>/dev/null | tr -d '\r\n ')
[ -z "$RV" ] && RV=$(curl -fsSL --max-time 8 "$JSD/ver.txt" 2>/dev/null | tr -d '\r\n ')
[ -z "$RV" ] && RV=$(curl -fsSL --max-time 10 -H "Accept: application/vnd.github.raw" "$API/ver.txt?ref=main" 2>/dev/null | tr -d '\r\n ')
[ -z "$RV" ] && { say "取 ver.txt 失败（本轮跳过）"; exit 0; }
LV=$(cat "$VERF" 2>/dev/null || echo none)
[ "$RV" = "$LV" ] && exit 0
say "发现新版本：$LV → $RV"

# ② 取完整 manifest
MJ=$(curl -fsSL --max-time 15 "$RAW/version.json" 2>/dev/null)
[ -z "$MJ" ] && MJ=$(curl -fsSL --max-time 15 "$JSD/version.json" 2>/dev/null)
[ -z "$MJ" ] && MJ=$(curl -fsSL --max-time 20 -H "Accept: application/vnd.github.raw" "$API/version.json?ref=main" 2>/dev/null)
[ -z "$MJ" ] && { say "取 version.json 失败，本轮跳过"; exit 0; }

B=$DEP/bak-$(date +%s); mkdir -p "$B"
echo "$MJ" | python3 -c '
import sys,json
j=json.load(sys.stdin)
for f in j.get("files",[]):
    print(f["file"]+"|"+f["obj"]+"|"+f["sha"])
' > /tmp/au.list 2>/dev/null || { say "解析 manifest 失败"; exit 0; }

fail=0
while IFS='|' read -r local obj sha; do
  [ -z "$local" ] && continue
  ok=0
  for base in "$RAW" "$JSD"; do
    curl -fsSL --max-time 60 "$base/$obj" -o /tmp/au.gz 2>/dev/null && { ok=1; break; }
  done
  [ "$ok" = "0" ] && curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "$API/$obj?ref=main" -o /tmp/au.gz 2>/dev/null && ok=1
  [ "$ok" = "0" ] && { say "取件失败 $local"; fail=1; break; }

  case "$local" in *.js) TMP=/tmp/au-check.js ;; *.html) TMP=/tmp/au-check.html ;; *.sh) TMP=/tmp/au-check.sh ;; *) TMP=/tmp/au-check.bin ;; esac
  gunzip -cf /tmp/au.gz > "$TMP" 2>/dev/null || { say "解压失败 $local"; fail=1; break; }
  got=$(sha256sum "$TMP" | cut -d' ' -f1)
  [ "$got" != "$sha" ] && { say "sha 不符 $local"; fail=1; break; }
  case "$local" in *.js) node --check "$TMP" 2>/dev/null || { say "语法失败 $local"; fail=1; break; } ;; esac
  [ -f "$T/$local" ] && cp -a "$T/$local" "$B/$(echo $local | tr '/' '_')"
  mkdir -p "$(dirname "$T/$local")"
  install -m 644 "$TMP" "$T/$local" || { say "写入失败 $local"; fail=1; break; }
  [ "$local" = ".deploy/auto-update.sh" ] && chmod +x "$T/$local"
  say "已更新 $local"
done < /tmp/au.list

rollback(){
  say "开始回滚"
  for f in "$B"/*; do [ -f "$f" ] || continue
    rel=$(basename "$f" | tr '_' '/'); cp -a "$f" "$T/$rel" 2>/dev/null; done
  systemctl restart moonarmor 2>/dev/null; sleep 2
  say "回滚完成："$(systemctl is-active moonarmor 2>/dev/null)
}
[ "$fail" != "0" ] && { rollback; exit 2; }

systemctl restart moonarmor || { rollback; exit 3; }
sleep 2
ST=$(systemctl is-active moonarmor 2>/dev/null)
[ "$ST" != "active" ] && { say "服务未起来 $ST"; rollback; exit 4; }
echo "$RV" > "$VERF"
say "更新成功：版本 $RV，服务 active"
