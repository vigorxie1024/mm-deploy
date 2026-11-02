#!/bin/bash
# deploy-20261102b.sh —— 月亮盔甲一次落地 7 个文件（含 CSchat-Cell）
# 流程：备份 → 三路取件 → sha256 校验 → node --check → 落盘 → 重启 → 四项探活 → 任一步失败自动回滚
# 用法：curl -fsSL -H "Accept: application/vnd.github.raw" \
#   "https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261102b/deploy.sh?ref=main" | bash
set -u
T=/www/wwwroot/moonarmor
B=$T/.deploy-bak-$(date +%s)
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261102b"
ALT="https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/deploy-20261102b"
say(){ echo "[deploy] $*"; }

rollback(){
  say "开始回滚…"
  [ -f "$B/web__auth-doctor.html" ] && cp -a "$B/web__auth-doctor.html" "$T/web/auth-doctor.html" && say "  还原 web/auth-doctor.html"
  [ -f "$B/web__cschat-cell.html" ] && cp -a "$B/web__cschat-cell.html" "$T/web/cschat-cell.html" && say "  还原 web/cschat-cell.html"
  [ -f "$B/server__archive-schema.js" ] && cp -a "$B/server__archive-schema.js" "$T/server/archive-schema.js" && say "  还原 server/archive-schema.js"
  [ -f "$B/server__archive-engine.js" ] && cp -a "$B/server__archive-engine.js" "$T/server/archive-engine.js" && say "  还原 server/archive-engine.js"
  [ -f "$B/server__modules__cell__engine.js" ] && cp -a "$B/server__modules__cell__engine.js" "$T/server/modules/cell/engine.js" && say "  还原 server/modules/cell/engine.js"
  [ -f "$B/server__modules__slim-matching__governance.js" ] && cp -a "$B/server__modules__slim-matching__governance.js" "$T/server/modules/slim-matching/governance.js" && say "  还原 server/modules/slim-matching/governance.js"
  [ -f "$B/server__server.js" ] && cp -a "$B/server__server.js" "$T/server/server.js" && say "  还原 server/server.js"
  systemctl restart moonarmor 2>/dev/null || service moonarmor restart 2>/dev/null
  sleep 2; say "回滚完成，服务状态："$(systemctl is-active moonarmor 2>/dev/null)
}
fail(){ echo "[deploy] 失败：$*"; rollback; exit 1; }

mkdir -p "$B" || { echo "[deploy] 建备份目录失败"; exit 1; }

# —— 1 备份 ——
[ -f "$T/web/auth-doctor.html" ] && cp -a "$T/web/auth-doctor.html" "$B/web__auth-doctor.html" && say "备份 web/auth-doctor.html"
[ -f "$T/web/cschat-cell.html" ] && cp -a "$T/web/cschat-cell.html" "$B/web__cschat-cell.html" && say "备份 web/cschat-cell.html"
[ -f "$T/server/archive-schema.js" ] && cp -a "$T/server/archive-schema.js" "$B/server__archive-schema.js" && say "备份 server/archive-schema.js"
[ -f "$T/server/archive-engine.js" ] && cp -a "$T/server/archive-engine.js" "$B/server__archive-engine.js" && say "备份 server/archive-engine.js"
[ -f "$T/server/modules/cell/engine.js" ] && cp -a "$T/server/modules/cell/engine.js" "$B/server__modules__cell__engine.js" && say "备份 server/modules/cell/engine.js"
[ -f "$T/server/modules/slim-matching/governance.js" ] && cp -a "$T/server/modules/slim-matching/governance.js" "$B/server__modules__slim-matching__governance.js" && say "备份 server/modules/slim-matching/governance.js"
[ -f "$T/server/server.js" ] && cp -a "$T/server/server.js" "$B/server__server.js" && say "备份 server/server.js"

# —— 2 取件 ——
say "取件 web__auth-doctor.html.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__auth-doctor.html.gz?ref=main" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || fail "取件失败 web__auth-doctor.html.gz"
say "取件 web__cschat-cell.html.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__cschat-cell.html.gz?ref=main" -o /tmp/web__cschat-cell.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__cschat-cell.html.gz" -o /tmp/web__cschat-cell.html.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/web__cschat-cell.html.gz" -o /tmp/web__cschat-cell.html.gz \
  || fail "取件失败 web__cschat-cell.html.gz"
