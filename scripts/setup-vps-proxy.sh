#!/bin/bash
# setup-vps-proxy.sh — sobe proxy privado com auth na VPS (Ubuntu 22.04/24.04).
# Uso na VPS como root:
#   chmod +x setup-vps-proxy.sh
#   ./setup-vps-proxy.sh [SENHA]
# Sem SENHA ele gera uma forte e mostra no final.
# No final ele imprime IP:porta + usuario + senha prontos p/ cadastrar no app.
set -e
PASS="${1:-}"
if [ "$PASS" = "" ]; then
  PASS="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)"
  GENERATED=1
else
  GENERATED=0
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq 3proxy curl > /dev/null
mkdir -p /etc/3proxy
cat > /etc/3proxy/3proxy.cfg <<EOF
# 3proxy — ScreenRec (gerado por setup-vps-proxy.sh)
daemon
nserver 1.1.1.1
nserver 8.8.8.8
nscache 65536
timeouts 1 5 30 60 180 1800 60 60
users universal:CL:$PASS
auth strong
allow universal
proxy -p8080 -a
EOF
chmod 600 /etc/3proxy/3proxy.cfg
systemctl enable 3proxy > /dev/null 2>&1 || true
systemctl restart 3proxy
sleep 2
systemctl is-active 3proxy
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep 8080 || true
IP="$(curl -s --max-time 15 http://ip-api.com/json/?fields=query | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
echo "=========================================="
echo "PROXY NO AR: http://$IP:8080"
echo "usuario: universal"
echo "senha: $PASS"
echo "Cadastre no app em config/regions.json e digite a senha 1x com Salvar."
echo "=========================================="
