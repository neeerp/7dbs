#!/bin/bash
if [ $# -eq 0 ]; then
  echo "Usage: $0 <example number>"
  exit 1
fi

COUCH_ROOT_URL="http://localhost:5984"
USER="admin"
PASS="couchdb"

example=$1

case $example in
  d2-1)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_all_docs" | jq
    ;;
  *)
    echo "Example $example does not exist."
    ;;
esac
