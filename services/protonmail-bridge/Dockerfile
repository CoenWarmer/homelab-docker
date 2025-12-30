FROM shenxn/protonmail-bridge:latest

# Install pass (password store) and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pass \
        gnupg \
        git && \
    rm -rf /var/lib/apt/lists/*

# Initialize pass with a dummy GPG key (for non-encrypted vault)
# The key will be created at runtime in the entrypoint
COPY docker-entrypoint-wrapper.sh /docker-entrypoint-wrapper.sh
RUN chmod +x /docker-entrypoint-wrapper.sh

ENTRYPOINT ["/docker-entrypoint-wrapper.sh"]




