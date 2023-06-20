#!/bin/bash 

. /home/kevin/project/create-peer-config.sh


FILE=/home/kevin/project
ORG=$1
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"
: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
input="/home/kevin/project/peers-${ORG,,}.txt"
PORT=$(awk 'NR<2{print $2}' $input)
echo $PORT
declare -i PORT=$PORT+10
peers=$(awk 'NR>1{print $2}' $input)
declare -i y=2
docker-compose -f $FILE/yamlfiles/cli.yaml up -d 2>&1
for i in $peers
do
    
    declare -i PORT=$PORT+$y
    sed -i "${y}s/$/ ${PORT}/" $input
    NAMEPEER=$i
    declare -i CHAINCODE_PORT=$PORT+50
    declare -i OPERADDRESS=$PORT+100
    declare -i COUCHPORT=$y+5984
    LEADER=true
    ADDRESSES="n "
    mkdir -p $FILE/organizations/${ORG,,}/peers/$NAMEPEER/LEDGER
    LEDGER=$FILE/organizations/${ORG,,}/peers/$NAMEPEER/LEDGER
    MSPATH=$FILE/organizations/${ORG,,}/peers/$NAMEPEER/msp
    MSPID=${ORG}MSP
    #echo "$PORT $NAMEPEER $ORG $CHAINCODE_PORT $ADDRESSES $LEADER $FILE $LEDGER $MSPATH $MSPID $OPERADDRESS"
    config_core $PORT $NAMEPEER $ORG $CHAINCODE_PORT $LEADER ${LEADER} ${FILE} $LEDGER $MSPATH ${OPERADDRESS} $MSPID
    config_peer ${PORT} ${ORG} ${NAMEPEER} ${FILE} ${CHAINCODE_PORT} 
    config_vm_peer ${ORG} ${NAMEPEER} ${DOCKER_SOCK} $FILE
    config_couch ${COUCHPORT} ${ORG} ${NAMEPEER}
    DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} -f $FILE/organizations/${ORG,,}/peers/$NAMEPEER/peer.yaml -f $FILE/organizations/${ORG,,}/peers/$NAMEPEER/vm-peer.yaml up -d 2>&1  
    y=$y+1
done 


