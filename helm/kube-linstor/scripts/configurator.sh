#!/bin/bash
set -e

load_params() {
  echo "Loading parameters"
  curl="curl -sS -f"
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
  echo "Checking if node $NODE_NAME already exists in cluster"
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}" >/dev/null; then
    echo "Node $NODE_NAME exists in cluster, skip adding..."
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

  echo "Checking if interface $interface_name already exists on node $NODE_NAME"
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces/$1" >/dev/null; then
    echo "Interface $interface_name already exists on node $NODE_NAME, updating..."
    (set -x; $curl -X PUT -d "$interface_json" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces/$interface_name")
  else
    echo "Interface $interface_name does not exists on node $NODE_NAME, adding..."
    (set -x; $curl -X POST -d "$interface_json" "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}/net-interfaces")
  fi
  echo
}

# TODO: incompleted
add_storage_pools(){
  local storage_pool_json="$(cat <<EOT
{
  "name": "lvm-thin",
  "providerKind": "LVM_THIN",
  "props": {
    "StorDriver/LvmVg": "drbdpool",
    "StorDriver/ThinPool": "thinpool"
  }
}

EOT
  )"

  (set -x; $curl -X POST -d "$storage_pool_json" $LS_CONTROLLERS/v1/nodes/${NODE_NAME}/storage-pools)
}

load_params
wait_satellite
wait_controller
register_node
configure_interface "data" "10.29.0.0/16"

#add_storage_pools

echo "Configuration has been successfully finished"
set -x
exec sleep infinity
