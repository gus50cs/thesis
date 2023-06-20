#!/bin/bash 

. /home/kevin/project/create-server-config.sh

export FILE=/home/kevin/project


PORT=${1}
ORG=${2}
HOSTS=0.0.0.0
declare -i PORT=$PORT-500
declare -i LISTENINGPORT=$PORT+10000
echo $PORT
USERNAME=tls-${ORG}-orderer
PASSWORD=tls-${ORG}pw-orderer
FILE=/home/kevin/project/servers
FILE=$FILE/tls-ca-${ORG}-orderer
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT
cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2


. /home/kevin/project/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD

register_tls_orderer


declare -i PORT=$PORT+10
USERNAME=ca-${ORG}-orderer
PASSWORD=ca-${ORG}pw-orderer
declare -i LISTENINGPORT=$PORT+10000
FILE=/home/kevin/project/servers
FILE=${FILE}/ca-${ORG}-orderer
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT
cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2


NAME=${2}

. /home/kevin/project/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD $ORG

register_ca_orderer

enroll_nodes_orderer