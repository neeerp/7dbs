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
  d2-views-1)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_all_docs" | jq
    ;;
  d2-views-2)
    # This time, include the document in addition to the metadata
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_all_docs?include_docs=true" | jq
    ;;
  d2-view-artists-by-name)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/artists/_view/by_name" | jq
    ;;
  d2-view-albums-by-name)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/albums/_view/by_name" | jq
    ;;
  d2-view-albums-by-name-help)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/albums/_view/by_name?key=\"Help!\"" | jq
    ;;
  d2-import)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/artists/_view/by_name?limit=5" | jq
    ;;
  d2-import-2)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/artists/_view/by_name?limit=5&startkey=%22C%22&endkey=%22D%22" | jq
    ;;
  d2-import-3)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/artists/_view/by_name?limit=5&startkey=%22D%22&endkey=%22C%22&descending=true" | jq
    ;;
  d2-hw-q2)
    RAND=$(ruby -e 'puts rand')
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_design/random/_view/artist?limit=1&startkey=${RAND}" | jq
    ;;
  *)
    echo "Example $example does not exist."
    ;;
esac
