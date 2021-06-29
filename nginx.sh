#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear
VER=1.0
echo "#############################################################"
echo "# Install Nginx or Set Nginx.conf for Ubuntu"
echo "#"
echo "# Version:$VER"
echo "#############################################################"
echo ""

__INTERACTIVE=""
if [ -t 1 ] ; then
    __INTERACTIVE="1"
fi

__green(){
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[1;31;32m'
    fi
    printf -- "$*"
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[0m'
    fi
}

__red(){
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[1;31;40m'
    fi
    printf -- "$*"
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[0m'
    fi
}

__yellow(){
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[1;31;33m'
    fi
    printf -- "$*"
    if [ "$__INTERACTIVE" ] ; then
        printf '\033[0m'
    fi
}

function start_set(){
	echo "please choose the type of your want(Install Nginx: 1  ,  Set Nginx.conf: 2  ,  All: 3):"
    read -p "your choice(1 or 2 or 3):" type_choice
    clear
	echo "#############################################################"
	echo "# Install Nginx or Set Nginx.conf for Ubuntu"
	echo "#"
	echo "# Version:$VER"
	echo "#############################################################"
    if [ "$type_choice" = "1" ]; then
    	# 卸载旧包
		apt-get remove nginx nginx-common

		# 安装
		apt-get install nginx
	elif [ "$type_choice" = "2" ]; then
		set_conf
	elif [ "$type_choice" = "3" ]; then
    	# 卸载旧包
		apt-get remove nginx nginx-common

		# 安装
		apt-get install nginx

		set_conf
	else
		exit 1
	fi
}



function get_ip(){
    echo "Preparing, Please wait a moment..."
	echo -e ''
    IP=`curl -s checkip.dyndns.com | cut -d' ' -f 6  | cut -d'<' -f 1`
    # 判断获取IP是否为空
    if [ -z $IP ]; then
        IP=`curl -s ifconfig.me/ip`
    fi
}

function set_conf(){
	if [ -e /etc/nginx/nginx.conf ]; then
		get_ip
		RootPath="/var/www/html"
		echo -e "Default path of conf file: [$(__yellow ${RootPath})]"
		read -p "press ENTER to comfirm or enter new path: " NewRoot
		if [ $NewRoot ]; then
			RootPath=$NewRoot
		fi
		echo -e ''
		echo -e "ip address info: [$(__yellow ${IP})]"
		read -p "press ENTER to comfirm or enter IP address: " NewIP
		if [ $NewIP ]; then
			IP=$NewIP
		fi
		# domain name
		declare -a domains
		DomainCount=0
		echo -e ''
		read -p "How many domain name you want to set?(default_value:0): " SetdomainNum
		while [[ $SetdomainNum -gt 0 ]]; do
			read -p "Type the domain name: " DomainName
			if [ -z $DomainName ]; then
				break
			else
				domains[$DomainCount]=$DomainName
				let "DomainCount++"
				let "SetdomainNum--"
			fi
		done
		echo -e ''
		echo "Would you want to set SSL?"
		read -p "yes or no?(default_value:no): " SetSSL
		if [ "$SetSSL" = "yes" ]; then
			read -p "SSL PEM path(can not be empty): " SSLPEM
			read -p "SSL KEY path(can not be empty): " SSLKEY
			if [ -z $SSLPEM ] || [ -z $SSLKEY ]; then
				echo -e ''
				echo "$(__red "can not to set SSL")"
				read -p "press ENTER to continue or enter any key to leave: " ConfirmCon
				if [ -z $ConfirmCon ]; then
					conf_confirm80
				else
					echo "$(__red "Not to set")"
					exit
				fi
			else
				echo -e ''
				echo "Would you want to set HTTP redirect to HTTPS?"
				read -p "yes or no?(default_value:no): " SetJump
				if [ "$SetJump" = "yes" ]; then
					read -p "Please enter the HTTP redirect address: " JumpAddress
					if [ $JumpAddress ]; then
		SerRewrite="rewrite ^(.*) https://${JumpAddress}\$1 permanent;"
					else
						echo "$(__red "redirect address is empty")"
		SerRewrite="location / {
			root ${RootPath};
			index index.html index.htm;
			error_page 404 /404.html;
			error_page 500 502 503 504 /404.html;
		}"
					fi
				fi
				conf_confirm443
			fi
		else
			conf_confirm80
		fi
	else
		echo -e "/etc/nginx/nginx.conf [$(__red "Not found")]"
		exit 1
	fi
}

function conf_confirm80(){
	if [ ${#domains[*]} -gt 0 ]; then
		outputdomain="${domains[*]} ${IP}"
	else
		outputdomain="${IP}"
	fi
	echo -e ''
	echo "#############################################################"
	echo "# IP or Host name"
	echo "#"
	echo "# $(__yellow ${outputdomain})"
	echo "#############################################################"
	read -p "press ENTER to comfirm or enter any key to leave: " ConfirmSet
	if [ -z $ConfirmSet ]; then
	SetServer="server {
		listen	80;
		server_name	${outputdomain};

		location / {
			root ${RootPath};
			index index.html index.htm;
			error_page 404 /404.html;
			error_page 500 502 503 504 /404.html;
		}
	}"
		output
		echo "$(__green "Already done")"
	else
		echo "$(__red "Not to set")"
		exit
	fi
}

function conf_confirm443(){
	if [ ${#domains[*]} -gt 0 ]; then
		outputdomain="${domains[*]} ${IP}"
	else
		outputdomain="${IP}"
	fi
	echo -e ''
	echo "#############################################################"
	echo "# IP or Host name"
	echo "#"
	echo "# $(__yellow ${outputdomain})"
	echo "#############################################################"
	read -p "press ENTER to comfirm or enter any key to leave: " ConfirmSet
	if [ -z $ConfirmSet ]; then
	SetServer="server {
		listen	80;
		server_name	${outputdomain};

		${SerRewrite}
	}
	### HTTPS server
	server {
		listen	443 ssl;
		listen	[::]:443 ssl;
		server_name ${outputdomain};

		ssl_certificate ${SSLPEM};
		ssl_certificate_key ${SSLKEY};

		ssl_session_timeout	5m;

		location / {
			root ${RootPath};
			index index.html index.htm;
			error_page 404 /404.html;
			error_page 500 502 503 504 /404.html;
		}
	}"
		output
		echo "$(__green "Already done")"
	else
		echo "$(__red "Not to set")"
		exit
	fi
}

function output(){
	cat > /etc/nginx/nginx.conf<<EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##
	
	sendfile off;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	# gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

	### HTTP server
	${SetServer}
}
EOF
}
# start
start_set