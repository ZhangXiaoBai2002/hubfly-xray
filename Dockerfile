# Hubfly Space (and similar container PaaS): official xray image has NO shell.
# Multi-stage: copy binary into Alpine so entrypoint.sh can generate config from env.
# Fix for "permission denied" crash loop: chmod in a RUN layer and start the
# entrypoint through /bin/sh so it does not depend on the file exec bit.
FROM ghcr.io/xtls/xray-core:latest AS src
FROM alpine:3.20
COPY --from=src /usr/local/bin/xray /usr/local/bin/xray
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh /usr/local/bin/xray
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
