
#!/bin/bash


WORKING_DIR=/home/kevin/project


function yaml_channel {
    sed -e "s/\${ORD_PORT}/$1/g" \
        -e "s/\${ORG}/$2/g" \
        -e "s|FILE|$3|g" \
        -e "s/\${NAME}/$4/g" \
        $WORKING_DIR/yaml files/configtx.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function config_channel() {    
        mkdir -p $WORKING_DIR/configtx/${ORG}
        > $WORKING_DIR/configtx/${ORG}/configtx.yaml
        echo "$(yaml_channel ${ORD_PORT} ${ORG,,} ${FILE} ${NAME})" > $WORKING_DIR/configtx/${ORG}/configtx.yaml
}
