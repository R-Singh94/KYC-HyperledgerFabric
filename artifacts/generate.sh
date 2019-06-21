#!/bin/sh

export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=kyc-channel
if [ -z "$1" ]; then
  echo "Please provide the consensus type in the command line"
  echo "Usage : generate.sh [CONSENSUS_TYPE]"
  echo "Supported Consensus types SOLO(\"solo\") & RAFT(\"etcdraft\")"
  exit 1
fi
CONSENSUS_TYPE=$1

# check if cryptogen binary is present in the system
which cryptogen
if [ "$?" -ne 0 ]; then
  echo "cryptogen tool not found. exiting"
  exit 1
fi

echo
echo "##########################################################"
echo "##### Generate certificates using cryptogen tool #########"
echo "##########################################################"

# remove previous crypto material and config transactions
if [ -d "crypto-config" ]; then
  rm -fr crypto-config/*
fi

# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# check if configtxgen binary is present in the system
which configtxgen
if [ "$?" -ne 0 ]; then
  echo "configtxgen tool not found. exiting"
  exit 1
fi

echo "##########################################################"
echo "#########  Generating Orderer Genesis block ##############"
echo "##########################################################"

if test "$CONSENSUS_TYPE" = "solo" ; then
  configtxgen -profile KYCOrgOrdererGenesis -channelID $CHANNEL_NAME -outputBlock ./channel-artifacts/genesis.block
elif test "$CONSENSUS_TYPE" = "etcdraft" ; then
  configtxgen -profile KYCEtcdRaft -channelID $CHANNEL_NAME -outputBlock ./channel-artifacts/genesis.block
else
  echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
  exit 1
fi
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

echo "#################################################################"
echo "### Generating channel configuration transaction 'channel.tx' ###"
echo "#################################################################"
configtxgen -profile KYCOrgChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

echo
echo "#################################################################"
echo "#######    Generating anchor peer update for Client    ##########"
echo "#################################################################"
configtxgen -profile KYCOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/ClientMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ClientMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Client..."
  exit 1
fi

echo
echo "#################################################################"
echo "#######    Generating anchor peer update for Validator ##########"
echo "#################################################################"
configtxgen -profile KYCOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/ValidatorMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ValidatorMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Validator..."
  exit 1
fi


echo
echo "#################################################################"
echo "#######    Generating anchor peer update for Bank      ##########"
echo "#################################################################"
configtxgen -profile KYCOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/BankMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ValidatorMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Bank..."
  exit 1
fi