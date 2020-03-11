# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV TERRACOIN_VERSION 0.12.2
ENV TERRACOIN_URL https://terracoin.io/bin/terracoin-core-0.12.2.5/terracoin-0.12.2-arm-linux-gnueabihf.tar.gz
ENV TERRACOIN_SHA256 0d65c717f66ca68624f3837c88f63746930c1ab43be44dacf0d5b6407fad17ff
ENV TERRACOIN_ASC_URL https://terracoin.io/bin/terracoin-core-0.12.2.5/SHA256SUMS.asc
ENV TERRACOIN_PGP_KEY A78B5052E13EC768

# install terracoin binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO terracoin.tar.gz "$TERRACOIN_URL" \
	&& echo "$TERRACOIN_SHA256 terracoin.tar.gz" | sha256sum -c - \
	&& gpg --keyserver keyserver.ubuntu.com --recv-keys "$TERRACOIN_PGP_KEY" \
	&& wget -qO terracoin.asc "$TERRACOIN_ASC_URL" \
	&& gpg --verify terracoin.asc \
	&& mkdir bin \
	&& tar -xzvf terracoin.tar.gz -C /tmp/bin --strip-components=2 "terracoin-$TERRACOIN_VERSION/bin/terracoin-cli" "terracoin-$TERRACOIN_VERSION/bin/terracoind" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-armhf" \
	&& echo "171b4a2decc920de0dd4f49278d3e14712da5fa48de57c556f99bcdabe03552e gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm32v7/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-arm-static /usr/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.terracoincore \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.terracoincore

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 13332 13333 18332 18321
CMD ["terracoind"]
