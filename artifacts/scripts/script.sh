#!/bin/bash

CHANNEL_NAME="$1"
LANGUAGE="$2"
DELAY="5"
MAX_RETRY=10

LANGUAGE=node
CC_SRC_PATH=/opt/gopath/src/github.com/chaincode

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1
VERSION
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.kyc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.kyc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2 3; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done
}

updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel update -o orderer.kyc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    set +x
  else
    set -x
    peer channel update -o orderer.kyc.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  veriCHANNEL_NAMEupdate failed"
  echoCHANNEL_NAMEhor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleeCHANNEL_NAME
  echoCHANNEL_NAME
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for Client..."
updateAnchorPeers 0 1
echo "Updating anchor peers for Validator..."
updateAnchorPeers 0 2
echo "Updating anchor peers for Bank..."
updateAnchorPeers 0 3

## Install chaincode
echo "Installing chaincode on client org"
installChaincode 1 1
echo "Installing chaincode on validator org"
installChaincode 1 2
echo "Installing chaincode on bank org"
installChaincode 1 3

sleep $DELAY

## instantiate chaincode
echo "Instantiate chaincode on client org"
instantiateChaincode 1 1