#!/bin/bash
# diag.sh —— 只诊断，不修改任何文件。回答一个问题：这次部署到底卡在哪一步。
set -u
T=/www/wwwroot/moonarmor
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261103b"
ALT="https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/deploy-20261103b"
echo "=== 0 环境 ==="
echo "node: $(node -v 2>&1)"
echo "gunzip: $(command -v gunzip || echo 缺失)"
echo "sha256sum: $(command -v sha256sum || echo 缺失)"
echo "systemd: $(systemctl is-active moonarmor 2>/dev/null)"
echo "目录: $(test -d $T && echo 存在 || echo 缺失)"
echo
echo "=== 1 取件测试（3 路）==="
F="server__server.js.gz"
for U in "$BASE/$F?ref=main|API" "$ALT/$F|raw" "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261103b/$F|jsdelivr"; do
  URL="${U%%|*}"; NAME="${U##*|}"
  CODE=$(curl -s -o /tmp/_diag.gz -w "%{http_code}" --max-time 40 -H "Accept: application/vnd.github.raw" "$URL" || echo 000)
  SZ=$(stat -c%s /tmp/_diag.gz 2>/dev/null || echo 0)
  echo "  $NAME → HTTP $CODE  大小 $SZ"
done
echo
echo "=== 2 解压 + 期望哈希比对 ==="
gunzip -cf /tmp/_diag.gz > /tmp/_diag.js 2>/tmp/_diag.err && echo "  解压成功 $(stat -c%s /tmp/_diag.js) 字节" || { echo "  解压失败：$(cat /tmp/_diag.err)"; }
GOT=$(sha256sum /tmp/_diag.js 2>/dev/null | cut -d" " -f1)
echo "  实际 sha: $GOT"
echo "  期望 sha: 2ac9a5580d7e... (完整值见部署脚本)"
echo
echo "=== 3 语法检查（用服务器上的 node）==="
node --check /tmp/_diag.js && echo "  server.js 语法通过" || echo "  server.js 语法失败 ← 如果这行报错，就是它导致回滚"
echo
echo "=== 4 现有文件状态（确认回滚成功）==="
for f in server/server.js server/modules/cell/engine.js web/cschat-cell.html web/live-chat.js; do
  [ -f "$T/$f" ] && echo "  $f  $(stat -c%s "$T/$f") 字节  $(stat -c%y "$T/$f" | cut -d. -f1)" || echo "  $f 缺失"
done
echo
echo "=== 5 备份目录 ==="
ls -dt $T/.deploy-bak-* 2>/dev/null | head -3
rm -f /tmp/_diag.* 2>/dev/null
echo
echo "诊断完成（没有任何文件被修改）"
