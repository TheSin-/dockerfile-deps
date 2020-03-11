#!/bin/bash
set -e

if [[ "$1" == "terracoin-cli" || "$1" == "terracoin-tx" || "$1" == "terracoind" || "$1" == "test_terracoin" ]]; then
	mkdir -p "$BITCOIN_DATA"

	CONFIG_PREFIX=""
    if [[ "${BITCOIN_NETWORK}" == "regtest" ]]; then
        CONFIG_PREFIX=$'regtest=1\n[regtest]'
    fi
    if [[ "${BITCOIN_NETWORK}" == "testnet" ]]; then
        CONFIG_PREFIX=$'testnet=1\n[test]'
    fi
    if [[ "${BITCOIN_NETWORK}" == "mainnet" ]]; then
        CONFIG_PREFIX=$'mainnet=1\n[main]'
    fi

	cat <<-EOF > "$BITCOIN_DATA/terracoin.conf"
	${CONFIG_PREFIX}
	printtoconsole=1
	rpcallowip=::/0
	${BITCOIN_EXTRA_ARGS}
	EOF
	chown bitcoin:bitcoin "$BITCOIN_DATA/terracoin.conf"

	# ensure correct ownership and linking of data directory
	# we do not update group ownership here, in case users want to mount
	# a host directory and still retain access to it
	chown -R bitcoin "$BITCOIN_DATA"
	ln -sfn "$BITCOIN_DATA" /home/bitcoin/.terracoincore
	chown -h bitcoin:bitcoin /home/bitcoin/.terracoincore

	exec gosu bitcoin "$@"
else
	exec "$@"
fi