say "取件 server__archive-schema.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-schema.js.gz?ref=main" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || fail "取件失败 server__archive-schema.js.gz"
say "取件 server__archive-engine.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-engine.js.gz?ref=main" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || fail "取件失败 server__archive-engine.js.gz"
say "取件 server__modules__cell__engine.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__cell__engine.js.gz?ref=main" -o /tmp/server__modules__cell__engine.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__cell__engine.js.gz" -o /tmp/server__modules__cell__engine.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/server__modules__cell__engine.js.gz" -o /tmp/server__modules__cell__engine.js.gz \
  || fail "取件失败 server__modules__cell__engine.js.gz"
say "取件 server__modules__slim-matching__governance.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__slim-matching__governance.js.gz?ref=main" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || fail "取件失败 server__modules__slim-matching__governance.js.gz"
say "取件 server__server.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__server.js.gz?ref=main" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__server.js.gz" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102b/server__server.js.gz" -o /tmp/server__server.js.gz \
  || fail "取件失败 server__server.js.gz"

# —— 3 解压 + sha256 校验 ——
gunzip -cf /tmp/web__auth-doctor.html.gz > /tmp/web__auth-doctor.html || fail "解压失败 web__auth-doctor.html.gz"
GOT=$(sha256sum /tmp/web__auth-doctor.html | cut -d" " -f1)
[ "$GOT" = "d77457fb09f02b94b90762fce96821a31f631ea2b3df7185c6830b2cb24f4a22" ] || fail "sha 不符 web/auth-doctor.html（期望 d77457fb09f0… 实际 ${GOT:0:12}…）"
say "校验通过 web/auth-doctor.html"
gunzip -cf /tmp/web__cschat-cell.html.gz > /tmp/web__cschat-cell.html || fail "解压失败 web__cschat-cell.html.gz"
GOT=$(sha256sum /tmp/web__cschat-cell.html | cut -d" " -f1)
[ "$GOT" = "c0bba73d8c85332d6699bdf7fac789d3cc28565f41dd2a8df1103681394a5776" ] || fail "sha 不符 web/cschat-cell.html（期望 c0bba73d8c85… 实际 ${GOT:0:12}…）"
say "校验通过 web/cschat-cell.html"
gunzip -cf /tmp/server__archive-schema.js.gz > /tmp/server__archive-schema.js || fail "解压失败 server__archive-schema.js.gz"
GOT=$(sha256sum /tmp/server__archive-schema.js | cut -d" " -f1)
[ "$GOT" = "25824fc61322c54011ab41e06f9a263afc2178f3482b3746e4c251a5549bd16d" ] || fail "sha 不符 server/archive-schema.js（期望 25824fc61322… 实际 ${GOT:0:12}…）"
say "校验通过 server/archive-schema.js"
gunzip -cf /tmp/server__archive-engine.js.gz > /tmp/server__archive-engine.js || fail "解压失败 server__archive-engine.js.gz"
GOT=$(sha256sum /tmp/server__archive-engine.js | cut -d" " -f1)
[ "$GOT" = "000594375f3164ef195cc11cbe08ff5a41cf970f1978b965dd5728e9d375e827" ] || fail "sha 不符 server/archive-engine.js（期望 000594375f31… 实际 ${GOT:0:12}…）"
say "校验通过 server/archive-engine.js"
gunzip -cf /tmp/server__modules__cell__engine.js.gz > /tmp/server__modules__cell__engine.js || fail "解压失败 server__modules__cell__engine.js.gz"
GOT=$(sha256sum /tmp/server__modules__cell__engine.js | cut -d" " -f1)
[ "$GOT" = "fc8fe626cc5a46e65600be95ac16b4f86be7fe4397296ccfe40feace02c914d3" ] || fail "sha 不符 server/modules/cell/engine.js（期望 fc8fe626cc5a… 实际 ${GOT:0:12}…）"
say "校验通过 server/modules/cell/engine.js"
gunzip -cf /tmp/server__modules__slim-matching__governance.js.gz > /tmp/server__modules__slim-matching__governance.js || fail "解压失败 server__modules__slim-matching__governance.js.gz"
GOT=$(sha256sum /tmp/server__modules__slim-matching__governance.js | cut -d" " -f1)
[ "$GOT" = "cf4ef469d776e37d850a6ac87a5411a3885e21972c23889d81bbaf67992aa3a4" ] || fail "sha 不符 server/modules/slim-matching/governance.js（期望 cf4ef469d776… 实际 ${GOT:0:12}…）"
say "校验通过 server/modules/slim-matching/governance.js"
gunzip -cf /tmp/server__server.js.gz > /tmp/server__server.js || fail "解压失败 server__server.js.gz"
GOT=$(sha256sum /tmp/server__server.js | cut -d" " -f1)
[ "$GOT" = "d9409c6546d1b4db4f2bdda5fee8b59164827828b80259d7f33ef623fe3dc70f" ] || fail "sha 不符 server/server.js（期望 d9409c6546d1… 实际 ${GOT:0:12}…）"
say "校验通过 server/server.js"

