#!/bin/bash 
. /home/kevin/project/create-orderer-config.sh

FILE=/home/kevin/project
ORG=$1

input="/home/kevin/project/orderer-${ORG,,}.txt"
PORT=$(awk 'NR<2{print $2}' $input)
declare -i PORT=$PORT+10
orderers=$(awk 'NR>1{print $2}' $input)
declare -i y=2
for i in $orderers
do
    declare -i PORT=$PORT+$y
    sed -i "${y}s/$/ ${PORT}/" $input
    NAME=$i
    declare -i ADMIN_PORT=$PORT+50
    declare -i OPERADDRESS=$PORT+100
    mkdir -p $FILE/organizations/${ORG,,}-orderer/orderers/$NAME/LEDGER
    LEDGER=$FILE/organizations/${ORG,,}-orderer/orderers/$NAME/LEDGER
    MSPATH=$FILE/organizations/${ORG,,}-orderer/orderers/$NAME/msp
    MSPID=${ORG}ordererMSP 
    config_orderer ${PORT} ${NAME} ${ORG} ${FILE} $LEDGER $MSPATH $MSPID ${OPERADDRESS} ${ADMIN_PORT}
    config_orderer_docker ${PORT} ${ORG} ${NAME} ${ADMIN_PORT} ${OPERADDRESS} $FILE
    docker-compose -f $FILE/organizations/${ORG,,}-orderer/orderers/$NAME/orderer-docker.yaml up -d 2>&1
    y=$y+1
done 