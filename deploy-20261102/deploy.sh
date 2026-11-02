#!/bin/bash
# deploy-20261102.sh —— 月亮盔甲「一步到位」部署：备份 → 校验 → 落盘 → 语法检查 → 重启 → 探活 → 失败自动回滚
# 用法：curl -fsSL <本脚本地址> | bash
# 安全：只写 $T/web 与 $T/server 下指定文件；失败自动还原并重启旧版。
set -u
T=/www/wwwroot/moonarmor
B=$T/.deploy-bak-$(date +%s)
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261102"
ALT="https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/deploy-20261102"
say(){ echo "[deploy] $*"; }
fail(){ echo "[deploy] 失败：$*"; rollback; exit 1; }
mkdir -p "$B" || { echo '[deploy] 建备份目录失败'; exit 1; }

rollback(){
  say '开始回滚…'
  [ -f "$B/web__auth-doctor.html" ] && cp -a "$B/web__auth-doctor.html" "$T/web/auth-doctor.html" && say "  还原 web/auth-doctor.html"
  [ -f "$B/server__archive-schema.js" ] && cp -a "$B/server__archive-schema.js" "$T/server/archive-schema.js" && say "  还原 server/archive-schema.js"
  [ -f "$B/server__archive-engine.js" ] && cp -a "$B/server__archive-engine.js" "$T/server/archive-engine.js" && say "  还原 server/archive-engine.js"
  [ -f "$B/server__server.js" ] && cp -a "$B/server__server.js" "$T/server/server.js" && say "  还原 server/server.js"
  [ -f "$B/server__modules__slim-matching__governance.js" ] && cp -a "$B/server__modules__slim-matching__governance.js" "$T/server/modules/slim-matching/governance.js" && say "  还原 server/modules/slim-matching/governance.js"
  systemctl restart moonarmor 2>/dev/null || service moonarmor restart 2>/dev/null
  sleep 2; say '回滚完成，服务状态：'$(systemctl is-active moonarmor 2>/dev/null)
}


# —— 回滚函数：还原备份并重启 ——

# —— 1. 备份 ——
[ -f "$T/web/auth-doctor.html" ] && cp -a "$T/web/auth-doctor.html" "$B/web__auth-doctor.html"; say '备份 web/auth-doctor.html'
[ -f "$T/server/archive-schema.js" ] && cp -a "$T/server/archive-schema.js" "$B/server__archive-schema.js"; say '备份 server/archive-schema.js'
[ -f "$T/server/archive-engine.js" ] && cp -a "$T/server/archive-engine.js" "$B/server__archive-engine.js"; say '备份 server/archive-engine.js'
[ -f "$T/server/server.js" ] && cp -a "$T/server/server.js" "$B/server__server.js"; say '备份 server/server.js'
[ -f "$T/server/modules/slim-matching/governance.js" ] && cp -a "$T/server/modules/slim-matching/governance.js" "$B/server__modules__slim-matching__governance.js"; say '备份 server/modules/slim-matching/governance.js'

# —— 2. 下载（三路回退：API → raw → jsDelivr）——
say '取件 web__auth-doctor.html.gz'
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__auth-doctor.html.gz?ref=main" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || fail '取件失败 web__auth-doctor.html.gz'
say '取件 server__archive-schema.js.gz'
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-schema.js.gz?ref=main" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || fail '取件失败 server__archive-schema.js.gz'
say '取件 server__archive-engine.js.gz'
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-engine.js.gz?ref=main" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || fail '取件失败 server__archive-engine.js.gz'
say '取件 server__server.js.gz'
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__server.js.gz?ref=main" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__server.js.gz" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102/server__server.js.gz" -o /tmp/server__server.js.gz \
  || fail '取件失败 server__server.js.gz'
say '取件 server__modules__slim-matching__governance.js.gz'
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__slim-matching__governance.js.gz?ref=main" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || fail '取件失败 server__modules__slim-matching__governance.js.gz'

