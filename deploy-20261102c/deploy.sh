#!/bin/bash
# deploy-20261102c.sh —— 月亮盔甲「细胞产品上线」一次落地 8 个文件
# 备份 → 三路取件 → sha256 → node --check → 落盘 → 重启 → 五项探活 → 失败自动回滚
set -u
T=/www/wwwroot/moonarmor
B=$T/.deploy-bak-$(date +%s)
BASE="https://api.github.com/repos/vigorxie1024/mm-deploy/contents/deploy-20261102c"
ALT="https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/deploy-20261102c"
say(){ echo "[deploy] $*"; }
rollback(){
  say "开始回滚…"
  [ -f "$B/web__auth-doctor.html" ] && cp -a "$B/web__auth-doctor.html" "$T/web/auth-doctor.html" && say "  还原 web/auth-doctor.html"
  [ -f "$B/web__cschat-cell.html" ] && cp -a "$B/web__cschat-cell.html" "$T/web/cschat-cell.html" && say "  还原 web/cschat-cell.html"
  [ -f "$B/server__archive-schema.js" ] && cp -a "$B/server__archive-schema.js" "$T/server/archive-schema.js" && say "  还原 server/archive-schema.js"
  [ -f "$B/server__archive-engine.js" ] && cp -a "$B/server__archive-engine.js" "$T/server/archive-engine.js" && say "  还原 server/archive-engine.js"
  [ -f "$B/server__modules__cell__engine.js" ] && cp -a "$B/server__modules__cell__engine.js" "$T/server/modules/cell/engine.js" && say "  还原 server/modules/cell/engine.js"
  [ -f "$B/server__modules__cell__reader.js" ] && cp -a "$B/server__modules__cell__reader.js" "$T/server/modules/cell/reader.js" && say "  还原 server/modules/cell/reader.js"
  [ -f "$B/server__modules__slim-matching__governance.js" ] && cp -a "$B/server__modules__slim-matching__governance.js" "$T/server/modules/slim-matching/governance.js" && say "  还原 server/modules/slim-matching/governance.js"
  [ -f "$B/server__server.js" ] && cp -a "$B/server__server.js" "$T/server/server.js" && say "  还原 server/server.js"
  systemctl restart moonarmor 2>/dev/null || service moonarmor restart 2>/dev/null
  sleep 2; say "回滚完成："$(systemctl is-active moonarmor 2>/dev/null)
}
fail(){ echo "[deploy] 失败：$*"; rollback; exit 1; }
mkdir -p "$B" || { echo "[deploy] 备份目录建不了"; exit 1; }
# 1 备份
[ -f "$T/web/auth-doctor.html" ] && cp -a "$T/web/auth-doctor.html" "$B/web__auth-doctor.html" && say "备份 web/auth-doctor.html"
[ -f "$T/web/cschat-cell.html" ] && cp -a "$T/web/cschat-cell.html" "$B/web__cschat-cell.html" && say "备份 web/cschat-cell.html"
[ -f "$T/server/archive-schema.js" ] && cp -a "$T/server/archive-schema.js" "$B/server__archive-schema.js" && say "备份 server/archive-schema.js"
[ -f "$T/server/archive-engine.js" ] && cp -a "$T/server/archive-engine.js" "$B/server__archive-engine.js" && say "备份 server/archive-engine.js"
[ -f "$T/server/modules/cell/engine.js" ] && cp -a "$T/server/modules/cell/engine.js" "$B/server__modules__cell__engine.js" && say "备份 server/modules/cell/engine.js"
[ -f "$T/server/modules/cell/reader.js" ] && cp -a "$T/server/modules/cell/reader.js" "$B/server__modules__cell__reader.js" && say "备份 server/modules/cell/reader.js"
[ -f "$T/server/modules/slim-matching/governance.js" ] && cp -a "$T/server/modules/slim-matching/governance.js" "$B/server__modules__slim-matching__governance.js" && say "备份 server/modules/slim-matching/governance.js"
[ -f "$T/server/server.js" ] && cp -a "$T/server/server.js" "$B/server__server.js" && say "备份 server/server.js"
# 2 取件
say "取件 web__auth-doctor.html.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__auth-doctor.html.gz?ref=main" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/web__auth-doctor.html.gz" -o /tmp/web__auth-doctor.html.gz \
  || fail "取件失败 web__auth-doctor.html.gz"
