#!/bin/bash

OBJECT=$1

if [ "${OBJECT}" == "" ]; then
    echo "usage: $0 ${OBJECT}"
    exit 1
fi

TEMP_FILE=$(mktemp)

wayback --ia --ip=false --is=false --ph=false --ga=false ${OBJECT} > ${TEMP_FILE} 2>&1

ARCHIVED_URL=$(grep "IA: " ${TEMP_FILE} | sed -e 's/.*IA: //')

echo $ARCHIVED_URL

rm ${TEMP_FILE}