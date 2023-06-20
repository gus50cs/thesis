#!/bin/bash


WORKING_DIR=/home/kevin/project


function yaml_config {
    sed -e "s/\${PORT}/$1/g" \
        -e "s/\${CANAME}/$2/g" \
        -e "s/\${USERNAME}/$3/g" \
        -e "s/\${PASSWORD}/$4/g" \
        -e "s/\${LISTENINGPORT}/$5/g" \
        -e "s/\${HOSTS}/$6/g" \
        $WORKING_DIR/yamlfiles/fabric-ca-server-config.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function config() {
    
    if [ ! -d "${FILE,,}" ]; then
        
        mkdir -p ${FILE,,}
        >${FILE}/fabric-ca-server-config.yaml
        echo "$(yaml_config ${PORT} ${NAME} ${USERNAME} ${PASSWORD} $LISTENINGPORT $HOSTS)" > $FILE/fabric-ca-server-config.yaml
        #echo $(basename ${FILE,,})
        if [[  ${NAME}  ==  *"tls"* ]]; then
            #echo "MPIKE STO IF"
            echo "$(sed "273,280d" ${FILE}/fabric-ca-server-config.yaml)" > $FILE/fabric-ca-server-config.yaml
        fi
    fi
}

function yaml_docker {
    sed -e "s/\${NAME}/$1/g" \
        -e "s/\${PORT}/$2/g" \
        -e "s/\${USERNAME}/$3/g" \
        -e "s/\${PASSWORD}/$4/g" \
        -e "s/\${LISTENINGPORT}/$5/g" \
        $WORKING_DIR/yamlfiles/ca-docker.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function docker() {
    FILE1=${FILE}/${NAME}.yaml
    if [ ! -d "${FILE1,,}" ]; then
        >${FILE}/${NAME}.yaml
        echo "$(yaml_docker ${NAME} ${PORT} ${USERNAME} ${PASSWORD} ${LISTENINGPORT})" > $FILE/${NAME}.yaml
    fi

}
