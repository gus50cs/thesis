
#!/bin/bash


. /home/kevin/project/channel-config.sh
. /home/kevin/project/envar.sh


PORT=$1
ORG=$2
FILE=/home/kevin/project
CHANNEL_NAME=${ORG}.channel

input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $2}' $input)
declare -i y=1
for i in $orderers
do
    IFS=
    declare -i ORD_PORT=$PORT+$y-500+13
    NAME=$i
    config_channel ${ORD_PORT} ${ORG} ${FILE} $NAME
    y=$y+1

done


createChannelGenesisBlock() {
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock /home/kevin/project/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
}

export FABRIC_CFG_PATH=$FILE/configtx/org1/
#createChannelGenesisBlock $CHANNEL_NAME
BLOCKFILE=/home/kevin/project/channel-artifacts/${CHANNEL_NAME}.block


createChannel() {
    declare -i ORD_PORT=$PORT+$y-500+12+50
    #echo "${ORD_PORT} ${ORDERER_ADMIN_TLS_SIGN_CERT} ${ORDERER_ADMIN_TLS_PRIVATE_KEY} $ORDERER_CA"
    set -x
	osnadmin channel join --channelID $CHANNEL_NAME --config-block /home/kevin/project/channel-artifacts/${CHANNEL_NAME}.block -o localhost:${ORD_PORT} --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	let rc=$res
    cat log.txt

}
export ORDERER_CA=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/tlscacerts/ca.crt
export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/signcerts/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORG}-orderer/orderers/${NAME}/tls-msp/keystore/server.key
#createChannel $PORT $CHANNEL_NAME


joinChannel() {
  export CORE_PEER_LOCALMSPID="org1MSP"
  export CORE_PEER_MSPCONFIGPATH=$FILE/organizations/${ORG}/users/admin/msp
  export CORE_PEER_ADDRESS=localhost:1011
  export FABRIC_CFG_PATH=/home/kevin/project/organizations/org1/peers/ws
  MAX_RETRY=5
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	#verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

export FABRIC_CFG_PATH=/home/kevin/project/organizations/org1/msp/tlscacerts/ca.crt
joinChannel $ORG 