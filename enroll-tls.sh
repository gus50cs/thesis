#!/bin/bash


PORT=$1
ORG=$2
USERNAME=$3
PASSWORD=$4


FILE=/home/kevin/project
 

function register_tls () {
    export porttls=$PORT
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/tls-ca-${ORG,,}/ca-cert.pem
    mkdir -p ${FILE}/organizations/${ORG,,}/admin
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}/admin
    > ${FILE}/peers-${ORG,,}.txt
    echo "${ORG,,} $PORT" >> ${FILE}/peers-${ORG,,}.txt
    fabric-ca-client enroll -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT}
    read -p "How many department :" NUMBER_PEERS
    export NUMBER_PEERS=$NUMBER_PEERS
    for (( i=1; i<=$NUMBER_PEERS; i++ ))
    do 
        read -p "Name of $i department :" PEER_NAME
        echo "$i ${PEER_NAME} ${PEER_NAME}pw" >> ${FILE}/peers-${ORG,,}.txt
        fabric-ca-client register --id.name ${PEER_NAME} --id.secret  ${PEER_NAME}pw --id.type peer -u https://0.0.0.0:${PORT}

    done
}



function register_ca () {
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG,,}/ca-cert.pem
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}
    fabric-ca-client enroll -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT}
    > ${FILE}/organizations/${ORG,,}/msp/config.yaml
    echo "$(yaml_node $PORT)" > ${FILE}/organizations/${ORG,,}/msp/config.yaml
    input="/home/kevin/project/peers-${ORG,,}.txt"
    awk 'NR>1{print $2,$3}' $input | while read -r USERNAME PASSWORD
    do 
        fabric-ca-client register --id.name $USERNAME --id.secret  $PASSWORD --id.type peer -u https://0.0.0.0:${PORT}
    done
    fabric-ca-client register --id.name admin-${ORG,,} --id.secret  admin${ORG,,}pw --id.type admin -u https://0.0.0.0:${PORT}

    fabric-ca-client register --id.name user-${ORG,,} --id.secret  user${ORG,,}pw --id.type client -u https://0.0.0.0:${PORT}

}


function enroll_nodes () {
    input="/home/kevin/project/peers-${ORG,,}.txt"
    awk 'NR>1{print $2,$3}' $input | while read -r USERNAME PASSWORD
    do 
        export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG,,}/ca-cert.pem
        export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}/peers/${USERNAME}
        export FABRIC_CA_CLIENT_MSPDIR=msp
        fabric-ca-client enroll -d -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT} --csr.hosts ${USERNAME}.${ORG,,} --csr.hosts localhost
        sleep 1
        mkdir -p ${FILE}/organizations/${ORG,,}/peers/${USERNAME}/msp/admincerts
        export FABRIC_CA_CLIENT_MSPDIR=tls-msp
        export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/tls-ca-${ORG,,}/ca-cert.pem
        fabric-ca-client enroll -d -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${porttls} --enrollment.profile tls --csr.hosts ${USERNAME}.${ORG,,} --csr.hosts localhost
        echo "$USERNAME $PASSWORD"
        sleep 1 
        cp "$FILE/organizations/${ORG,,}/msp/config.yaml" "$FILE/organizations/${ORG,,}/peers/${USERNAME}/msp/config.yaml"
        cp "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/signcerts/"* "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/signcerts/server.crt"
        cp "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/keystore/"* "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/keystore/server.key" 
        cp "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/tlscacerts/"* "${FILE}/organizations/${ORG,,}/peers/${USERNAME}/tls-msp/tlscacerts/ca.crt"
    done
    mkdir -p ${FILE}/organizations/${ORG,,}/users/admin
    mkdir -p ${FILE}/organizations/${ORG,,}/users/user
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}/users/admin
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG,,}//ca-cert.pem
    export FABRIC_CA_CLIENT_MSPDIR=msp

    fabric-ca-client enroll -d -u https://admin-${ORG,,}:admin${ORG,,}pw@0.0.0.0:${PORT}
    sleep 1 
    awk 'NR>1{print $2}' $input | while read -r USERNAME
    do 
        cp ${FILE}/organizations/${ORG,,}/users/admin/msp/signcerts/cert.pem ${FILE}/organizations/${ORG,,}/peers/$USERNAME/msp/admincerts/${ORG,,}-admin-cert.pem
        cp "$FILE/organizations/${ORG,,}/msp/config.yaml" "${FILE}/organizations/${ORG,,}/users/admin/msp/config.yaml"
    done

    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}/users/user
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG,,}/ca-cert.pem
    export FABRIC_CA_CLIENT_MSPDIR=msp
    fabric-ca-client enroll -d -u https://user-${ORG,,}:user${ORG,,}pw@0.0.0.0:${PORT}
    mkdir -p "${FILE}/organizations/${ORG}/msp/tlscacerts"
    cp "$FILE/organizations/${ORG,,}/msp/config.yaml" "${FILE}/organizations/${ORG,,}/users/user/msp/config.yaml"
    cp "${FILE}/servers/tls-ca-${ORG}/ca-cert.pem" "${FILE}/organizations/${ORG}/msp/tlscacerts/ca.crt"

}


