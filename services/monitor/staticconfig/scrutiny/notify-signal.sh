#!/bin/sh
# Scrutiny -> Signal notification script
# Scrutiny passes the message as the first argument

MESSAGE="$1"
SIGNAL_API="http://signal-api:8080"
SENDER="+31638278909"
RECIPIENT="+31638278909"

# Send to Signal API
curl -s -X POST "${SIGNAL_API}/v2/send" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"💾 Scrutiny Alert\n\n${MESSAGE}\", \"number\": \"${SENDER}\", \"recipients\": [\"${RECIPIENT}\"]}"






