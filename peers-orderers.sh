#!/bin/bash 

. /home/kevin/project/create-peer-config.sh


FILE=/home/kevin/project
ORG=$2
declare -i PORT=$1+10


input="/home/kevin/project/peers-${ORG,,}.txt"
peers=$(awk '{print $2}' $input)
declare -i y=1
for i in $peers
do
    IFS=
    declare -i PORT=$PORT+$y
    sed -i "${y}s/$/ ${PORT}/" $input
    NAMEPEER=$i
    declare -i CHAINCODE_PORT=$PORT+50
    declare -i OPERADDRESS=$PORT+100
    LEADER=true
    ADDRESSES=" "
    mkdir -p $FILE/organizations/${ORG,,}/peers/$NAMEPEER/LEDGER
    LEDGER=$FILE/organizations/${ORG,,}/peers/$NAMEPEER/LEDGER
    MSPATH=$FILE/organizations/${ORG,,}/peers/$NAMEPEER/msp
    MSPID=${ORG}MSP
    config_core $PORT $NAMEPEER $ORG $CHAINCODE_PORT $ADDRESSES $LEADER $FILE $LEDGER $MSPATH $MSPID $OPERADDRESS
    config_peer ${PORT} ${ORG} ${NAMEPEER} ${FILE} ${CHAINCODE_PORT} 
    docker-compose -f $FILE/organizations/${ORG,,}/peers/$NAMEPEER/peer.yaml up -d 2>&1
    y=$y+1
done 


. /home/kevin/project/create-orderer-config.sh

input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $2}' $input)
declare -i y=1
for i in $orderers
do
    IFS=
    declare -i PORT=$PORT+$y-500
    sed -i "${y}s/$/ ${PORT}/" $input
    NAME=$i
    echo $ORG
    declare -i ADMIN_PORT=$PORT+50
    declare -i OPERADDRESS=$PORT+100
    mkdir -p $FILE/organizations/${ORG,,}-orderer/orderers/$NAME/LEDGER
    LEDGER=$FILE/organizations/${ORG,,}-orderer/orderers/$NAME/LEDGER
    MSPATH=$FILE/organizations/${ORG,,}-orderer/orderers/$NAME/msp
    MSPID=${ORG}ordererMSP
    echo "${PORT} ${NAME} ${ORG} ${FILE} $LEDGER $MSPATH $MSPID ${OPERADDRESS} ${ADMIN_PORT}"
    config_orderer ${PORT} ${NAME} ${ORG} ${FILE} $LEDGER $MSPATH $MSPID ${OPERADDRESS} ${ADMIN_PORT}
    config_orderer_docker ${PORT} ${ORG} ${NAME} ${ADMIN_PORT} ${OPERADDRESS} $FILE
    docker-compose -f $FILE/organizations/${ORG,,}-orderer/orderers/$NAME/orderer-docker.yaml up -d 2>&1
    y=$y+1
done 