# —— 3. 解压并校验 sha256 ——
gunzip -cf /tmp/web__auth-doctor.html.gz > /tmp/web__auth-doctor.html || fail '解压失败 web__auth-doctor.html.gz'
GOT=$(sha256sum /tmp/web__auth-doctor.html | cut -d" " -f1)
[ "$GOT" = "d77457fb09f02b94b90762fce96821a31f631ea2b3df7185c6830b2cb24f4a22" ] || fail 'sha 不符 web/auth-doctor.html（期望 d77457fb09f0… 实际 ${GOT:0:12}…）'
say '校验通过 web/auth-doctor.html  5291B'
gunzip -cf /tmp/server__archive-schema.js.gz > /tmp/server__archive-schema.js || fail '解压失败 server__archive-schema.js.gz'
GOT=$(sha256sum /tmp/server__archive-schema.js | cut -d" " -f1)
[ "$GOT" = "25824fc61322c54011ab41e06f9a263afc2178f3482b3746e4c251a5549bd16d" ] || fail 'sha 不符 server/archive-schema.js（期望 25824fc61322… 实际 ${GOT:0:12}…）'
say '校验通过 server/archive-schema.js  9521B'
gunzip -cf /tmp/server__archive-engine.js.gz > /tmp/server__archive-engine.js || fail '解压失败 server__archive-engine.js.gz'
GOT=$(sha256sum /tmp/server__archive-engine.js | cut -d" " -f1)
[ "$GOT" = "000594375f3164ef195cc11cbe08ff5a41cf970f1978b965dd5728e9d375e827" ] || fail 'sha 不符 server/archive-engine.js（期望 000594375f31… 实际 ${GOT:0:12}…）'
say '校验通过 server/archive-engine.js  34543B'
gunzip -cf /tmp/server__server.js.gz > /tmp/server__server.js || fail '解压失败 server__server.js.gz'
GOT=$(sha256sum /tmp/server__server.js | cut -d" " -f1)
[ "$GOT" = "2dcab9d19c905073ec27f633facaf17f5d8fa091130866188b897cde192d9d3b" ] || fail 'sha 不符 server/server.js（期望 2dcab9d19c90… 实际 ${GOT:0:12}…）'
say '校验通过 server/server.js  290314B'
gunzip -cf /tmp/server__modules__slim-matching__governance.js.gz > /tmp/server__modules__slim-matching__governance.js || fail '解压失败 server__modules__slim-matching__governance.js.gz'
GOT=$(sha256sum /tmp/server__modules__slim-matching__governance.js | cut -d" " -f1)
[ "$GOT" = "cf4ef469d776e37d850a6ac87a5411a3885e21972c23889d81bbaf67992aa3a4" ] || fail 'sha 不符 server/modules/slim-matching/governance.js（期望 cf4ef469d776… 实际 ${GOT:0:12}…）'
say '校验通过 server/modules/slim-matching/governance.js  10674B'

# —— 4. 服务端文件先做语法检查（未通过就不替换）——
node --check /tmp/server__archive-schema.js || fail '语法检查失败 server/archive-schema.js（尚未替换任何文件）'
say '语法通过 server/archive-schema.js'
node --check /tmp/server__archive-engine.js || fail '语法检查失败 server/archive-engine.js（尚未替换任何文件）'
say '语法通过 server/archive-engine.js'
node --check /tmp/server__server.js || fail '语法检查失败 server/server.js（尚未替换任何文件）'
say '语法通过 server/server.js'
node --check /tmp/server__modules__slim-matching__governance.js || fail '语法检查失败 server/modules/slim-matching/governance.js（尚未替换任何文件）'
say '语法通过 server/modules/slim-matching/governance.js'

# —— 5. 落盘 ——
mkdir -p "$(dirname "$T/web/auth-doctor.html")"
install -m 644 /tmp/web__auth-doctor.html "$T/web/auth-doctor.html" || fail '写入失败 web/auth-doctor.html'
say '已写入 web/auth-doctor.html'
mkdir -p "$(dirname "$T/server/archive-schema.js")"
install -m 644 /tmp/server__archive-schema.js "$T/server/archive-schema.js" || fail '写入失败 server/archive-schema.js'
say '已写入 server/archive-schema.js'
mkdir -p "$(dirname "$T/server/archive-engine.js")"
install -m 644 /tmp/server__archive-engine.js "$T/server/archive-engine.js" || fail '写入失败 server/archive-engine.js'
say '已写入 server/archive-engine.js'
mkdir -p "$(dirname "$T/server/server.js")"
install -m 644 /tmp/server__server.js "$T/server/server.js" || fail '写入失败 server/server.js'
say '已写入 server/server.js'
mkdir -p "$(dirname "$T/server/modules/slim-matching/governance.js")"
install -m 644 /tmp/server__modules__slim-matching__governance.js "$T/server/modules/slim-matching/governance.js" || fail '写入失败 server/modules/slim-matching/governance.js'
say '已写入 server/modules/slim-matching/governance.js'

# —— 6. 重启 ——
systemctl restart moonarmor || fail '重启失败'
sleep 3
ST=$(systemctl is-active moonarmor 2>/dev/null)
[ "$ST" = "active" ] || fail "服务未起来：$ST"
say '服务状态：active'

# —— 7. 探活（这是真正的验收：新接口从 404 变成 401 才算成功）——
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:8000/api/archive/by-frequency?frequency=fr-health || echo 000)
[ "$CODE" = "000" ] && CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/api/archive/by-frequency?frequency=fr-health || echo 000)
say "/api/archive/by-frequency 返回 $CODE（部署前是 404，部署后应为 401 未登录）"
[ "$CODE" = "404" ] && fail "新接口仍是 404，可能没落盘"
DOC=$(curl -s --max-time 15 https://moonarmor.cn/auth-doctor.html | grep -c "probe(" ; true)
say "/auth-doctor.html 的 probe( 次数：$DOC（目标 9）"
[ "$DOC" -lt 9 ] && fail "医生页仍是旧版（probe( 只有 $DOC 次）"

rm -f /tmp/*.gz /tmp/*.gz.out 2>/dev/null
say "全部完成。备份留在：$B"
say "如需回滚：cp -a $B/* $T/ 后 systemctl restart moonarmor"
