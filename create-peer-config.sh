#!/bin/bash


WORKING_DIR=/home/kevin/project


function yaml_core {
    sed -e "s/\${PORT}/$1/g" \
        -e "s/\${NAMEPEER}/$2/g" \
        -e "s/\${ORG}/$3/g" \
        -e "s/\${CHAINCODE_PORT}/$4/g" \
        -e "s/\${ADDRESSES}/ /g" \
        -e "s|\${LEADER}|$5|g" \
        -e "s|FILE|$6|g" \
        -e "s|LEDGER|$7|g" \
        -e "s|MSPATH|$8|g" \
        -e "s/\${OPERADDRESS}/${9}/g" \
        -e "s/\${MSPID}/${10}/g" \
        $WORKING_DIR/yamlfiles/core.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function yaml_couch {
    sed -e "s/\${COUCHPORT}/$1/g" \
        -e "s/\${ORG}/$2/g" \
        -e "s/\${NAMEPEER}/$3/g" \
        $WORKING_DIR/yamlfiles/couchdb.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function yaml_peer {
    sed -e "s/\${PORT}/$1/g" \
        -e "s/\${ORG}/$2/g" \
        -e "s/\${NAMEPEER}/$3/g" \
        -e "s|FILE|$4|g" \
        -e "s/\${CHAINCODE_PORT}/$5/g" \
        $WORKING_DIR/yamlfiles/peer.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function yaml_vm {
    sed -e "s/\${ORG}/$1/g" \
        -e "s/\${NAMEPEER}/$2/g" \
        -e "s|FILE|$3|g" \
        $WORKING_DIR/yamlfiles/vm-peer.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function config_couch() {    
        > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/couchdb.yaml
        echo "$(yaml_couch ${COUCHPORT} ${ORG} ${NAMEPEER})" > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/couchdb.yaml
}

function config_core() {    
        > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/core.yaml
        echo "$(yaml_core ${PORT} ${NAMEPEER} ${ORG} ${CHAINCODE_PORT} ${LEADER} ${FILE} $LEDGER $MSPATH ${OPERADDRESS} $MSPID)" > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/core.yaml
}

function config_peer() {    
        > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/peer.yaml
        echo "$(yaml_peer ${PORT} ${ORG} ${NAMEPEER} ${FILE} ${CHAINCODE_PORT} )" > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/peer.yaml
}

function config_vm_peer() {    
        > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/vm-peer.yaml
        echo "$(yaml_vm ${ORG} ${NAMEPEER} ${FILE} )" > ${WORKING_DIR}/organizations/${ORG,,}/peers/${NAMEPEER}/vm-peer.yaml
}
