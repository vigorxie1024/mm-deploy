#!/bin/bash
# asus 443 split v2 - auto-detect (Alibaba Cloud Linux / system nginx)
# moves https listeners 443 -> 8443, adds stream ssl_preread split on 443
set -u
BIN=$(command -v nginx || echo /usr/sbin/nginx)
CONF=$($BIN -V 2>&1 | tr ' ' '\n' | sed -n 's/--conf-path=//p')
CONF=${CONF:-/etc/nginx/nginx.conf}
CONFDIR=$(dirname $CONF)
MODDIR=/usr/share/nginx/modules
STAMP=$(date +%Y%m%d%H%M%S)
BAK=/root/asus-bak-$STAMP.tgz
echo "nginx=$BIN conf=$CONF dir=$CONFDIR"
tar czf $BAK $CONFDIR $MODDIR /www/server/panel/vhost/nginx 2>/dev/null || tar czf $BAK $CONFDIR $MODDIR 2>/dev/null
[ -s $BAK ] && echo "backup ok: $BAK $(stat -c%s $BAK) bytes" || { echo BACKUP_FAIL; exit 1; }
# 1) stream module
if ! $BIN -T 2>/dev/null | grep -q 'ngx_stream_module'; then
  SO=$(ls $MODDIR/ngx_stream_module.so 2>/dev/null | head -1)
  if [ -z "$SO" ]; then echo NO_STREAM_MODULE; exit 1; fi
  grep -q '^load_module.*ngx_stream_module' $CONF || sed -i "1i load_module $SO;" $CONF
  echo "loaded stream module: $SO"
else echo 'stream module already loaded'; fi
# 2) move 443 -> 8443
N=0
for f in $(grep -rlE 'listen[[:space:]]+(\[::\]:)?443' $CONFDIR 2>/dev/null); do
  cp -a $f $f.asusbak; sed -i -E 's/listen([[:space:]]+)(\[::\]:)?443/listen\18443/g' $f; N=$((N+1)); echo "  moved: $f"
done
echo "files_moved=$N"
[ $N -eq 0 ] && { echo NO_443_FOUND; exit 1; }
# 3) stream block
mkdir -p $CONFDIR/stream.d
cat > $CONFDIR/stream.d/asus-split.conf <<'XEOF'
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
grep -q 'stream.d/asus-split.conf' $CONF || echo "include $CONFDIR/stream.d/asus-split.conf;" >> $CONF
# 4) asus account
id asus >/dev/null 2>&1 || useradd -m -s /bin/bash asus
echo 'asus ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-asus; chmod 440 /etc/sudoers.d/90-asus
install -d -m 700 -o asus -g asus /home/asus/.ssh
printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEEPJzwPOfTaUqGcQcger0P4F/U6TaJD2FLIrYxtcvL asus@moonarmor' > /home/asus/.ssh/authorized_keys
chmod 600 /home/asus/.ssh/authorized_keys; chown asus:asus /home/asus/.ssh/authorized_keys
rollback(){
  echo ROLLING_BACK
  tar xzf $BAK -C /
  for f in $(ls $CONFDIR/*.asusbak $CONFDIR/*/*.asusbak 2>/dev/null); do cp -a $f ${f%.asusbak}; rm -f $f; done
  rm -f $CONFDIR/stream.d/asus-split.conf
  $BIN -t && systemctl reload nginx; echo ROLLBACK_DONE
}
# 5) test + reload + smoke
$BIN -t 2>&1 | tail -3 || { rollback; exit 2; }
systemctl reload nginx || $BIN -s reload || { rollback; exit 3; }
sleep 3
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://moonarmor.cn/ 2>/dev/null)
CODE2=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H 'Host: moonarmor.cn' https://127.0.0.1/ 2>/dev/null)
BANNER=$(timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/443; head -c 8 <&3' 2>/dev/null)
echo "http_domain=$CODE http_local=$CODE2 ssh_banner=$BANNER"
[ "$CODE" = '200' ] || { echo SMOKE_FAIL; rollback; exit 4; }
case "$BANNER" in SSH-2.0-*) echo OK_443_SPLIT_READY ;; *) echo SSH_MUX_FAIL; rollback; exit 5 ;; esac
