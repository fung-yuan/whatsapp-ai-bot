#!/bin/bash

# WAHA Client Manager
# Manages multiple WAHA instances for different clients

set -e

# Configuration
PORT_START=3000
PORT_END=3010
MAX_DISPLAY=5
# Determine script directory (resolving symlinks)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/.waha-clients.json"
SERVER_IP=$(hostname -I | awk '{print $1}')

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize config file if it doesn't exist
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"clients":[]}' > "$CONFIG_FILE"
    fi
}

# Generate random API key
generate_api_key() {
    echo "waha_$(openssl rand -hex 16)"
}

# Sanitize client name for container name
sanitize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_'
}

# Check if port is in use
is_port_used() {
    local port=$1
    docker ps --format '{{.Ports}}' | grep -q ":${port}->"
    return $?
}

# Get client by port
get_client_by_port() {
    local port=$1
    jq -r ".clients[] | select(.port==$port) | .name" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# Scan available ports
scan_ports() {
    echo -e "${CYAN}📊 Scanning Available Ports...${NC}"
    echo "─────────────────────────────────────────"
    
    local available_count=0
    local shown_count=0
    
    for port in $(seq $PORT_START $PORT_END); do
        if is_port_used "$port"; then
            client_name=$(get_client_by_port "$port")
            echo -e "${RED}❌ Port $port - IN USE${NC} (${client_name:-Unknown})"
        else
            if [ $shown_count -lt $MAX_DISPLAY ]; then
                echo -e "${GREEN}✅ Port $port - Available${NC}"
                ((shown_count++))
            fi
            ((available_count++))
        fi
    done
    
    echo "─────────────────────────────────────────"
    
    if [ $available_count -eq 0 ]; then
        echo -e "${RED}❌ All ports ($PORT_START-$PORT_END) are in use!${NC}"
        echo ""
        echo "Current clients: $(jq '.clients | length' "$CONFIG_FILE")"
        echo "Maximum capacity reached."
        echo ""
        return 1
    fi
    
    echo ""
    return 0
}

# Extract dashboard credentials from docker logs
get_dashboard_credentials() {
    local container=$1
    local max_attempts=10
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local username=$(docker logs "$container" 2>&1 | grep "WAHA_DASHBOARD_USERNAME" | head -1 | cut -d'=' -f2)
        local password=$(docker logs "$container" 2>&1 | grep "WAHA_DASHBOARD_PASSWORD" | head -1 | cut -d'=' -f2)
        
        if [ -n "$username" ] && [ -n "$password" ]; then
            echo "$username|$password"
            return 0
        fi
        
        sleep 1
        ((attempt++))
    done
    
    echo "admin|password_not_found"
    return 1
}

# Add new client
add_client() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        🆕 Add New WAHA Client          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! scan_ports; then
        echo ""
        read -p "Press Enter to return to menu..."
        return
    fi
    
    # Get client name
    read -p "Enter client name: " client_name
    if [ -z "$client_name" ]; then
        echo -e "${RED}❌ Client name cannot be empty${NC}"
        sleep 2
        return
    fi
    
    # Get port
    read -p "Select port [$PORT_START-$PORT_END]: " port
    if [ -z "$port" ]; then
        echo -e "${RED}❌ Port cannot be empty${NC}"
        sleep 2
        return
    fi
    
    if [ "$port" -lt "$PORT_START" ] || [ "$port" -gt "$PORT_END" ]; then
        echo -e "${RED}❌ Port must be between $PORT_START and $PORT_END${NC}"
        sleep 2
        return
    fi
    
    if is_port_used "$port"; then
        echo -e "${RED}❌ Port $port is already in use${NC}"
        sleep 2
        return
    fi
    
    # Generate API key
    read -p "Generate API key automatically? [Y/n]: " auto_key
    if [[ "$auto_key" =~ ^[Nn]$ ]]; then
        read -p "Enter API key: " api_key
    else
        api_key=$(generate_api_key)
        echo -e "${GREEN}✨ Generated API key: ${api_key}${NC}"
    fi
    
    # Create container name
    container_name="waha_$(sanitize_name "$client_name")"
    
    # Confirm
    echo ""
    echo "─────────────────────────────────────────"
    echo -e "${CYAN}📋 Client Configuration:${NC}"
    echo "─────────────────────────────────────────"
    echo "Name:       $client_name"
    echo "Port:       $port"
    echo "API Key:    $api_key"
    echo "Session:    default (auto)"
    echo "Container:  $container_name"
    echo ""
    read -p "Confirm and create? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Cancelled."
        sleep 2
        return
    fi
    
    # Create container
    echo ""
    echo -e "${YELLOW}🚀 Creating Docker container...${NC}"
    
    docker run -d \
        --name "$container_name" \
        -p "$port:3000" \
        -e "WAHA_API_KEY=$api_key" \
        -v "${container_name}_data:/app/.waha" \
        --restart always \
        devlikeapro/waha:latest > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create container${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}✅ Container started!${NC}"
    echo -e "${YELLOW}⏳ Waiting for WAHA to initialize...${NC}"
    sleep 8
    
    # Get dashboard credentials
    credentials=$(get_dashboard_credentials "$container_name")
    username=$(echo "$credentials" | cut -d'|' -f1)
    password=$(echo "$credentials" | cut -d'|' -f2)
    
    # Save to config
    timestamp=$(date -Iseconds)
    jq ".clients += [{
        \"name\": \"$client_name\",
        \"port\": $port,
        \"apiKey\": \"$api_key\",
        \"container\": \"$container_name\",
        \"dashboard\": {
            \"username\": \"$username\",
            \"password\": \"$password\"
        },
        \"created\": \"$timestamp\"
    }]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    # Display success
    clear
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Client Created Successfully!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "─────────────────────────────────────────"
    echo -e "${CYAN}🔐 Dashboard Access:${NC}"
    echo "─────────────────────────────────────────"
    echo "URL:        http://${SERVER_IP}:${port}/dashboard"
    echo "Username:   $username"
    echo "Password:   $password"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Save these credentials!${NC}"
    echo ""
    echo "─────────────────────────────────────────"
    echo -e "${CYAN}🔧 API Configuration:${NC}"
    echo "─────────────────────────────────────────"
    echo "Base URL:   http://${SERVER_IP}:${port}"
    echo "API Key:    $api_key"
    echo "Session:    default"
    echo ""
    echo "─────────────────────────────────────────"
    echo -e "${CYAN}📱 Next Steps:${NC}"
    echo "─────────────────────────────────────────"
    echo "1. Open the dashboard URL above"
    echo "2. Login with the credentials shown"
    echo "3. Scan WhatsApp QR code"
    echo "4. Update n8n workflow with port $port"
    echo ""
    read -p "Press Enter to return to menu..."
}

