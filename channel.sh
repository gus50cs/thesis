
#!/bin/bash


. /home/kevin/project/channel-config.sh

PORT=$1
ORG=$2
FILE=/home/kevin/project
CHANNEL_NAME=${ORG}.channel

input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $1}' $input)
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

export FABRIC_CFG_PATH=$FILE/configtx/org1
createChannelGenesisBlock $CHANNEL_NAME


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

createChannel $PORT $CHANNEL_NAME