#!/bin/bash

# 获取脚本工作目录绝对路径
export CLASH_TOP_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# 加载env变量文件
source ${CLASH_TOP_DIR}/env.conf

# 添加可执行权限
chmod +x ${CLASH_TOP_DIR}/bin/*
chmod +x ${CLASH_TOP_DIR}/scripts/*
chmod +x ${CLASH_TOP_DIR}/tools/subconverter/subconverter

CONF_DIR="${CLASH_TOP_DIR}/conf"
Temp_Dir="${CLASH_TOP_DIR}/temp"
LOG_DIR="${CLASH_TOP_DIR}/logs"

# 将 CLASH_URL 变量的值赋给 URL 变量，并检查 CLASH_URL 是否为空
URL=${CLASH_URL:?Error: CLASH_URL variable is not set or empty}

# 获取 CLASH_SECRET 值，如果不存在则生成一个随机数
#Secret=${CLASH_SECRET:-$(openssl rand -hex 2)}

# 自定义action函数，实现通用action功能
success() {
	echo -en "\\033[60G[\\033[1;32m  OK  \\033[0;39m]\r"
	return 0
}

failure() {
	local rc=$?
	echo -en "\\033[60G[\\033[1;31mFAILED\\033[0;39m]\r"
	[ -x /bin/plymouth ] && /bin/plymouth --details
	return $rc
}

action() {
	local STRING rc

	STRING=$1
	echo -n "$STRING "
	shift
	"$@" && success $"$STRING" || failure $"$STRING"
	rc=$?
	echo
	return $rc
}

# 判断命令是否正常执行 函数
if_success() {
	local exe_result=$3
	if [ $exe_result -eq 0 ]; then
		action "$1" /bin/true
	else
		action "$2" /bin/false
		exit 1
	fi
}

## 获取CPU架构信息
# Source the script to get CPU architecture
source ${CLASH_TOP_DIR}/scripts/get_cpu_arch.sh

# Check if we obtained CPU architecture
if [[ -z "${CPU_ARCH}" ]]; then
	echo "Failed to obtain CPU architecture"
	exit 1
fi

# 临时取消环境变量
unset http_proxy
unset https_proxy
unset no_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset NO_PROXY

# 拉取更新config.yml文件
echo -e '\n正在下载Clash配置文件...'

Text1="yaml配置文件下载成功！"
Text2="yaml配置文件下载失败，退出启动！"

CONF_XML=config.yaml
CONF_XML_TMP=config_temp.yaml
CONF_XML_SUBCONVERT_TMP=config_subconvert_temp.yaml
# 尝试使用curl进行下载
curl -L -k -sS --retry 5 -m 10 -o ${CONF_DIR}/${CONF_XML_TMP} $URL

exe_result=$?
if [ $exe_result -ne 0 ]; then
	# 如果使用curl下载失败，尝试使用wget进行下载
	for i in {1..3}
	do
		wget -q --no-check-certificate -O ${CONF_DIR}/${CONF_XML_TMP} $URL
		exe_result=$?
		if [ $exe_result -eq 0 ]; then
			break
		else
			continue
		fi
	done
fi
if_success $Text1 $Text2 $exe_result

## 判断config xml是否符合clash配置文件标准
if [[ ${CPU_ARCH} =~ "x86_64" || ${CPU_ARCH} =~ "amd64"  ]]; then
	echo -e '\n判断订阅内容是否符合clash配置文件标准:'
	source ${CLASH_TOP_DIR}/scripts/clash_profile_conversion.sh
	sleep 3
fi

# Configure Clash Dashboard
dashboard="${CLASH_TOP_DIR}/dashboard/public"
sed -ri "s@^# external-ui:.*@external-ui: ${dashboard}@g" ${CONF_DIR}/${CONF_XML}
sed -r -i '/^secret: /s@(secret: ).*@\1'${Secret}'@g' ${CONF_DIR}/${CONF_XML}


## 启动Clash服务
echo -e '\n正在启动Clash服务...'
Text5="服务启动成功！"
Text6="服务启动失败！"
if [[ ${CPU_ARCH} =~ "x86_64" || ${CPU_ARCH} =~ "amd64"  ]]; then
	${CLASH_TOP_DIR}/bin/clash-linux-amd64 -d ${CONF_DIR}
	exe_result=$?
	if_success $Text5 $Text6 $exe_result
elif [[ ${CPU_ARCH} =~ "aarch64" ||  ${CPU_ARCH} =~ "arm64" ]]; then
	nohup ${CLASH_TOP_DIR}/bin/clash-linux-arm64 -d ${CONF_DIR} &> ${LOG_DIR}/clash.log &
	exe_result=$?
	if_success $Text5 $Text6 $exe_result
elif [[ ${CPU_ARCH} =~ "armv7" ]]; then
	nohup ${CLASH_TOP_DIR}/bin/clash-linux-armv7 -d ${CONF_DIR} &> ${LOG_DIR}/clash.log &
	exe_result=$?
	if_success $Text5 $Text6 $exe_result
else
	echo -e "\033[31m\n[ERROR] Unsupported CPU Architecture！\033[0m"
	exit 1
fi

# Output Dashboard access address and Secret
echo ''
echo -e "Clash Dashboard url: http://127.0.0.1:9090/ui"
echo -e "Secret: ${Secret}"
echo ''
