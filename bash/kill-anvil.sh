#!/bin/bash

ANVIL_PID=$(cat "./bash/.anvil-pid.txt")

kill -9 $ANVIL_PID

echo "Killed an Anvil with PID: $ANVIL_PID"
