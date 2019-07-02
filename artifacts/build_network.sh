#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

MODE=$1
if [ "$2" != "" ]; then
    CONSENSUS_TYPE=$2
else
    CONSENSUS_TYPE=solo
fi
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\.0-preview ^1\.1\.0-alpha"
export IMAGE_TAG="latest"
COMPOSE_FILE=docker-compose.yaml
COMPOSE_FILE_RAFT2=docker-compose-etcdraft.yaml

function printHelp() {
    echo "Usage: "
    echo "  build_networks.sh <mode> <consensus-type> <language> "
    echo "    <mode> - one of 'up', 'down', or 'restart'"
    echo "      - 'up' - bring up the network with docker-compose up"
    echo "      - 'down' - clear the network with docker-compose down"
    echo "      - 'restart' - restart the network"
    echo "    <consensus-type> - the consensus-type of the ordering service: solo or etcdraft"
    echo "    <language> - the chaincode language: golang (default) or node"
    echo
    echo "Before running this script, one would first generate the required certificates and "
    echo "genesis block, then bring up the network. Please use generate.sh before this"
    echo
    echo "Examples : "
    echo "	build_networks.sh up etcdraft"
    echo "	build_networks.sh down"
}

function prerequisite() {
    LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
    DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGE_TAG peer version | sed -ne 's/ Version: //p' | head -1)

    echo "LOCAL_VERSION=$LOCAL_VERSION"
    echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

    if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
        echo "=================== WARNING ==================="
        echo "  Local fabric binaries and docker images are  "
        echo "  out of  sync. This may cause problems.       "
        echo "==============================================="
    fi

    for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
        echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
        if [ $? -eq 0 ]; then
            echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
            exit 1
        fi

        echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
        if [ $? -eq 0 ]; then
        echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
        exit 1
        fi
    done
}

function networkUp() {
    prerequisite
    if [ ! -d "crypto-config" ]; then
        echo "Please generate the Crypto Materials using \"generate.sh\" and then run this script"
        exit 1
    fi

    if  [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
        docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT2 up -d 2>&1
        docker ps -a
    else
        docker-compose -f $COMPOSE_FILE up -d 2>&1
        docker ps -a
    fi

    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start network"
        exit 1
    fi

    if [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
        sleep 1
        echo "Sleeping 15s to allow $CONSENSUS_TYPE cluster to complete booting"
        sleep 14
    fi

    #TO-DO: Creation of the Channel and joining the peers to the Channel

}

function networkDown() {
    #Stop all docker instances that are currently running
    docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_RAFT2 down --volumes --remove-orphans
}

if [ "$MODE" == "up" ]; then
    networkUp
elif [ "$MODE" == "down" ]; then
    networkDown
elif [ "$MODE" == "restart" ]; then
    networkDown
    networkUp]
else
    printHelp
    exit 1
fi
