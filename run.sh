#!/bin/bash

TEMP_DIR=./tmp
FAILED_DIR=./error
ARCHIVER="./wayback-archiver.sh"
TIMEMAP_BASE=http://web.archive.org/web/timemap/link/
SEND_ATTEMPTS=2
LOCK_FILE=${TEMP_DIR}/lock

source .env

# Set a sleep to keep from getting blocked from Web archives with too
# many exists
SLEEP=30

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
    UUID=$(uuidgen | tr A-Z a-z)
    DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    > ${TEMP_DIR}/announce.jsonld cat << EOF
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    { "iana": "https://www.iana.org/" }
  ],
  "id": "urn:uuid:${UUID}",
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
    
    exponential-backoff-tool -a -M -r $SEND_ATTEMPTS -e "x*x" "ldn-sender ${ACTOR_INBOX} ${TEMP_DIR}/announce.jsonld"

    if [ $? -eq 0 ]; then
        info "👍 done ${OBJECT}"
    else 
        D=$(date +%Y%m%d%H%M%S)
        error "👎 failed ${OBJECT}"
        mv ${TEMP_DIR}/announce.jsonld ${FAILED_DIR}/${D}-$$-announce.jsonld
    fi
}

function cleanup {
    echo "Caught: $?"
    if [ -f $LOCK_FILE ]; then
        echo "Removing $LOCK_FILE"
        rm  -f $LOCK_FILE
    fi
    exit 0
}

trap cleanup EXIT

if [ -f $LOCK_FILE ]; then
    error "$LOCK_FILE found exiting"
    exit 2
fi

info "start"
info "locking $LOCKFILE"
touch $LOCK_FILE

info "scanning ./inbox"
COUNT=0
for f in ./inbox/*.jsonld ; do
    if [ "${COUNT}" != 0 ]; then
        info "sleeping $SLEEP seconds..."
        sleep $SLEEP
    fi

    info "processing $f..."
    
    ACTIVITY_ID=$(jq -r ".id" $f)
    ACTOR_ID=$(jq -r ".actor.id" $f)
    ACTOR_INBOX=$(jq -r ".actor.inbox" $f)
    ACTOR_NAME=$(jq -r ".actor.name" $f)
    ACTOR_TYPE=$(jq -r ".actor.type" $f)
    OBJECT=$(jq -r ".object.id" $f)

    if [[ "${ACTIVITY_ID}" == "" ]]; then
       error "no activity id found in $f"
       mv $f $FAILED_DIR
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
        mv $f $FAILED_DIR
        continue
    fi

    info "actor = ${ACTOR_ID} @ ${ACTOR_INBOX}"
    info "object = ${OBJECT}"

    info "starting archiver ${ARCHIVER} on ${OBJECT}"

    ARCHIVED_URL=$(${ARCHIVER} "${OBJECT}")

    info "archiver done..."

    if [ "${ARCHIVED_URL}" == "" ]; then
        error "failed to generated archived url"
        mv $f $FAILED_DIR
    else
        info "extracted ${ARCHIVED_URL}"
        send_announce
    fi

    rm -f $f

    COUNT=$((COUNT+1))
done

info "done"