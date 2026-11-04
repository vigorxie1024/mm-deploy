#!/bin/bash
# install-updater.sh v2 —— 装 10 秒级自更新
set -u
T=/www/wwwroot/moonarmor
DEP=$T/.deploy
mkdir -p "$DEP"
say(){ echo "[安装] $*"; }

curl -fsSL --max-time 60 "https://raw.githubusercontent.com/vigorxie1024/mm-deploy/main/prod-manifest/auto-update.sh" \
  -o "$DEP/auto-update.sh" 2>/dev/null \
  || curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" \
     "https://api.github.com/repos/vigorxie1024/mm-deploy/contents/prod-manifest/auto-update.sh?ref=main" -o "$DEP/auto-update.sh"
chmod +x "$DEP/auto-update.sh"
bash -n "$DEP/auto-update.sh" || { echo "脚本语法错误，中止"; exit 1; }
say "自更新脚本就绪"

cat > /etc/systemd/system/moonarmor-autoupdate.service <<'EOF'
[Unit]
Description=moonarmor auto update (10s)
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /www/wwwroot/moonarmor/.deploy/auto-update.sh
EOF
cat > /etc/systemd/system/moonarmor-autoupdate.timer <<'EOF'
[Unit]
Description=check moonarmor updates every 10 seconds

[Timer]
OnBootSec=30s
OnUnitActiveSec=10s
AccuracySec=1s
Unit=moonarmor-autoupdate.service

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl restart moonarmor-autoupdate.timer >/dev/null 2>&1
systemctl enable moonarmor-autoupdate.timer >/dev/null 2>&1
say "定时器："$(systemctl is-active moonarmor-autoupdate.timer)"  间隔：10 秒"
say "立刻跑一轮"
bash "$DEP/auto-update.sh"
sleep 1
say "日志尾部："
tail -6 "$DEP/auto-update.log" 2>/dev/null
