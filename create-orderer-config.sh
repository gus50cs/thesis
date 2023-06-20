
#!/bin/bash


WORKING_DIR=/home/kevin/project


function yaml_orderer {
    sed -e "s/\${PORT}/$1/g" \
        -e "s/\${NAME}/$2/g" \
        -e "s/\${ORG}/$3/g" \
        -e "s|FILE|$4|g" \
        -e "s|LEDGER|$5|g" \
        -e "s|MSPATH|$6|g" \
        -e "s/\${MSPID}/$7/g" \
        -e "s/\${OPERADDRESS}/$8/g" \
        -e "s/\${ADMIN_PORT}/$9/g" \
        $WORKING_DIR/yamlfiles/orderer.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function yaml_orderer_docker {
    sed -e "s/\${PORT}/$1/g" \
        -e "s/\${ORG}/$2/g" \
        -e "s/\${NAME}/$3/g" \
        -e "s/\${ADMIN_PORT}/$4/g" \
        -e "s/\${OPERADDRESS}/$5/g" \
        -e "s|FILE|$6|g" \
        $WORKING_DIR/yamlfiles/orderer-docker.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function config_orderer() {    
        > ${WORKING_DIR}/organizations/${ORG,,}-orderer/orderers/${NAME}/orderer.yaml
        echo "$(yaml_orderer ${PORT} ${NAME} ${ORG,,} ${FILE} $LEDGER $MSPATH $MSPID ${OPERADDRESS} ${ADMIN_PORT})" > ${WORKING_DIR}/organizations/${ORG,,}-orderer/orderers/${NAME}/orderer.yaml
}


function config_orderer_docker() {    
        > ${WORKING_DIR}/organizations/${ORG,,}-orderer/orderers/${NAME}/orderer-docker.yaml
        echo "$(yaml_orderer_docker ${PORT} ${ORG} ${NAME} ${ADMIN_PORT} ${OPERADDRESS} $FILE)" > ${WORKING_DIR}/organizations/${ORG,,}-orderer/orderers/${NAME}/orderer-docker.yaml
}