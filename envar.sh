#!/bin/bash

FILE=/home/kevin/project


ORG=$1
ORD=$2
NAME=$3


export ORDERER_CA=$FILE/organizations/${ORD}-orderer/orderers/${NAME}/tls-msp/tlscacerts/ca.crt
export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORD}-orderer/orderers/${NAME}/tls-msp/signcerts/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORD}-orderer/orderers/${NAME}/tls-msp/keystore/server.key


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
  PEERS1=""
  for i in ${ORGS[@]}  
  do
    input="$FILE/peers-$i.txt"
    peers=$(awk 'NR>1{print $2}' $input)
    for k in ${PEERS[@]}
    do
      PEER="$k"
      if echo $peers | grep -wq "$PEER"; then
        result=$(grep -n "${PEER}" $input | cut -d':' -f1)  
        PORT=$(awk -v line=$result 'NR==line{print $4}' $input)
        setGlobals $PORT
        PEER="$PEER"
        ## Set peer addresses
        if [ -z "$PEERS1" ]
        then
  	    PEERS1="$PEER"
        else
	      PEERS1="$PEERS1 $PEER"
        fi
        PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
        ## Set path to TLS certificate
        org_ca=$FILE/organizations/${i}/msp/tlscacerts/ca.crt
        CA=$org_ca
        TLSINFO=(--tlsRootCertFiles "${CA}")
        PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
        # shift by one to get to the next organization
      fi
    done
  done
}