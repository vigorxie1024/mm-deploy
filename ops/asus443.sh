#!/bin/bash
# asus 443 split: nginx stream + ssl_preread
# SNI https -> 127.0.0.1:8443 ; raw TCP no-SNI -> 127.0.0.1:22 (sshd)
# auto rollback on any failure. sshd config untouched.
set -u
STAMP=$(date +%Y%m%d%H%M%S)
BAK=/root/asus-bak-$STAMP.tgz
NG=/www/server/nginx
VH=/www/server/panel/vhost/nginx
tar czf $BAK $NG/conf $VH 2>/dev/null && echo "backup ok: $BAK" || { echo BACKUP_FAIL; exit 1; }
if ! $NG/sbin/nginx -V 2>&1 | grep -q with-stream; then echo NO_STREAM_MODULE; exit 1; fi
id asus >/dev/null 2>&1 || useradd -m -s /bin/bash asus
echo 'asus ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-asus
chmod 440 /etc/sudoers.d/90-asus
install -d -m 700 -o asus -g asus /home/asus/.ssh
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEEPJzwPOfTaUqGcQcger0P4F/U6TaJD2FLIrYxtcvL asus@moonarmor' > /home/asus/.ssh/authorized_keys
chmod 600 /home/asus/.ssh/authorized_keys
chown asus:asus /home/asus/.ssh/authorized_keys
MOVED=0
for f in $(grep -rl 'listen 443' $NG/conf $VH 2>/dev/null); do
  cp -a $f $f.asusbak
  sed -i 's/listen[[:space:]]*\[::\]:443/listen [::]:8443/g; s/listen[[:space:]]*443/listen 8443/g' $f
  MOVED=$((MOVED+1))
done
echo moved_vhosts=$MOVED
cat > $NG/conf/stream_asus.conf <<'XEOF'
stream {
    map $ssl_preread_server_name $asus_backend {
        default 127.0.0.1:8443;
        ""      127.0.0.1:22;
    }
    server {
        listen 443;
        proxy_pass $asus_backend;
        ssl_preread on;
        proxy_connect_timeout 10s;
        proxy_timeout 3600s;
    }
}
XEOF
grep -q stream_asus.conf $NG/conf/nginx.conf || echo 'include /www/server/nginx/conf/stream_asus.conf;' >> $NG/conf/nginx.conf
rollback() {
  echo ROLLING_BACK
  tar xzf $BAK -C /
  for f in $(ls $NG/conf/*.asusbak $VH/*.asusbak 2>/dev/null); do cp -a $f $(echo $f | sed 's/.asusbak$//'); rm -f $f; done
  $NG/sbin/nginx -t && $NG/sbin/nginx -s reload
  echo ROLLBACK_DONE
}
if ! $NG/sbin/nginx -t; then rollback; exit 2; fi
$NG/sbin/nginx -s reload || { rollback; exit 3; }
sleep 3
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://moonarmor.cn/ 2>/dev/null)
BANNER=$(timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/443; head -c 8 <&3' 2>/dev/null)
echo http_code=$CODE ssh_banner=$BANNER
if [ "$CODE" != "200" ]; then echo SMOKE_FAIL; rollback; exit 4; fi
case "$BANNER" in SSH-2.0-*) echo OK_443_SPLIT_READY ;; *) echo SSH_MUX_FAIL; rollback; exit 5 ;; esac