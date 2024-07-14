#!/bin/bash

# 加载clash配置文件内容
raw_content=$(cat ${CONF_DIR}/${CONF_XML_TMP})

# 判断订阅内容是否符合clash配置文件标准
if echo "$raw_content" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'; then
    echo "config content is valid."
    mv ${CONF_DIR}/${CONF_XML_TMP} ${CONF_DIR}/${CONF_XML}
else
    # 判断订阅内容是否为base64编码
    if echo "$raw_content" | base64 -d &>/dev/null; then
        # 订阅内容为base64编码，进行解码
        decoded_content=$(echo "$raw_content" | base64 -d)

        # 判断解码后的内容是否符合clash配置文件标准
        if echo "$decoded_content" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'; then
            echo "解码后的内容符合clash标准"
            echo "$decoded_content" > ${CONF_DIR}/${CONF_XML}
        else
            echo "解码后的内容不符合clash标准，尝试将其转换为标准格式"
            ${CLASH_TOP_DIR}/tools/subconverter/subconverter -g &>> ${CLASH_TOP_DIR}/logs/subconverter.log
            converted_content=$(cat ${CONF_DIR}/${CONF_XML_SUBCONVERT_TMP})

            # 判断转换后的内容是否符合clash配置文件标准
            if echo "$converted_content" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'; then
                echo "$converted_content" > ${CONF_DIR}/${CONF_XML}
                echo "配置文件已成功转换成clash标准格式"
            else
                echo "配置文件转换标准格式失败"
                exit 1
            fi
        fi
    else
        echo "config content is invalid."
        exit 1
    fi
fi
