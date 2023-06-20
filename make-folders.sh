#!/bin/bash 

. /home/kevin/project/create-server-config.sh

export FILE=/home/kevin/project


PORT=${1}
ORG=${2}
USERNAME=tls-${ORG}
PASSWORD=tls-${ORG}pw
declare -i LISTENINGPORT=$PORT+10000
HOSTS=0.0.0.0


FILE=/home/kevin/project/servers
FILE=$FILE/tls-ca-${ORG}
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT

cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2


. /home/kevin/project/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD $ORG
register_tls

declare -i PORT=$PORT+10
USERNAME=ca-${ORG}
PASSWORD=ca-${ORG}pw
declare -i LISTENINGPORT=$PORT+10000

FILE=/home/kevin/project/servers
FILE=${FILE}/ca-${ORG} 
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT

cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2


. /home/kevin/project/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD $ORG 


register_ca

enroll_nodes