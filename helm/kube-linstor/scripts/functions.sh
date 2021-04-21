#!/bin/bash
set -e

load_params() {
  echo "Loading parameters"
  case "" in
    $NODE_NAME)
    echo "Variable NODE_NAME is not set!"
    exit 1
    ;;
    $NODE_IP)
    echo "Variable NODE_IP is not set!"
    exit 1
    ;;
    $LS_CONTROLLERS)
    echo "Variable LS_CONTROLLERS is not set!"
    exit 1
    ;;
  esac
  curl="curl -sS -f -H Content-Type:application/json"
  if [ -f /tls/client/ca.crt ]; then
    curl="$curl --cacert /tls/client/ca.crt"
  fi
  if [ -f /tls/client/tls.crt ] && [ /tls/client/tls.key ]; then
    curl="$curl --cert /tls/client/tls.crt --key /tls/client/tls.key"
  fi
  config=/config/linstor_satellite.toml
  config_type=${NODE_ENCRYPTION_TYPE:-$(awk -F= '$1 == "  type" {gsub("\"","",$2); print $2}' "$config")}
  config_port=${NODE_PORT:-$(awk -F= '$1 == "  port" {gsub("\"","",$2); print $2}' "$config")}
  config_type=${config_type:-Plain}
  config_port=${config_port:-3366}
  controller_port=$(echo "$LS_CONTROLLERS" | awk -F'[/:]+' '{print $NF}')
  controller_address=$(echo "$LS_CONTROLLERS" | awk -F'[/:]+' '{print $(NF-1)}')
}

wait_tcp_port(){
  until printf "" 2>/dev/null >"/dev/tcp/$1/$2"; do
    sleep 1
  done
}

wait_satellite(){
  echo "Waiting linstor-satellite to launch on localhost:$config_port..."
  wait_tcp_port localhost "$config_port"
  echo "Service linstor-satellite launched"
}

wait_controller(){
  echo "Waiting linstor-controller to launch on $controller_address:$controller_port..."
  wait_tcp_port "$controller_address" "$controller_port"
  echo "Service linstor-controller launched"
}

register_node(){
  echo "Checking if node $NODE_NAME exists in cluster"
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}" >/dev/null; then
    echo "Node $NODE_NAME already exists in cluster, skip adding..."
    return 0
  fi
  echo "Node $NODE_NAME does not exists in cluster"

  echo "Adding node $NODE_NAME to the cluster"
  node_json="$(cat <<EOT
{
  "name": "",
  "type": "satellite",
  "net_interfaces": [
    {
      "name": "default",
      "address": "$NODE_IP",
      "satellite_port": $config_port,
      "satellite_encryption_type": "$config_type"
    }
  ]
}
EOT
  )"
  
  (set -x; $curl -X POST -d "$node_json" "$LS_CONTROLLERS/v1/nodes")
  echo
}

src_ip(){
  ip -o route get "$1" | awk -F "src " '{ gsub(" .*", "", $2); print $2 }'
}

configure_interface(){
  local interface_name=$1
  local interface_ip=$(src_ip $2)

  echo "Compuited address for interface $interface_name: $interface_ip (determined from $2)"

  if [ "$interface_ip" = "$NODE_IP" ]; then
    echo "IP address $interface_ip matches the default node IP address, assuming it does not existing on the node, skipping..."
    return 0
  fi

  local interface_json="$(cat <<EOT
{
  "name": "${interface_name}",
  "address": "${interface_ip}"
}
EOT
  )"

  echo "Checking if interface $interface_name exists on node $NODE_NAME"
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces/$interface_name" >/dev/null; then
    echo "Interface $interface_name already exists on node $NODE_NAME, updating..."
    (set -x; $curl -X PUT -d "$interface_json" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces/$interface_name")
  else
    echo "Interface $interface_name does not exists on node $NODE_NAME, adding..."
    (set -x; $curl -X POST -d "$interface_json" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces")
  fi
  echo
}

configure_storage_pool(){
  local sp_name=$1
  local sp_provider=$2
  local sp_props_json=$3

  local sp_json="$(cat <<EOT
{
  "storage_pool_name": "$sp_name",
  "provider_kind": "$sp_provider",
  "props": $sp_props_json
}

EOT
  )"

  echo "Checking if storage-pool $sp_name exists on node $NODE_NAME"
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/storage-pools/$sp_name" >/dev/null; then
    echo "Storage-pool $sp_name already exists on node $NODE_NAME, updating..."
    (set -x; $curl -X PUT -d "{\"override_props\": $sp_props_json}" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/storage-pools/$sp_name")
  else
    echo "Storage-pool $sp_name does not exists on node $NODE_NAME, adding..."
    (set -x; $curl -X POST -d "$sp_json" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/storage-pools")
  fi
  echo
}

finish(){
  echo "Configuration has been successfully finished"
  exec sleep infinity
}