say "取件 web__cschat-cell.html.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/web__cschat-cell.html.gz?ref=main" -o /tmp/web__cschat-cell.html.gz \
  || curl -fsSL --max-time 90 "$ALT/web__cschat-cell.html.gz" -o /tmp/web__cschat-cell.html.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/web__cschat-cell.html.gz" -o /tmp/web__cschat-cell.html.gz \
  || fail "取件失败 web__cschat-cell.html.gz"
say "取件 server__archive-schema.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-schema.js.gz?ref=main" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__archive-schema.js.gz" -o /tmp/server__archive-schema.js.gz \
  || fail "取件失败 server__archive-schema.js.gz"
say "取件 server__archive-engine.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__archive-engine.js.gz?ref=main" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__archive-engine.js.gz" -o /tmp/server__archive-engine.js.gz \
  || fail "取件失败 server__archive-engine.js.gz"
say "取件 server__modules__cell__engine.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__cell__engine.js.gz?ref=main" -o /tmp/server__modules__cell__engine.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__cell__engine.js.gz" -o /tmp/server__modules__cell__engine.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__modules__cell__engine.js.gz" -o /tmp/server__modules__cell__engine.js.gz \
  || fail "取件失败 server__modules__cell__engine.js.gz"
say "取件 server__modules__cell__reader.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__cell__reader.js.gz?ref=main" -o /tmp/server__modules__cell__reader.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__cell__reader.js.gz" -o /tmp/server__modules__cell__reader.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__modules__cell__reader.js.gz" -o /tmp/server__modules__cell__reader.js.gz \
  || fail "取件失败 server__modules__cell__reader.js.gz"
say "取件 server__modules__slim-matching__governance.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__modules__slim-matching__governance.js.gz?ref=main" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__modules__slim-matching__governance.js.gz" -o /tmp/server__modules__slim-matching__governance.js.gz \
  || fail "取件失败 server__modules__slim-matching__governance.js.gz"
say "取件 server__server.js.gz"
curl -fsSL --max-time 90 -H "Accept: application/vnd.github.raw" "$BASE/server__server.js.gz?ref=main" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "$ALT/server__server.js.gz" -o /tmp/server__server.js.gz \
  || curl -fsSL --max-time 90 "https://cdn.jsdelivr.net/gh/vigorxie1024/mm-deploy@main/deploy-20261102c/server__server.js.gz" -o /tmp/server__server.js.gz \
  || fail "取件失败 server__server.js.gz"
