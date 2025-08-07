#!/bin/sh
set -e

# ==============================================================================
# FUNCTION DEFINITIONS
# ==============================================================================

# Add global torrc config from TORRC_* environment variables
process_global_torrc_variables() {
    echo "Processing custom GLOBAL TORRC environment variables..."
    echo "" >> /etc/tor/torrc
    echo "# Custom global configuration from TORRC_ environment variables" >> /etc/tor/torrc

    # Skip service-specific variables (TORRC_SERVICE_CONFIG format)
    for var in $(env | grep '^TORRC_' | grep -v '^TORRC_[^_]*_'); do
        config_key=$(echo "$var" | cut -d= -f1 | sed 's/^TORRC_//')
        config_value=$(echo "$var" | cut -d= -f2-)

        echo "$config_key $config_value" >> /etc/tor/torrc
        echo "-> Added GLOBAL Tor config: '$config_key $config_value'"
    done
    echo "" >> /etc/tor/torrc
}

# Create a hidden service and apply any service-specific torrc config
create_hidden_service() {
    local service_name=$1
    local target_host=$2
    local target_port=$3
    local virtual_port=$4

    if [ -z "$virtual_port" ]; then
        virtual_port=$target_port
    fi

    local service_dir="/var/lib/tor/${service_name}"
    if [ ! -d "$service_dir" ]; then
        if ! mkdir -p "$service_dir"; then
            echo "ERROR: Failed to create service directory: $service_dir"
            exit 1
        fi
        echo "Created directory for hidden service: $service_name"
    elif [ -f "${service_dir}/private_key" ] || [ -f "${service_dir}/hs_ed25519_secret_key" ]; then
        echo "Found existing keys for hidden service: $service_name"
    fi
    
    chown -R tor:tor "$service_dir"
    chmod 700 "$service_dir"

    echo "" >> /etc/tor/torrc
    echo "# Hidden Service: ${service_name}" >> /etc/tor/torrc
    echo "HiddenServiceDir $service_dir" >> /etc/tor/torrc
    echo "HiddenServicePort $virtual_port $target_host:$target_port" >> /etc/tor/torrc

    # Apply service-specific torrc config (TORRC_SERVICENAME_CONFIG format)
    local prefix="TORRC_${service_name}_"
    for var in $(env | grep "^$prefix"); do
        local config_key=$(echo "$var" | cut -d= -f1 | sed "s/^$prefix//")
        local config_value=$(echo "$var" | cut -d= -f2-)
        echo "$config_key $config_value" >> /etc/tor/torrc
        echo "  -> Applied '$service_name' specific config: '$config_key $config_value'"
    done

    echo "Configured hidden service '$service_name': forwarding port $virtual_port to $target_host:$target_port"
}

print_onion_addresses() {
    sleep 10
    echo "======== TOR HIDDEN SERVICES ========"
    for dir in /var/lib/tor/*/ ; do
        if [ -f "${dir}hostname" ]; then
            service_name=$(basename "$dir")
            onion_address=$(cat "${dir}hostname")
            echo "$service_name: $onion_address"
        fi
    done
    echo "===================================="
}

# ==============================================================================
# SCRIPT EXECUTION
# ==============================================================================

# Start with a clean torrc configuration.
cp /etc/tor/torrc.sample /etc/tor/torrc

# Process environment variables for hidden services
# Format: HS_[SERVICE_NAME]=[TARGET_HOST]:[TARGET_PORT]:[VIRTUAL_PORT]
# Example: HS_WEB=web:80:80
for var in $(env | grep ^HS_); do
    service_name=$(echo "$var" | cut -d= -f1 | sed 's/^HS_//')
    value=$(echo "$var" | cut -d= -f2-)
    target_host=$(echo "$value" | cut -d: -f1)
    target_port=$(echo "$value" | cut -d: -f2)
    virtual_port=$(echo "$value" | cut -d: -f3)
    
    if [ -z "$target_host" ] || [ -z "$target_port" ]; then
        echo "ERROR: Invalid service configuration for $service_name (missing host or port)"
        continue
    fi
    
    create_hidden_service "$service_name" "$target_host" "$target_port" "$virtual_port"
done

# Process command line arguments
# Format: [SERVICE_NAME]:[TARGET_HOST]:[TARGET_PORT]:[VIRTUAL_PORT]
for arg in "$@"; do
    if echo "$arg" | grep -q '.*:.*:.*'; then
        service_name=$(echo "$arg" | cut -d: -f1)
        target_host=$(echo "$arg" | cut -d: -f2)
        target_port=$(echo "$arg" | cut -d: -f3)
        virtual_port=$(echo "$arg" | cut -d: -f4)
        
        if [ -z "$service_name" ] || [ -z "$target_host" ] || [ -z "$target_port" ]; then
            echo "ERROR: Invalid service configuration in argument '$arg' (missing service name, host, or port)"
            continue
        fi
        
        create_hidden_service "$service_name" "$target_host" "$target_port" "$virtual_port"
    fi
done

process_global_torrc_variables

# Make sure the Tor data directory has correct permissions
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor

# Start printing onion addresses in the background
print_onion_addresses &

# If the first argument is "tor", run it as the tor user
if [ "$1" = "tor" ]; then
    shift
    echo "Starting Tor daemon..."
    exec su-exec tor tor "$@"
else
    # Otherwise, run the command as is
    exec "$@"
fi
