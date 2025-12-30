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

# Start the original entrypoint
exec bash /protonmail/entrypoint.sh "$@"

