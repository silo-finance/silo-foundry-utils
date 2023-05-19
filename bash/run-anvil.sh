#!/bin/bash

ANVIL_PORT=8546
ANVIL_CHAIN_ID=9119

FILE_PID=./bash/.anvil-pid.txt

if [[ -f "$FILE_PID" ]]; then
    rm $FILE_PID
fi

&>/dev/null anvil --port $ANVIL_PORT --chain-id $ANVIL_CHAIN_ID &

PID=$!

echo $PID >> $FILE_PID
echo $PID
