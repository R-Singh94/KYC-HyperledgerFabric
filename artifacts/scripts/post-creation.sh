#!/bin/bash


export PATH=/home/arunab/projects/temp/KYC-HyperledgerFabric/bin:/home/arunab/projects/temp/KYC-HyperledgerFabric/artifacts:$PATH
export FABRIC_CFG_PATH=/home/arunab/projects/temp/KYC-HyperledgerFabric/artifacts

CHANNEL_NAME="$1"
LANGUAGE="$2"
DELAY="5"
MAX_RETRY=10

LANGUAGE=node
CC_SRC_PATH=/opt/gopath/src/github.com/chaincode


# import utils
. utils.sh

setGlobals 1 1
# peer version

# To try out things
tryout(){
    setGlobals 1 1
    instantiateChaincode 1 1
}
# installChaincode 1 1
# tryout



