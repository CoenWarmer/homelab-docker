#!/bin/bash
set -e

# Initialize GPG and pass if not already done
if [ ! -d "/root/.password-store" ]; then
    echo "Initializing pass password store..."
    
    # Create GPG key configuration
    cat > /tmp/gpg-key-config << EOF
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Proton Bridge
Name-Email: bridge@local
Expire-Date: 0
EOF

    # Generate GPG key
    gpg --batch --gen-key /tmp/gpg-key-config 2>/dev/null
    
    # Get the key ID
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr' | head -1 | cut -d: -f10)
    
    # Initialize pass with the key
    pass init "$KEY_ID"
    
    echo "Pass initialized successfully"
fi

# Handle init mode (pass to original entrypoint)
if [[ $1 == init ]]; then
    exec bash /protonmail/entrypoint.sh "$@"
fi

# Custom startup with corrected ports for Proton Bridge v3
# socat will make the conn appear to come from 127.0.0.1
# Proton Bridge v3 uses port 1026 for SMTP and 1144 for IMAP
# socat TCP-LISTEN:25,fork TCP:127.0.0.1:1026 &
# socat TCP-LISTEN:143,fork TCP:127.0.0.1:1144 &

# Start protonmail bridge
# Fake a terminal, so it does not quit because of EOF...
rm -f faketty
mkfifo faketty
cat faketty | protonmail-bridge --cli

