# This is a collection of bash functions used by different scripts

ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kyc.com/orderers/orderer.kyc.com/msp/tlscacerts/tlsca.kyc.com-cert.pem
PEER0_CLIENT_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Client.kyc.com/peers/peer0.Client.kyc.com/tls/ca.crt
PEER0_VALIDATOR_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Validator.kyc.com/peers/peer0.Validator.kyc.com/tls/ca.crt
PEER0_BANK_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Bank.kyc.com/peers/peer0.Bank.kyc.com/tls/ca.crt

# verify the result of the end-to-end test
verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
    exit 1
  fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  CORE_PEER_LOCALMSPID="OrdererMSP"
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kyc.com/orderers/orderer.kyc.com/msp/tlscacerts/tlsca.example.com-cert.pem
  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/kyc.com/users/Admin@example.com/msp
}

#Set Organization Globals
setGlobals() {
  PEER=$1
  ORG=$2
  if [ $ORG -eq 1 ]; then
    CORE_PEER_LOCALMSPID="ClientMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CLIENT_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Client.kyc.com/users/Admin@Client.kyc.com/msp
    if [ $PEER -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.Client.kyc.com:7051
    else
      CORE_PEER_ADDRESS=peer1.Client.kyc.com:8051
    fi
  elif [ $ORG -eq 2 ]; then
    CORE_PEER_LOCALMSPID="ValidatorMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_VALIDATOR_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Validator.kyc.com/users/Admin@Validator.kyc.com/msp
    if [ $PEER -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.Validator.kyc.com:9051
    else
      CORE_PEER_ADDRESS=peer1.Validator.kyc.com:10051
    fi

  elif [ $ORG -eq 3 ]; then
    CORE_PEER_LOCALMSPID="BankMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BANK_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Bank.kyc.com/users/Admin@Bank.kyc.com/msp
    if [ $PEER -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.Bank.kyc.com:11051
    else
      CORE_PEER_ADDRESS=peer1.Bank.kyc.com:12051
    fi
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

## Sometimes Join takes time hence RETRY at least 5 times
joinChannelWithRetry() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  set -x
  peer channel join -b $CHANNEL_NAME.block >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=$(expr $COUNTER + 1)
    echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannelWithRetry $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}