# List all clients
list_clients() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         📋 Active WAHA Clients         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    local client_count=$(jq '.clients | length' "$CONFIG_FILE")
    
    if [ "$client_count" -eq 0 ]; then
        echo "No clients configured yet."
        echo ""
        read -p "Press Enter to return to menu..."
        return
    fi
    
    local index=1
    jq -c '.clients[]' "$CONFIG_FILE" | while read -r client; do
        name=$(echo "$client" | jq -r '.name')
        port=$(echo "$client" | jq -r '.port')
        api_key=$(echo "$client" | jq -r '.apiKey')
        container=$(echo "$client" | jq -r '.container')
        username=$(echo "$client" | jq -r '.dashboard.username')
        password=$(echo "$client" | jq -r '.dashboard.password')
        
        # Check if running
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            status="${GREEN}🟢 Running${NC}"
            uptime=$(docker ps --filter "name=${container}" --format '{{.Status}}')
        else
            status="${RED}🔴 Stopped${NC}"
            uptime="N/A"
        fi
        
        echo -e "${CYAN}${index}️⃣  ${name}${NC}"
        echo -e "    Status:     $status"
        echo "    Port:       $port"
        echo "    Dashboard:  http://${SERVER_IP}:${port}/dashboard"
        echo "    Username:   $username"
        echo "    Password:   $password"
        echo "    API Key:    $api_key"
        echo "    Uptime:     $uptime"
        echo ""
        
        ((index++))
    done
    
    echo "─────────────────────────────────────────"
    echo "Total: $client_count client(s)"
    echo "─────────────────────────────────────────"
    echo ""
    read -p "Press Enter to return to menu..."
}

