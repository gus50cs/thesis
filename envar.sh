#!/bin/bash

FILE=/home/kevin/project


ORG=$1
input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $2}' $input)

for i in $orderers
do
  NAME=$i
  export ORDERER_CA=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/tlscacerts/ca.crt
  export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/signcerts/server.crt
  export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/keystore/server.key
done

export ${ORG}=$FILE/organizations/${ORG}/msp/tlscacerts/ca.crt
setGlobals() {
  PORT=$1
  export CORE_PEER_LOCALMSPID="${ORG}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${!ORG}
  export CORE_PEER_MSPCONFIGPATH=$FILE/organizations/${ORG}/users/admin/msp
  export CORE_PEER_ADDRESS=localhost:$PORT
}

setGlobalsCLI() {
  PORT=$1
  PEER=$2
  setGlobals $PORT
  export CORE_PEER_ADDRESS=${PEER}.${ORG}:${PORT}
}

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}