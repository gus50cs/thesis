
#!/bin/bash


WORKING_DIR=/home/kevin/project


function yaml_channel {
    sed -e "s/\${ORD_PORT}/$1/g" \
        -e "s|FILE|$2|g" \
        -e "s/\${ORD}/$3/g" \
        -e "s/\${NAME}/$4/g" \
        $WORKING_DIR/yamlfiles/configtx.yaml | sed -e $'s/\\\\n/\\\n          /g'
}


function config_channel() {    
        mkdir -p $WORKING_DIR/configtx/${CHANNEL_NAME}
        > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(yaml_channel ${ORD_PORT} ${FILE} $ORD ${ORDERER_NAME})" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(sed "460d" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml)" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(sed "72,97d" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml)" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
}

function yaml_org {
        new_txt=$(sed -n "72,97{s/\${ORG}/$1/g;s|FILE|$2|g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num1=$3
        sed -i "${line_num1} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
        new_txt=$(sed -n "460{s/\${ORG}/$1/g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num2=$4
        sed -i "${line_num2} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
}

function org_channel() {    
        yaml_org ${org,,} $FILE ${line_num1} ${line_num2}
}

