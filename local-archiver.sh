#!/bin/bash

LOCAL_MAX_LEVEL=0
LOCAL_WAIT=0
LOCAL_EMAIL="Patrick.Hochstenbach@UGent.be"
LOCAL_BASE_URL=http://localhost
LOCAL_PUBLIC_DIR="./public"

source .env

DATE=$(date +%Y%m%dT%H%M%S)
URL=$1

if [ "${URL}" == "" ]; then
    echo "usage: $0 url"
    exit 1
fi

URLESC=$(echo "${URL}" | sed 's/[^A-Za-z0-9][^A-Za-z0-9]*/-/g')

wget \
    --quiet \
    --level=$LOCAL_MAX_LEVEL \
    --warc-file=${LOCAL_PUBLIC_DIR}/${DATE}-${URLESC} \
    --page-requisites \
    --html-extension \
    --convert-links \
    --execute robots=off \
    --directory-prefix=. \
    --span-hosts \
    --user-agent="Mozilla (mailto:${LOCAL_EMAIL})" \
    --wait=$LOCAL_WAIT \
    --random-wait \
    --delete-after \
    --no-directories \
    $URL 

echo "${LOCAL_BASE_URL}/${DATE}-${URLESC}"