# 3 校验
gunzip -cf /tmp/web__auth-doctor.html.gz > /tmp/web__auth-doctor.html || fail "解压失败 web__auth-doctor.html.gz"
GOT=$(sha256sum /tmp/web__auth-doctor.html | cut -d" " -f1)
[ "$GOT" = "d77457fb09f02b94b90762fce96821a31f631ea2b3df7185c6830b2cb24f4a22" ] || fail "sha 不符 web/auth-doctor.html（期望 d77457fb09f0… 实际 ${GOT:0:12}…）"
say "校验通过 web/auth-doctor.html"
gunzip -cf /tmp/web__cschat-cell.html.gz > /tmp/web__cschat-cell.html || fail "解压失败 web__cschat-cell.html.gz"
GOT=$(sha256sum /tmp/web__cschat-cell.html | cut -d" " -f1)
[ "$GOT" = "1e505a8cda99d99267c3641b8101208a12ad22ac9ad41b434ac7bd5b03e8bb92" ] || fail "sha 不符 web/cschat-cell.html（期望 1e505a8cda99… 实际 ${GOT:0:12}…）"
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
[ "$GOT" = "1b1549e04f9fabebd17012475862984c27bbe92b921b867a15809a699e6d69c3" ] || fail "sha 不符 server/modules/cell/engine.js（期望 1b1549e04f9f… 实际 ${GOT:0:12}…）"
say "校验通过 server/modules/cell/engine.js"
gunzip -cf /tmp/server__modules__cell__reader.js.gz > /tmp/server__modules__cell__reader.js || fail "解压失败 server__modules__cell__reader.js.gz"
GOT=$(sha256sum /tmp/server__modules__cell__reader.js | cut -d" " -f1)
[ "$GOT" = "2aa1f82a6fd9d9e752a928d50a2682ff3667d0d6d791d4a378dd0ca86b94f548" ] || fail "sha 不符 server/modules/cell/reader.js（期望 2aa1f82a6fd9… 实际 ${GOT:0:12}…）"
say "校验通过 server/modules/cell/reader.js"
gunzip -cf /tmp/server__modules__slim-matching__governance.js.gz > /tmp/server__modules__slim-matching__governance.js || fail "解压失败 server__modules__slim-matching__governance.js.gz"
GOT=$(sha256sum /tmp/server__modules__slim-matching__governance.js | cut -d" " -f1)
[ "$GOT" = "cf4ef469d776e37d850a6ac87a5411a3885e21972c23889d81bbaf67992aa3a4" ] || fail "sha 不符 server/modules/slim-matching/governance.js（期望 cf4ef469d776… 实际 ${GOT:0:12}…）"
say "校验通过 server/modules/slim-matching/governance.js"
gunzip -cf /tmp/server__server.js.gz > /tmp/server__server.js || fail "解压失败 server__server.js.gz"
GOT=$(sha256sum /tmp/server__server.js | cut -d" " -f1)
[ "$GOT" = "89d47b49ab47ebd01b5ea40e54aca4bcb1693308d5106127ec3de1ff512de4be" ] || fail "sha 不符 server/server.js（期望 89d47b49ab47… 实际 ${GOT:0:12}…）"
say "校验通过 server/server.js"
# 4 语法
node --check /tmp/server__archive-schema.js || fail "语法失败 server/archive-schema.js（未替换任何文件）"
node --check /tmp/server__archive-engine.js || fail "语法失败 server/archive-engine.js（未替换任何文件）"
node --check /tmp/server__modules__cell__engine.js || fail "语法失败 server/modules/cell/engine.js（未替换任何文件）"
node --check /tmp/server__modules__cell__reader.js || fail "语法失败 server/modules/cell/reader.js（未替换任何文件）"
node --check /tmp/server__modules__slim-matching__governance.js || fail "语法失败 server/modules/slim-matching/governance.js（未替换任何文件）"
node --check /tmp/server__server.js || fail "语法失败 server/server.js（未替换任何文件）"
say "5 个服务端文件语法全部通过"
# 5 落盘
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
mkdir -p "$(dirname "$T/server/modules/cell/reader.js")"
install -m 644 /tmp/server__modules__cell__reader.js "$T/server/modules/cell/reader.js" || fail "写入失败 server/modules/cell/reader.js"
mkdir -p "$(dirname "$T/server/modules/slim-matching/governance.js")"
install -m 644 /tmp/server__modules__slim-matching__governance.js "$T/server/modules/slim-matching/governance.js" || fail "写入失败 server/modules/slim-matching/governance.js"
mkdir -p "$(dirname "$T/server/server.js")"
install -m 644 /tmp/server__server.js "$T/server/server.js" || fail "写入失败 server/server.js"
say "8 个文件已落盘"
# 6 重启
systemctl restart moonarmor || fail '重启失败'
sleep 3
ST=$(systemctl is-active moonarmor 2>/dev/null); [ "$ST" = "active" ] || fail "服务未起来：$ST"; say "服务 active"
# 7 五项探活（真验收）
P=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/cschat-cell.html || echo 000); say "细胞页面 → $P（期望 200）"; [ "$P" = "200" ] || fail "页面不可访问 $P"
C=$(curl -s --max-time 15 https://moonarmor.cn/api/cell/members | head -c 40); say "成员接口 → $C"
case "$C" in *members*) ;; *) fail "成员接口异常";; esac
Q=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/api/cell/reader/books || echo 000); say "AI 读者章节列表 → $Q（期望 200）"; [ "$Q" = "200" ] || fail "读者接口异常 $Q"
F=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://moonarmor.cn/api/archive/by-frequency?frequency=fr-health || echo 000); say "档案多路径接口 → $F（期望 401）"; [ "$F" = "401" ] || fail "档案新接口未生效 $F"
D=$(curl -s --max-time 15 https://moonarmor.cn/auth-doctor.html | grep -c "probe(" ; true); say "医生页 probe( → $D（期望 9）"; [ "$D" -ge 9 ] || fail "医生页仍旧版 $D"
rm -f /tmp/*.gz /tmp/*.gz.out 2>/dev/null
say "全部完成 ✔ 备份：$B"
