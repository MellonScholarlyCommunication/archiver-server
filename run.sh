#!/bin/bash

TMPDIR=./tmp

if [ ! -d $TMPDIR ]; then
    mkdir $TMPDIR
fi

# Ignore empty directories
shopt -s nullglob

function send_announce {
    DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    > ${TMPDIR}/announce.jsonld cat << EOF
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": "urn:uuid:9ec17fd7-f0f1-4d97-b421-29bfad935aad",
  "type": "Announce",
  "published": "${DATE}",
  "actor": {
    "id": "http://mycontributions.info/service/m/profile/card#me",
    "name": "Mastodon Bot",
    "inbox": "http://mycontributions.info/service/m/inbox/",
    "type": "Service"
  },
  "object": {
    "id": "${ARCHIVED_URL}",
    "type": "WebPage"
  }
}
EOF
    echo "INFO - sending announce.jsonld to ${ACTOR_INBOX}"
    
    exponential-backoff-tool -a -M -r 2 -e "x*x" "ldn-sender ${ACTOR_INBOX} ${TMPDIR}/announce.jsonld"

    if [ $? -eq 0 ]; then
        echo "INFO - done 👍"
        exit 0
    else 
        echo "INFO - failed 👎"
        exit 2
    fi
}

for f in ./inbox/*.jsonld ; do
    echo "INFO - processing $f..."
    
    ACTOR_ID=$(jq -r ".actor.id" $f)
    ACTOR_INBOX=$(jq -r ".actor.inbox" $f)

    if [[ "${ACTOR_ID}" == "" ]] || 
       [[ "${ACTOR_INBOX}" == "" ]] ; then
       echo "ERROR - bad actor found in $f"
       continue
    fi

    echo "INFO - actor = ${ACTOR_ID} @ ${ACTOR_INBOX}"

    OBJECT=$(jq -r ".object.id" $f)

    if [ "${OBJECT}" == "" ]; then
        echo "ERROR - no object.id found in $f"
        continue
    else
        echo "INFO - object = ${OBJECT}"
    fi

    echo "INFO - starting wayback on ${OBJECT}"
    #wayback --ia --ip=false --is=false --ph=false --ga=false ${OBJECT} > ${TMPDIR}/wayback.output

    ARCHIVED_URL=$(grep "IA: " ${TMPDIR}/wayback.output | sed -e 's/.*IA: //')

    send_announce
done