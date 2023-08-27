# 开启系统代理
function proxy_on() {
	export http_proxy=http://127.0.0.1:4780
	export https_proxy=http://127.0.0.1:4780
	export no_proxy=127.0.0.1,localhost
	export HTTP_PROXY=http://127.0.0.1:4780
	export HTTPS_PROXY=http://127.0.0.1:4780
 	export NO_PROXY=127.0.0.1,localhost
	echo -e "\033[32m[√] 已开启代理\033[0m"
}

# 关闭系统代理
function proxy_off(){
	unset http_proxy
	unset https_proxy
	unset no_proxy
	unset HTTP_PROXY
	unset HTTPS_PROXY
	unset NO_PROXY
        unset ftp_proxy
        unset FTP_PROXY
        unset ALL_PROXY
        unset all_proxy
	echo -e "\033[32m[√] 已关闭代理\033[0m"
}
