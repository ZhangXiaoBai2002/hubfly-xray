#!/bin/sh
# Generate a minimal VLESS inbound (WS by default, XHTTP if TRANSPORT=xhttp) from env, then exec xray.
# Required on platforms whose edge terminates TLS and forwards plain HTTP to $PORT.
set -eu


UUID="${UUID:-00000000-0000-0000-0000-000000000000}"
PORT="${PORT:-8080}"
WSPATH="${WSPATH:-/tk-rail}"
TRANSPORT="${TRANSPORT:-ws}"


# refuse obvious placeholder in production-ish logs (still start so panel health checks don't loop forever)
if [ "$UUID" = "00000000-0000-0000-0000-000000000000" ] || [ "$UUID" = "CHANGE_ME" ]; then
  echo "WARNING: set a real UUID env before handing out client links" >&2
fi


case "$WSPATH" in
  /*) ;;
  *) WSPATH="/$WSPATH" ;;
esac


if [ "$TRANSPORT" = "xhttp" ]; then
  STREAM='"network": "xhttp", "security": "none", "xhttpSettings": { "path": "'"${WSPATH}"'", "mode": "packet-up" }'
else
  STREAM='"network": "ws", "security": "none", "wsSettings": { "path": "'"${WSPATH}"'" }'
fi


CFG=/tmp/xray-config.json
cat > "$CFG" <<JSON
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${PORT},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID}" } ],
        "decryption": "none"
      },
      "streamSettings": { ${STREAM} }
    }
  ],
  "outbounds": [ { "protocol": "freedom", "settings": { "domainStrategy": "UseIPv4" } } ]
}
JSON


echo "starting xray on port ${PORT} path ${WSPATH} transport ${TRANSPORT}"
exec /usr/local/bin/xray run -c "$CFG"

