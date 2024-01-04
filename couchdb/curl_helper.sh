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
  d3-poll-changes)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_changes" | jq
    ;;
  d3-poll-changes-since)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_changes?since=27210-g1AAAACdeJzLYWBgYMpgLhdMzi9NzkhJcjA0MtczAELDHJBMIkNS_f___7MymJMYGEyjcoFi7CaWyUaWFoZYtOA2J48FSDI0AKn_cONMPoCNMzC1SDZOTcWiMwsAwGMqKA" | jq
    ;;
  d3-longpoll)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_changes?feed=longpoll&since=27213-g1AAAACdeJzLYWBgYMpgLhdMzi9NzkhJcjA0MtczAELDHJBMIkNS_f___7MymJMYGExjc4Fi7CaWyUaWFoZYtOA2J48FSDI0AKn_cONMPoCNMzC1SDZOTcWiMwsAwbMqKw" | jq
    ;;
  d3-continuous)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_changes?feed=continuous&since=27213-g1AAAACdeJzLYWBgYMpgLhdMzi9NzkhJcjA0MtczAELDHJBMIkNS_f___7MymJMYGExjc4Fi7CaWyUaWFoZYtOA2J48FSDI0AKn_cONMPoCNMzC1SDZOTcWiMwsAwbMqKw"
    ;;
  d3-create-wherabouts)
    curl -u $USER:$PASS -XPUT "${COUCH_ROOT_URL}/music/_design/wherabouts" \
      -H "Content-Type: application/json" \
      -d '{"language":"javascript","filters":{"by_country":"function(doc,req){return doc.country === req.query.country;}"}}'
    ;;
  d3-wherabouts-rus)
    curl -u $USER:$PASS "${COUCH_ROOT_URL}/music/_changes?filter=wherabouts/by_country&country=RUS"
    ;;
  d3-conflict-1)
    curl -u $USER:$PASS -XPUT "${COUCH_ROOT_URL}/music-repl/theconflicts" \
      -H "Content-Type: application/json" \
      -d '{
        "_id": "theconflicts",
        "_rev": "1-e007498c59e95d23912be35545049174",
        "name": "The Conflicts",
        "albums": ["Conflicts of Interest"]
      }'
    ;;
  d3-conflict-2)
    curl -u $USER:$PASS -XPUT "${COUCH_ROOT_URL}/music/theconflicts" \
      -H "Content-Type: application/json" \
      -d '{
        "_id": "theconflicts",
        "_rev": "1-e007498c59e95d23912be35545049174",
        "name": "The Conflicts",
        "albums": ["Conflicting Opinions"]
      }'
    ;;
  *)
    echo "Example $example does not exist."
    ;;
esac
