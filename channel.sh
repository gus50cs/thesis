
#!/bin/bash


. /home/kevin/project/channel-config.sh

PORT=$1
ORG=$2
. /home/kevin/project/envar.sh $ORG
FILE=/home/kevin/project
CHANNEL_NAME=${ORG}.channel

input="/home/kevin/project/orderer-${ORG,,}.txt"
orderers=$(awk '{print $2}' $input)
declare -i y=1
for i in $orderers
do
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
##createChannelGenesisBlock $CHANNEL_NAME
BLOCKFILE=$FILE/channel-artifacts/${CHANNEL_NAME}.block


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
    PORT=$1
    PEER=$2
    DELAY=3
    export FABRIC_CFG_PATH=$FILE/organizations/$ORG/peers/$PEER/
    MAX_RETRY=5
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
        set -x
        peer channel join -b $BLOCKFILE >&log.txt
        res=$?
        { set +x; } 2>/dev/null
		    let rc=$res
		    COUNTER=$(expr $COUNTER + 1)
	done
	    cat log.txt
}

input="$FILE/peers-${ORG,,}.txt"
number=$(awk '{print $1}' $input)
ports=$(awk '{print $4}' $input)
peers=$(awk '{print $2}' $input)
for i in $number
do  
    #echo $i
    #echo "niggas"
    PORT="$(echo $ports | cut -d " " -f $i)"
    PEER="$(echo $peers | cut -d " " -f $i)"
    setGlobals $PORT
    #joinChannel $PORT $PEER
done



PEER="$(echo $peers | cut -d " " -f 1)"
PORT="$(echo $ports | cut -d " " -f 1)"
input="$FILE/orderer-${ORG,,}.txt"
ports=$(awk '{print $4}' $input)
orderer=$(awk '{print $2}' $input)
ORD_PORT="$(echo $ports | cut -d " " -f 1)"
ORD="$(echo $orderer | cut -d " " -f 1)"
setAnchorPeer() {
    docker exec cli /bin/bash -c "/home/kevin/project/setAnchor.sh $ORG $CHANNEL_NAME $PEER $ORD $PORT $ORD_PORT"
}

setAnchorPeer
#ports="1 2 3 4 5"

# Loop through each port in the ports variable
#for port in $ports
#do
    # Print a message for each port
   # echo "Processing port: $port"
   # echo "hello"
#done
