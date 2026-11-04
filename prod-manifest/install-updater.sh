#!/bin/bash
# install-updater.sh —— 一次性安装自更新（装完就再不用人管部署）
set -u
T=/www/wwwroot/moonarmor
DEP=$T/.deploy
mkdir -p "$DEP"
say(){ echo "[安装] $*"; }

say "写自更新脚本"
curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" \
  "https://api.github.com/repos/vigorxie1024/mm-deploy/contents/prod-manifest/auto-update.sh?ref=main" \
  -o "$DEP/auto-update.sh" || { echo "下载失败"; exit 1; }
chmod +x "$DEP/auto-update.sh"
bash -n "$DEP/auto-update.sh" || { echo "脚本语法错误"; exit 1; }
say "脚本就绪：$DEP/auto-update.sh"

say "写 systemd 服务与定时器（每 5 分钟）"
cat > /etc/systemd/system/moonarmor-autoupdate.service <<'EOF'
[Unit]
Description=moonarmor auto update
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /www/wwwroot/moonarmor/.deploy/auto-update.sh
EOF
cat > /etc/systemd/system/moonarmor-autoupdate.timer <<'EOF'
[Unit]
Description=check moonarmor updates every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=moonarmor-autoupdate.service

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now moonarmor-autoupdate.timer >/dev/null 2>&1
say "定时器状态："$(systemctl is-active moonarmor-autoupdate.timer)

say "首次跑一轮（拉取当前版本）"
bash "$DEP/auto-update.sh" | tail -5
say "完成。以后有新版本，服务器 5 分钟内自己更新——不需要任何人点按钮。"
say "日志：$DEP/auto-update.log   查看：tail -f $DEP/auto-update.log"
