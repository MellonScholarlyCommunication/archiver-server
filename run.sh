#!/bin/bash

TEMP_DIR=./tmp
FAILED_DIR=./error
TIMEMAP_BASE=http://web.archive.org/web/timemap/link/

if [ ! -d $TEMP_DIR ]; then
    mkdir $TEMP_DIR
fi

if [ ! -d $FAILED_DIR ]; then
    mkdir $FAILED_DIR
fi

# Ignore empty directories
shopt -s nullglob

function info {
    T_NOW=`date +%Y-%m-%dT%H:%M:%S`
    echo "${T_NOW} [INFO] : $0 - $1" 
}

function warn {
    T_NOW=`date +%Y-%m-%dT%H:%M:%S`
    echo "${T_NOW} [WARN] : $0 - $1"
}

function debug {
    T_NOW=`date +%Y-%m-%dT%H:%M:%S`
    echo "${T_NOW} [DEBUG] : $0 - $1"
}

function error {
    T_NOW=`date +%Y-%m-%dT%H:%M:%S`
    echo "${T_NOW} [ERROR] :  $0 - $1" 
}

function send_announce {
    DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    > ${TEMP_DIR}/announce.jsonld cat << EOF
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    { "iana": "https://www.iana.org/" }
  ],
  "id": "urn:uuid:9ec17fd7-f0f1-4d97-b421-29bfad935aad",
  "type": "Announce",
  "published": "${DATE}",
  "actor": {
    "id": "http://mycontributions.info/service/m/profile/card#me",
    "name": "Mastodon Bot",
    "inbox": "http://mycontributions.info/service/m/inbox/",
    "type": "Service"
  },
  "context": "${OBJECT}",
  "inReplyTo": "${ACTIVITY_ID}",
  "object": {
    "id": "${TIMEMAP_BASE}${OBJECT}",
    "type": "Document",
    "iana:original": "${OBJECT}",
    "iana:memento": "${ARCHIVED_URL}"
  },
  "target": {
    "id": "${ACTOR_ID}",
    "type": "${ACTOR_TYPE}",
    "name": "${ACTOR_NAME}",
    "inbox": "${ACTOR_INBOX}"
  }
}
EOF
    info "sending announce.jsonld to ${ACTOR_INBOX}"
    
    exponential-backoff-tool -a -M -r 2 -e "x*x" "ldn-sender ${ACTOR_INBOX} ${TEMP_DIR}/announce.jsonld"

    if [ $? -eq 0 ]; then
        info "done 👍"
        exit 0
    else 
        D=$(date +%Y%m%d%H%M%S)
        error "failed 👎"
        mv ${TEMP_DIR}/announce.jsonld ${FAILED_DIR}/${D}-announce.jsonld
        exit 2
    fi
}

for f in ./inbox/*.jsonld ; do
    info "processing $f..."
    
    ACTIVITY_ID=$(jq -r ".id" $f)
    ACTOR_ID=$(jq -r ".actor.id" $f)
    ACTOR_INBOX=$(jq -r ".actor.inbox" $f)
    ACTOR_NAME=$(jq -r ".actor.name" $f)
    ACTOR_TYPE=$(jq -r ".actor.type" $f)
    OBJECT=$(jq -r ".object.id" $f)

    rm -f $f

    if [[ "${ACTIVITY_ID}" == "" ]]; then
       error "no activity id found in $f"
       continue
    fi
    if [[ "${ACTOR_ID}" == "" ]] || 
       [[ "${ACTOR_NAME}" == "" ]] ||
       [[ "${ACTOR_TYPE}" == "" ]] ||
       [[ "${ACTOR_INBOX}" == "" ]] ; then
       error "bad actor found in $f"
       continue
    fi
    if [ "${OBJECT}" == "" ]; then
        error "no object.id found in $f"
        continue
    fi

    error "actor = ${ACTOR_ID} @ ${ACTOR_INBOX}"
    error "object = ${OBJECT}"

    error "starting wayback on ${OBJECT}"
    wayback --ia --ip=false --is=false --ph=false --ga=false ${OBJECT} > ${TEMP_DIR}/wayback.output 2>&1

    ARCHIVED_URL=$(grep "IA: " ${TEMP_DIR}/wayback.output | sed -e 's/.*IA: //')

    send_announce
done