# —— 4 服务端文件语法检查（不过就不替换）——
node --check /tmp/server__archive-schema.js || fail "语法检查失败 server/archive-schema.js（尚未替换任何文件）"
say "语法通过 server/archive-schema.js"
node --check /tmp/server__archive-engine.js || fail "语法检查失败 server/archive-engine.js（尚未替换任何文件）"
say "语法通过 server/archive-engine.js"
node --check /tmp/server__modules__cell__engine.js || fail "语法检查失败 server/modules/cell/engine.js（尚未替换任何文件）"
say "语法通过 server/modules/cell/engine.js"
node --check /tmp/server__modules__slim-matching__governance.js || fail "语法检查失败 server/modules/slim-matching/governance.js（尚未替换任何文件）"
say "语法通过 server/modules/slim-matching/governance.js"
node --check /tmp/server__server.js || fail "语法检查失败 server/server.js（尚未替换任何文件）"
say "语法通过 server/server.js"

# —— 5 落盘 ——
mkdir -p "$(dirname "$T/web/auth-doctor.html")"
install -m 644 /tmp/web__auth-doctor.html "$T/web/auth-doctor.html" || fail "写入失败 web/auth-doctor.html"
mkdir -p "$(dirname "$T/web/cschat-cell.html")"
install -m 644 /tmp/web__cschat-cell.html "$T/web/cschat-cell.html" || fail "写入失败 web/cschat-cell.html"
mkdir -p "$(dirname "$T/server/archive-schema.js")"
install -m 644 /tmp/server__archive-schema.js "$T/server/archive-schema.js" || fail "写入失败 server/archive-schema.js"
mkdir -p "$(dirname "$T/server/archive-engine.js")"
install -m 644 /tmp/server__archive-engine.js "$T/server/archive-engine.js" || fail "写入失败 server/archive-engine.js"
mkdir -p "$(dirname "$T/server/modules/cell/engine.js")"
install -m 644 /tmp/server__modules__cell__engine.js "$T/server/modules/cell/engine.js" || fail "写入失败 server/modules/cell/engine.js"
mkdir -p "$(dirname "$T/server/modules/slim-matching/governance.js")"
install -m 644 /tmp/server__modules__slim-matching__governance.js "$T/server/modules/slim-matching/governance.js" || fail "写入失败 server/modules/slim-matching/governance.js"
mkdir -p "$(dirname "$T/server/server.js")"
install -m 644 /tmp/server__server.js "$T/server/server.js" || fail "写入失败 server/server.js"
say "7 个文件已落盘"

# —— 6 重启 ——
systemctl restart moonarmor || fail '重启失败'
sleep 3
ST=$(systemctl is-active moonarmor 2>/dev/null)
[ "$ST" = "active" ] || fail "服务未起来：$ST"
say "服务 active"

# —— 7 四项探活（真正的验收）——
C1=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:8000/api/cell/state || echo 000)
say "/api/cell/state → $C1（期望 200）"
[ "$C1" = "200" ] || fail "细胞接口未生效（$C1）"
C2=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/cschat-cell.html || echo 000)
say "/cschat-cell.html → $C2（期望 200）"
[ "$C2" = "200" ] || fail "细胞页面不可访问（$C2）"
C3=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/api/archive/by-frequency?frequency=fr-health || echo 000)
say "/api/archive/by-frequency → $C3（期望 401；404 说明没落盘）"
[ "$C3" = "401" ] || fail "档案新接口未生效（$C3）"
DOC=$(curl -s --max-time 15 https://moonarmor.cn/auth-doctor.html | grep -c "probe(" ; true)
say "医生页 probe( 次数 → $DOC（期望 9）"
[ "$DOC" -ge 9 ] || fail "医生页仍是旧版（$DOC）"

rm -f /tmp/*.gz /tmp/*.gz 2>/dev/null
say "全部完成。备份：$B"
say "回滚：cp -a $B/* $T/ 后 systemctl restart moonarmor"
