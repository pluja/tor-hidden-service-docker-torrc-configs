FROM --platform=$BUILDPLATFORM alpine:3.21

LABEL maintainer="hundehausen"
LABEL description="Tor Hidden Service Docker Image"

# Set Tor version - this will be updated by DependencyBot
ENV TOR_VERSION=0.4.8.16-r0

# Install packages & Create directory
RUN apk add --no-cache \
    tor=${TOR_VERSION} \
    curl \
    su-exec \
    && mkdir -p /var/lib/tor/hidden_service/ \
    && chown -R tor:tor /var/lib/tor/ \
    && chmod -R 700 /var/lib/tor/ \
    && rm -rf /var/cache/apk/*

# Copy configuration files and scripts
COPY torrc /etc/tor/torrc
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=300s --timeout=3s \
CMD curl -sS --socks5-hostname localhost:9050 https://check.torproject.org/ | grep -q Congratulations

# Expose the Tor SOCKS port
EXPOSE 9050

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["tor", "-f", "/etc/tor/torrc"]
