#!/bin/bash


export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

echo $FABRIC_CFG_PATH

CHANNEL_NAME="$1"
LANGUAGE="$2"
DELAY="5"
MAX_RETRY=10

LANGUAGE=node
CC_SRC_PATH=/opt/gopath/src/github.com/chain-code

# import utils
. utils.sh

setGlobals 1 1
# peer version

# To try out things

# installChaincode 1 1

instantiateChaincode 1 1