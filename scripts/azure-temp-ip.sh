#!/usr/bin/env bash
set -e

RG="JENKINS-HMIS2026"
VM="jenkins-hmis2026"
LOCATION="francecentral"

PUBLIC_IP_NAME="${VM}-ip"
DNS_NAME="jenkins-hmis2026"

IP_CONFIG_NAME="ipconfig1"

ACTION="$1"

NIC_ID=$(az vm show -g "$RG" -n "$VM" --query "networkProfile.networkInterfaces[0].id" -o tsv)
NIC_NAME=$(basename "$NIC_ID")

if [ "$ACTION" = "attach" ]; then

  echo "Creando IP pública con DNS..."

  az network public-ip create \
    -g "$RG" \
    -n "$PUBLIC_IP_NAME" \
    --location "$LOCATION" \
    --sku Standard \
    --allocation-method Static \
    --dns-name "$DNS_NAME"

  echo "Asociando IP pública a la VM..."

  az network nic ip-config update \
    -g "$RG" \
    --nic-name "$NIC_NAME" \
    -n "$IP_CONFIG_NAME" \
    --public-ip-address "$PUBLIC_IP_NAME"

  FQDN=$(az network public-ip show \
    -g "$RG" \
    -n "$PUBLIC_IP_NAME" \
    --query "dnsSettings.fqdn" \
    -o tsv)

  IP=$(az network public-ip show \
    -g "$RG" \
    -n "$PUBLIC_IP_NAME" \
    --query "ipAddress" \
    -o tsv)

  echo "IP pública: $IP"
  echo "DNS: $FQDN"

elif [ "$ACTION" = "detach" ]; then

  echo "Desasociando IP pública..."

  az network nic ip-config update \
    -g "$RG" \
    --nic-name "$NIC_NAME" \
    -n "$IP_CONFIG_NAME" \
    --remove publicIpAddress

  echo "Eliminando IP pública..."

  az network public-ip delete \
    -g "$RG" \
    -n "$PUBLIC_IP_NAME"

  echo "IP pública y DNS eliminados."

else

  echo "Uso:"
  echo "  $0 attach"
  echo "  $0 detach"
  exit 1

fi