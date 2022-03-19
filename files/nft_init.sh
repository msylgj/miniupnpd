#!/bin/sh
#
# establish the chains that miniupnpd will update dynamically
#
# 'add' doesn't raise an error if the object already exists. 'create' does.
#

echo "Creating nftables structure"

cat >> /etc/nftables.d/80-miniupnpd.nft <<EOF
# Hook fw4 forward
chain forward {
    jump miniupnpd
}

# miniupnpd
chain miniupnpd {
}

# Hook fw4 nat
chain dstnat {
    jump prerouting_miniupnpd
}

chain srcnat {
    jump postrouting_miniupnpd
}

chain prerouting_miniupnpd {
}

chain postrouting_miniupnpd {
}
EOF
