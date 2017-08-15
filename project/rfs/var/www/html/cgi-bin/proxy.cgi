#!/bin/bash
echo "Content-Type: application/x-ns-proxy-autoconfig"
echo

function match_domain() {
	echo
	cat /etc/privoxy/ladder.action | grep '^\.' | awk '{printf("\tif (shExpMatch(host, \"*%s\")) return proxy;\n", $1)}'
}

echo "pac update" >&2
PROXY=
[ -z "$QUERY_STRING" ] || PROXY="SOCKS5 $QUERY_STRING:31280; SOCKS $QUERY_STRING:31280; PROXY $QUERY_STRING:3128; DIRECT"
[ -z "$QUERY_STRING" ] && PROXY="DIRECT"
cat <<EOF
function IsLocalNetwork(host) {
	if (isInNet(host, "10.0.0.0", "255.0.0.0")) return true;
	if (isInNet(host, "172.16.0.0",  "255.240.0.0")) return true;
	if (isInNet(host, "192.168.0.0", "255.255.0.0")) return true;
	if (isInNet(host, "127.0.0.0", "255.255.255.0")) return true;
	return false;
}

function FindProxyForURL(url, host) {
	url  = url.toLowerCase();
	host = host.toLowerCase();
	proxy="$PROXY"
	if (IsLocalNetwork(dnsResolve(host))) {
		return "DIRECT";
	}

	if (isPlainHostName(host)) {
		return "DIRECT";
	}
	$(match_domain)
	return "DIRECT";
}
EOF