function register_tls_orderer() {
    export porttls=$PORT
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/tls-ca-${ORG}-orderer/ca-cert.pem
    mkdir -p ${FILE}/organizations/${ORG,,}-orderer/admin
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}-orderer/admin
    > ${FILE}/orderer-${ORG,,}.txt
    echo "${ORG,,} $PORT" >> ${FILE}/orderer-${ORG,,}.txt
    fabric-ca-client enroll -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT}
    read -p "How many orderers :" NUMBER_ORDERERS
    export NUMBER_ORDERERS=$NUMBER_ORDERERS
    for (( i=1; i<=$NUMBER_ORDERERS; i++ ))
    do 
        read -p "Name of $i department :" ORDERER_NAME
        echo "$i ${ORDERER_NAME} ${ORDERER_NAME}pw" >> ${FILE}/orderer-${ORG,,}.txt
        fabric-ca-client register --id.name ${ORDERER_NAME} --id.secret  ${ORDERER_NAME}pw --id.type orderer -u https://0.0.0.0:${PORT}

    done

}

function register_ca_orderer () {
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG}-orderer/ca-cert.pem
    echo "$FABRIC_CA_CLIENT_TLS_CERTFILES"
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}-orderer
    fabric-ca-client enroll -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT}
    > $FILE/organizations/${ORG,,}-orderer/msp/config.yaml
    echo "$(yaml_node $PORT)" > $FILE/organizations/${ORG,,}-orderer/msp/config.yaml
    input="/home/kevin/project/orderer-${ORG,,}.txt"
    awk 'NR>1{print $2,$3}' $input | while read -r USERNAME PASSWORD
    do
        fabric-ca-client register --id.name $USERNAME --id.secret  $PASSWORD --id.type orderer -u https://0.0.0.0:${PORT}
    done

    fabric-ca-client register --id.name admin-${NAME,,} --id.secret  admin${NAME,,}pw --id.type admin -u https://0.0.0.0:${PORT}


}

function enroll_nodes_orderer () {
    input="/home/kevin/project/orderer-${ORG,,}.txt"
    awk 'NR>1{print $2,$3}' $input | while read -r USERNAME PASSWORD
    do
        export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG}-orderer/ca-cert.pem
        export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}
        export FABRIC_CA_CLIENT_MSPDIR=msp
        fabric-ca-client enroll -d -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${PORT} --csr.hosts ${USERNAME}.${ORG,,} --csr.hosts localhost
        sleep 1
        mkdir -p ${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/msp/admincerts
        export FABRIC_CA_CLIENT_MSPDIR=tls-msp
        export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/tls-ca-${ORG}-orderer/ca-cert.pem
        echo "{$porttls} ${port}"
        fabric-ca-client enroll -d -u https://${USERNAME}:${PASSWORD}@0.0.0.0:${porttls} --enrollment.profile tls --csr.hosts ${USERNAME}.${ORG,,} --csr.hosts localhost
        echo "$USERNAME $PASSWORD"
        sleep 1 
        cp "$FILE/organizations/${ORG,,}-orderer/msp/config.yaml"* "$FILE/organizations/${ORG,,}-orderer/orderers/${USERNAME}/msp/config.yaml"
        cp "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/signcerts/"* "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/signcerts/server.crt"
        cp "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/keystore/"* "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/keystore/server.key" 
        cp "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/tlscacerts/"* "${FILE}/organizations/${ORG,,}-orderer/orderers/${USERNAME}/tls-msp/tlscacerts/ca.crt"
    done
    
    mkdir -p ${FILE}/organizations/${ORG,,}-orderer/users/admin
    export FABRIC_CA_CLIENT_HOME=${FILE}/organizations/${ORG,,}-orderer/users/admin
    export FABRIC_CA_CLIENT_TLS_CERTFILES=${FILE}/servers/ca-${ORG}-orderer/ca-cert.pem
    export FABRIC_CA_CLIENT_MSPDIR=msp

    fabric-ca-client enroll -d -u https://admin-${ORG,,}:admin${ORG,,}pw@0.0.0.0:${PORT}
    sleep 1 
    awk 'NR>1{print $2}' $input | while read -r USERNAME
    do 
        cp ${FILE}/organizations/${ORG,,}-orderer/users/admin/msp/signcerts/cert.pem ${FILE}/organizations/${ORG,,}-orderer/orderers/$USERNAME/msp/admincerts/${ORG,,}-admin-cert.pem
        cp "$FILE/organizations/${ORG,,}-orderer/msp/config.yaml"* "${FILE}/organizations/${ORG,,}-orderer/users/admin/msp/config.yaml"
    done
    mkdir -p "${FILE}/organizations/${ORG}-orderer/msp/tlscacerts"
    cp "${FILE}/servers/tls-ca-${ORG}-orderer/ca-cert.pem" "${FILE}/organizations/${ORG}-orderer/msp/tlscacerts/ca.crt"
}




function yaml_node {
    sed -e "s/\${PORT}/$1/g" \
        $WORKING_DIR/yamlfiles/config.yaml | sed -e $'s/\\\\n/\\\n          /g'
}