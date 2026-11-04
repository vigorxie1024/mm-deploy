#!/bin/bash
# deploy-20261104b.sh —— 上线三方圆桌（3 文件：server.js + 细胞页 + 子智能体）
set -u
T=/www/wwwroot/moonarmor
B=$T/.deploy-bak-$(date +%s)
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261104b"
ALT="https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/deploy-20261104b"
say(){ echo "[deploy] $*"; }
rollback(){ say "开始回滚…"
  [ -f "$B/server__server.js" ] && cp -a "$B/server__server.js" "$T/server/server.js" && say "  还原 server/server.js"
  [ -f "$B/web__cschat-cell.html" ] && cp -a "$B/web__cschat-cell.html" "$T/web/cschat-cell.html" && say "  还原 web/cschat-cell.html"
  [ -f "$B/web__live-chat.js" ] && cp -a "$B/web__live-chat.js" "$T/web/live-chat.js" && say "  还原 web/live-chat.js"
  systemctl restart moonarmor 2>/dev/null || service moonarmor restart 2>/dev/null; sleep 2; say "回滚完成："$(systemctl is-active moonarmor 2>/dev/null); }
fail(){ echo "[deploy] 失败：$*"; rollback; exit 1; }
mkdir -p "$B" || { echo "[deploy] 备份目录建不了"; exit 1; }
# 1 备份
[ -f "$T/server/server.js" ] && cp -a "$T/server/server.js" "$B/server__server.js" && say "备份 server/server.js"
[ -f "$T/web/cschat-cell.html" ] && cp -a "$T/web/cschat-cell.html" "$B/web__cschat-cell.html" && say "备份 web/cschat-cell.html"
[ -f "$T/web/live-chat.js" ] && cp -a "$T/web/live-chat.js" "$B/web__live-chat.js" && say "备份 web/live-chat.js"
# 2 取件
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__server.js.gz?ref=main" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__server.js.gz" -o /tmp/server__server.js.gz \
  || fail "取件失败 server__server.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__cschat-cell.html.gz?ref=main" -o /tmp/web__cschat-cell.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__cschat-cell.html.gz" -o /tmp/web__cschat-cell.html.gz \
  || fail "取件失败 web__cschat-cell.html.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__live-chat.js.gz?ref=main" -o /tmp/web__live-chat.js.gz \
  || curl -fsSL --max-time 90 "$ALT/web__live-chat.js.gz" -o /tmp/web__live-chat.js.gz \
  || fail "取件失败 web__live-chat.js.gz"
say "3 个文件取件完成"
# 3 校验
gunzip -cf /tmp/server__server.js.gz > /tmp/server__server.js || fail "解压失败 server__server.js.gz"
GOT=$(sha256sum /tmp/server__server.js | cut -d" " -f1); [ "$GOT" = "df304cf8d3bc89f75320cba55ab3e4c33d97e543b74dac3f8cd519532d89da18" ] || fail "sha 不符 server/server.js"
gunzip -cf /tmp/web__cschat-cell.html.gz > /tmp/web__cschat-cell.html || fail "解压失败 web__cschat-cell.html.gz"
GOT=$(sha256sum /tmp/web__cschat-cell.html | cut -d" " -f1); [ "$GOT" = "b526034e32a531e7934705d79aa42a5ee3a83fb226ee4fab902d43aa4e6781af" ] || fail "sha 不符 web/cschat-cell.html"
gunzip -cf /tmp/web__live-chat.js.gz > /tmp/web__live-chat.js || fail "解压失败 web__live-chat.js.gz"
GOT=$(sha256sum /tmp/web__live-chat.js | cut -d" " -f1); [ "$GOT" = "3dadf04f3e69169db8c4a79c27ce1f6201c0c5c25570616a88414ab5df86cd94" ] || fail "sha 不符 web/live-chat.js"
say "sha256 全部一致"
# 4 语法
node --check /tmp/server__server.js || fail "server.js 语法失败（未替换任何文件）"
say "server.js 语法通过"
# 5 落盘
mkdir -p "$(dirname "$T/server/server.js")"; install -m 644 /tmp/server__server.js "$T/server/server.js" || fail "写入失败 server/server.js"
mkdir -p "$(dirname "$T/web/cschat-cell.html")"; install -m 644 /tmp/web__cschat-cell.html "$T/web/cschat-cell.html" || fail "写入失败 web/cschat-cell.html"
mkdir -p "$(dirname "$T/web/live-chat.js")"; install -m 644 /tmp/web__live-chat.js "$T/web/live-chat.js" || fail "写入失败 web/live-chat.js"
say "3 个文件已落盘"
# 6 重启
systemctl restart moonarmor || fail '重启失败'; sleep 3
ST=$(systemctl is-active moonarmor 2>/dev/null); [ "$ST" = "active" ] || fail "服务未起来：$ST"; say "服务 active"
# 7 探活
RQ=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://moonarmor.cn/api/room/thread?since=0" || echo 000); say "圆桌接口 $RQ（期望 401，不是 404）"; [ "$RQ" = "401" ] || fail "圆桌接口未生效 $RQ"
P=$(curl -s --max-time 15 https://moonarmor.cn/cschat-cell.html | grep -c "邀请码"; true); say "门禁页 $P 处"; [ "${P:-0}" -ge 1 ] || say "⚠️ 门禁未命中（不致命）"
L=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/api/cell/memory || echo 000); say "细胞接口 $L（期望 401）"; [ "$L" = "401" ] || fail "细胞接口 $L"
say "全部完成 ✔ 备份：$B"
