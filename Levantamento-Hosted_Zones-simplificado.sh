#!/bin/bash

# Listar todas as hosted zones
aws route53 list-hosted-zones > hosted_zones.json

# Extrair IDs das hosted zones e iterar sobre cada uma
jq -r '.HostedZones[].Id' hosted_zones.json | while read -r zone_id; do
  zone_id=${zone_id##*/}
  echo "Listando records da hosted zone: $zone_id"
  aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" > "records_$zone_id.json"
done

