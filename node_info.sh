#!/bin/bash
# Default variables
language="EN"
raw_output="false"
software_name=""

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about a node from Polkadot ecosystem."
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help               show help page"
		echo -e "  -l, --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                           LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -ro, --raw-output        the raw JSON output"
		echo -e "  -sn NAME                 the NAME of a service file or a Docker container"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Polkadot/blob/main/node_info.sh - script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo -e "https://learning.1package.io — guides and articles"
		echo -e "https://teletype.in/@letskynode — guides and articles"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	-sn*)
		if ! grep -q "=" <<< $1; then shift; fi
		software_name=`option_value $1`
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
api_request() { wget -qO- -t 1 -T 5 --header "Content-Type: application/json" --post-data '{"id":1, "jsonrpc":"2.0", "method": "'$1'"}' "http://localhost:$2/" | jq; }
main() {
	# Texts
	if [ "$language" = "RU" ]; then
		local t_nn="\nНазвание ноды:               ${C_LGn}%s${RES}"
		local t_nv="Версия ноды:                 ${C_LGn}%s${RES}"
		
		local t_p_net="\nСеть:                        ${C_LGn}%s${RES}"
		local t_p_ni=" ID ноды:                    ${C_LGn}%s${RES}"
		local t_p_lb=" Последний блок:             ${C_LGn}%d${RES}"
		local t_p_sy1=" Нода синхронизирована:      ${C_LR}нет${RES}"
		local t_p_sy2=" Осталось нагнать:           ${C_LR}%d-%d=%d (около %.2f мин.)${RES}"
		local t_p_sy3=" Нода синхронизирована:      ${C_LGn}да${RES}"
		
		local t_r_net="\n\nСеть:                        ${C_LGn}%s${RES}"
		local t_r_ni=" ID ноды:                    ${C_LGn}%s${RES}"
		local t_r_lb=" Последний блок:             ${C_LGn}%d${RES}"
		local t_r_sy1=" Нода синхронизирована:      ${C_LR}нет${RES}"
		local t_r_sy2=" Осталось нагнать:           ${C_LR}%d-%d=%d (около %.2f мин.)${RES}"
		local t_r_sy3=" Нода синхронизирована:      ${C_LGn}да${RES}"
		
		local t_e_sn1="\n${C_R}Вы не указали название сервисного файла или Docker контейнера!${RES}\n"
		local t_e_sn2="\n${C_R}Сервисный файл или Docker контейнер с именем ${C_LY}%s${C_R} не найден!${RES}\n"
		
	# Send Pull request with new texts to add a language - https://github.com/SecorD0/Polkadot/blob/main/node_info.sh
	#elif [ "$language" = ".." ]; then
	else
		local t_nn="\nMoniker:                  ${C_LGn}%s${RES}"
		local t_nv="Node version:             ${C_LGn}%s${RES}"
		
		local t_p_net="\nNetwork:                  ${C_LGn}%s${RES}"
		local t_p_ni=" Node ID:                 ${C_LGn}%s${RES}"
		local t_p_lb=" Latest block height:     ${C_LGn}%s${RES}"
		local t_p_sy1=" Node is synchronized:    ${C_LR}no${RES}"
		local t_p_sy2=" It remains to catch up:  ${C_LR}%d-%d=%d (about %.2f min.)${RES}"
		local t_p_sy3=" Node is synchronized:    ${C_LGn}yes${RES}"
		
		local t_r_net="\n\nNetwork:                  ${C_LGn}%s${RES}"
		local t_r_ni=" Node ID:                 ${C_LGn}%s${RES}"
		local t_r_lb=" Latest block height:     ${C_LGn}%s${RES}"
		local t_r_sy1=" Node is synchronized:    ${C_LR}no${RES}"
		local t_r_sy2=" It remains to catch up:  ${C_LR}%d-%d=%d (about %.2f min.)${RES}"
		local t_r_sy3=" Node is synchronized:    ${C_LGn}yes${RES}"
		
		local t_e_sn1="\n${C_R}You didn't specify the name of the service file or the Docker container!${RES}\n"
		local t_e_sn2="\n${C_R}No service file or Docker container named ${C_LY}%s${C_R} found!${RES}\n"
	fi

	# Actions
	sudo apt install jq bc -y &>/dev/null
	
	if [ ! -n "$software_name" ]; then
		printf_n "$t_e_sn1"
		return 1 2>/dev/null; exit 1
	fi
	
	if systemctl cat "$software_name" 2>&1 | grep -q "No files"; then
		if docker inspect "$software_name" 2>&1 | grep -q "No such object:"; then
			printf_n "$t_e_sn2" "$software_name"
			return 1 2>/dev/null; exit 1
		else
			local moniker=`docker logs "$software_name" | grep Node | tail -1 | grep -oPm1 "(?<=Node name: )([^%]+)(?=$)"`
			local service_file="false"
		fi
	else
		local moniker=`sudo journalctl -u "$software_name" | grep Node | tail -1 | grep -oPm1 "(?<=Node name: )([^%]+)(?=$)"`
		local service_file="true"
	fi
	
	if [ "$service_file" = "true" ]; then
		p_port=`sudo systemctl cat "$software_name" | grep rpc-port | head -1 | grep -oE '[0-9]+'`
	else
		p_port=`docker inspect "$software_name" | jq ".[0].Args" | grep -A1 rpc-port | grep -oE '[0-9]+' | head -1`
	fi
	if [ ! -n "$p_port" ]; then
		p_port=9933
	fi
	
	if [ "$service_file" = "true" ]; then
		r_port=`sudo systemctl cat "$software_name" | grep rpc-port | tail -1 | grep -oE '[0-9]+'`
	else
		r_port=`docker inspect "$software_name" | jq ".[0].Args" | grep -A1 rpc-port | grep -oE '[0-9]+' | tail -1`
	fi
	if [ ! -n "$r_port" ] || [ "$r_port" -eq "$p_port" ]; then
		r_port=9934
	fi
	
	local node_version=`api_request system_version $p_port | jq -r ".result"`
	
	local p_network=`api_request system_chain $p_port | jq -r ".result"`
	local p_node_id=`api_request system_localPeerId $p_port | jq -r ".result"`
	local p_latest_block_height=`api_request system_syncState $p_port | jq -r ".result.currentBlock"`
	local p_catching_up=`api_request system_health $p_port | jq -r ".result.isSyncing"`
	
	local r_network=`api_request system_chain $r_port | jq -r ".result"`
	local r_node_id=`api_request system_localPeerId $r_port | jq -r ".result"`
	local r_latest_block_height=`api_request system_syncState $r_port | jq -r ".result.currentBlock"`
	local r_catching_up=`api_request system_health $r_port | jq -r ".result.isSyncing"`
	
	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '[{"moniker": "%s", "node_version": "%s", "networks": [{"network": "%s", "node_id": "%s", "latest_block_height": %d, "catching_up": %b}, {"network": "%s", "node_id": "%s", "latest_block_height": %d, "catching_up": %b}]}]' \
"$moniker" \
"$node_version" \
"$p_network" \
"$p_node_id" \
"$p_latest_block_height" \
"$p_catching_up" \
"$r_network" \
"$r_node_id" \
"$r_latest_block_height" \
"$r_catching_up"
	else
		printf_n "$t_nn" "$moniker"
		printf_n "$t_nv" "$node_version"
		
		printf_n "$t_p_net" "$p_network"
		printf_n "$t_p_ni" "$p_node_id"
		printf_n "$t_p_lb" "$p_latest_block_height"
		if [ "$p_catching_up" = "true" ]; then
			local p_current_block=`api_request system_syncState $p_port | jq ".result.highestBlock"`
			local p_diff=`bc -l <<< "$p_current_block-$p_latest_block_height"`
			local p_takes_time=`bc -l <<< "$p_diff/60/60"`
			printf_n "$t_p_sy1"
			printf_n "$t_p_sy2" "$p_current_block" "$p_latest_block_height" "$p_diff" "$p_takes_time"		
		else
			printf_n "$t_p_sy3"
		fi
		
		printf_n "$t_r_net" "$r_network"
		printf_n "$t_r_ni" "$r_node_id"
		printf_n "$t_r_lb" "$r_latest_block_height"
		if [ "$r_catching_up" = "true" ]; then
			local r_current_block=`api_request system_syncState $r_port | jq ".result.highestBlock"`
			local r_diff=`bc -l <<< "$r_current_block-$r_latest_block_height"`
			local r_takes_time=`bc -l <<< "$r_diff/350/60"`
			printf_n "$t_r_sy1"
			printf_n "$t_r_sy2" "$r_current_block" "$r_latest_block_height" "$r_diff" "$r_takes_time"		
		else
			printf_n "$t_r_sy3"
		fi
		printf_n
	fi
}

main
