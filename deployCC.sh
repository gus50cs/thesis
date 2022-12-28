#!/bin/bash


FILE=/home/kevin/project

ORG=$1
CHANNEL_NAME=${ORG}.channel
CC_NAME=${2}
CC_SRC_PATH=${3}
CC_SRC_LANGUAGE=${4}
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="NA"
CC_END_POLICY="NA"
CC_COLL_CONFIG="NA"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"

export FABRIC_CFG_PATH=/home/kevin/project/organizations/org1/peers/qa

# import utils
. $FILE/envar.sh $ORG
. $FILE/ccutils.sh


CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  #infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  #successln "Finished vendoring Go dependencies"
fi


INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  { set +x; } 2>/dev/null
  cat log.txt
  #verifyResult $res "Chaincode packaging has failed"
  #successln "Chaincode is packaged"
}

## package the chaincode
#packageChaincode


install() {
  input="$FILE/peers-${ORG,,}.txt"
  number=$(awk '{print $1}' $input)
  ports=$(awk '{print $4}' $input)
  peers=$(awk '{print $2}' $input)
  for i in $number  
  do  
    PORT="$(echo $ports | cut -d " " -f $i)"
    PEER="$(echo $peers | cut -d " " -f $i)"
    installChaincode $PORT
  done
}

install 

## Install chaincode on peer0.org1 and peer0.org2
#infoln "Installing chaincode on peer0.org1..."
#infoln "Install chaincode on peer0.org2..."
#installChaincode 2

## query whether the chaincode is installed
#queryInstalled 1

## approve the definition for org1
#approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect org1 to have approved and org2 not to
#checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
#checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

## now approve also for org2
#approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
#checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
#checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

## now that we know for sure both orgs have approved, commit the definition
#commitChaincodeDefinition 1 2

## query on both orgs to see that the definition committed successfully
#queryCommitted 1
#queryCommitted 2

## Invoke the chaincode - this does require that the chaincode have the 'initLedger'
## method defined
#if [ "$CC_INIT_FCN" = "NA" ]; then
#  infoln "Chaincode initialization is not required"
#else
  #chaincodeInvokeInit 1 2
#fi

