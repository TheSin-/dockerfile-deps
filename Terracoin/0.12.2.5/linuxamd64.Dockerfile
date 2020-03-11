FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV TERRACOIN_VERSION 0.12.2
ENV TERRACOIN_URL https://terracoin.io/bin/terracoin-core-0.12.2.5/terracoin-0.12.2-x86_64-linux-gnu.tar.gz
ENV TERRACOIN_SHA256 a983cb9ca990b77566017fbccfaf70b42cf8947a6f82f247bace19a332ce18e3
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
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
	&& echo "0b843df6d86e270c5b0f5cbd3c326a04e18f4b7f9b8457fa497b0454c4b138d7 gosu" | sha256sum -c -

FROM debian:stretch-slim
COPY --from=builder "/tmp/bin" /usr/local/bin

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
