#!/bin/bash

FILE=/home/kevin/project


ORG=$1
input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $2}' $input)

for i in $orderers
do
  IFS=
  NAME=$i
  export ORDERER_CA=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/tlscacerts/ca.crt
  export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/signcerts/server.crt
  export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/keystore/server.key
done

export ${ORG}_CA=$FILE/organizations/${ORG}/msp/tlscacerts/ca.crt

setGlobals() {
  VAR=$1
  input="/home/kevin/project/orderer-${ORG,,}.txt"
  peers=$(awk '{print $3}' $input)
  export CORE_PEER_LOCALMSPID="${ORG}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${ORG}_CA
  export CORE_PEER_MSPCONFIGPATH=$FILE/organizations/${ORG}/users/admin/msp
    if [ $USING_PEER -eq 1 ]; then
      PORT=(echo $peers | cut -d " " -f 1)
      export CORE_PEER_ADDRESS=localhost:$PORT
  
}

