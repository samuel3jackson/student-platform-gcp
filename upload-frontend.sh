#!/bin/bash
set -e

# Get access token from service account
ACCESS_TOKEN=$(cat service_account.json | python3 -c "
import json, sys, time, urllib.request, urllib.parse
sa = json.load(sys.stdin)
import jwt
now = int(time.time())
claim = {'iss': sa['client_email'], 'scope': 'https://www.googleapis.com/auth/cloud-platform', 'aud': 'https://oauth2.googleapis.com/token', 'iat': now, 'exp': now + 3600}
signed = jwt.encode(claim, sa['private_key'], algorithm='RS256')
data = urllib.parse.urlencode({'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion': signed}).encode()
resp = json.loads(urllib.request.urlopen('https://oauth2.googleapis.com/token', data).read())
print(resp['access_token'])
")

BUCKET="infra-case-study-frontend-dev"

# Upload index.html
curl -X PUT \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: text/html" \
  --data-binary @index.html \
  "https://storage.googleapis.com/upload/storage/v1/b/$BUCKET/o?uploadType=media&name=index.html"

echo ""
echo "✅ Uploaded! Access at:"
echo "https://storage.googleapis.com/$BUCKET/index.html"