# Stop client
stop_client() {
    clear
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           ⏸️  Stop Client              ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    local client_count=$(jq '.clients | length' "$CONFIG_FILE")
    
    if [ "$client_count" -eq 0 ]; then
        echo "No clients configured."
        sleep 2
        return
    fi
    
    # List clients
    local index=1
    jq -c '.clients[]' "$CONFIG_FILE" | while read -r client; do
        name=$(echo "$client" | jq -r '.name')
        port=$(echo "$client" | jq -r '.port')
        echo "[$index] $name (port $port)"
        ((index++))
    done
    echo "[0] Cancel"
    echo ""
    
    read -p "Choose: " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    local container=$(jq -r ".clients[$((choice-1))].container" "$CONFIG_FILE")
    local name=$(jq -r ".clients[$((choice-1))].name" "$CONFIG_FILE")
    
    if [ "$container" == "null" ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}⏸️  Stopping ${name}...${NC}"
    docker stop "$container" > /dev/null 2>&1
    echo -e "${GREEN}✅ Client stopped${NC}"
    sleep 2
}

# Remove client
remove_client() {
    clear
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          🗑️  Remove Client             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    local client_count=$(jq '.clients | length' "$CONFIG_FILE")
    
    if [ "$client_count" -eq 0 ]; then
        echo "No clients configured."
        sleep 2
        return
    fi
    
    # List clients
    local index=1
    jq -c '.clients[]' "$CONFIG_FILE" | while read -r client; do
        name=$(echo "$client" | jq -r '.name')
        port=$(echo "$client" | jq -r '.port')
        echo "[$index] $name (port $port)"
        ((index++))
    done
    echo "[0] Cancel"
    echo ""
    
    read -p "Choose: " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    local container=$(jq -r ".clients[$((choice-1))].container" "$CONFIG_FILE")
    local name=$(jq -r ".clients[$((choice-1))].name" "$CONFIG_FILE")
    
    if [ "$container" == "null" ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${RED}⚠️  WARNING: This will DELETE all data for \"${name}\"${NC}"
    echo ""
    read -p "Type client name to confirm: " confirm_name
    
    if [ "$confirm_name" != "$name" ]; then
        echo -e "${RED}❌ Name mismatch. Cancelled.${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}🗑️  Stopping container...${NC}"
    docker stop "$container" > /dev/null 2>&1 || true
    
    echo -e "${YELLOW}🗑️  Removing container...${NC}"
    docker rm "$container" > /dev/null 2>&1 || true
    
    echo -e "${YELLOW}🗑️  Cleaning up data...${NC}"
    docker volume rm "${container}_data" > /dev/null 2>&1 || true
    
    # Remove from config
    jq "del(.clients[$((choice-1))])" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Client \"${name}\" removed successfully!${NC}"
    echo ""
    sleep 2
}

# Main menu
main_menu() {
    while true; do
        clear
        local client_count=$(jq '.clients | length' "$CONFIG_FILE")
        
        echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     🤖 WAHA Client Manager v1.0        ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "Current Clients: $client_count"
        echo ""
        echo "[1] Add New Client"
        echo "[2] List All Clients"
        echo "[3] Stop Client"
        echo "[4] Remove Client"
        echo "[5] Exit"
        echo ""
        read -p "Choose option: " option
        
        case $option in
            1) add_client ;;
            2) list_clients ;;
            3) stop_client ;;
            4) remove_client ;;
            5) echo "Goodbye!"; exit 0 ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

# Main
init_config
main_menu
