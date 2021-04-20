#!/bin/bash

curl="curl -s -f"
if [ -f /tls/client/ca.crt ]; then
  curl="$curl --cacert /tls/client/ca.crt"
fi
if [ -f /tls/client/tls.crt ] && [ /tls/client/tls.key ]; then
  curl="$curl --cert /tls/client/tls.crt --key /tls/client/tls.key"
fi

add_node(){
  config=/config/linstor_satellite.toml
  config_type=${NODE_ENCRYPTION_TYPE:-$(awk -F= '$1 == "  type" {gsub("\"","",$2); print $2}' "$config")}
  config_port=${NODE_PORT:-$(awk -F= '$1 == "  port" {gsub("\"","",$2); print $2}' "$config")}
  config_type=${config_type:-Plain}
  config_port=${config_port:-3366}

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
  
  if $curl "$LS_CONTROLLERS/v1/nodes/${NODE_NAME}"; then
    echo "Node $NODE_NAME exists in cluster"
    return 0
  fi

  $curl -d "$node_json" "$LS_CONTROLLERS/v1/nodes"
}

# TODO: incompleted
add_storage_pools(){
  storage_pool_json="$(cat <<EOT
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

  $curl -d "$storage_pool_json" $LS_CONTROLLERS/v1/nodes/${NODE_NAME}/storage-pools
}

add_node
add_storage_pools
