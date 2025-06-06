#Deve ter instalado AWS-CLI,jq , Python e as bibliotecas pandas e openpyxl.

#Primeiro você deve gerar um json com as hosted zones
aws route53 list-hosted-zones > hosted_zones.json

#Depois disso você deve criar um script shell chamado list_records.sh e adicionar o script abaixo:

#!/bin/bash

# Listar todas as hosted zones
aws route53 list-hosted-zones > hosted_zones.json

# Extrair IDs das hosted zones e iterar sobre cada uma
jq -r '.HostedZones[].Id' hosted_zones.json | while read -r zone_id; do
  zone_id=${zone_id##*/}
  echo "Listando records da hosted zone: $zone_id"
  aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" > "records_$zone_id.json"
done

#Dê permissão de execução ao script:
chmod +x list_records.sh

#Após isso execute o script

#Realizar a criação desse script no mesmo diretorio do arquivo da hosted_zones e records.

#O script abaixo gera uma planilha com os records A com alias e IPs e CNAME

#!/usr/bin/env python3

import json
import pandas as pd
import os

# Função para ler o arquivo JSON e extrair os records
def read_records(file_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    return data['ResourceRecordSets']

# Ler o arquivo de hosted zones
with open('hosted_zones.json', 'r') as file:
    hosted_zones = json.load(file)

# Preparar uma lista para armazenar os dados
records_data = []

# Iterar sobre cada hosted zone e seus records
for zone in hosted_zones['HostedZones']:
    zone_id = zone['Id'].split('/')[-1]
    zone_name = zone['Name']
    records_file = f'records_{zone_id}.json'
    
    if os.path.exists(records_file):
        records = read_records(records_file)
        
        for record in records:
            # Filtrar apenas registros do tipo A e CNAME
            if record['Type'] in ['A', 'CNAME']:
                # Verificar se 'ResourceRecords' está presente
                if 'ResourceRecords' in record:
                    for rr in record['ResourceRecords']:
                        records_data.append({
                            'Hosted Zone ID': zone_id,
                            'Hosted Zone Name': zone_name,
                            'Record Name': record['Name'],
                            'Record Type': record['Type'],
                            'TTL': record.get('TTL', 'N/A'),
                            'Record Value': rr.get('Value', 'N/A')
                        })
                else:
                    # Adicionar um registro para os tipos que não têm 'ResourceRecords'
                    records_data.append({
                        'Hosted Zone ID': zone_id,
                        'Hosted Zone Name': zone_name,
                        'Record Name': record['Name'],
                        'Record Type': record['Type'],
                        'TTL': record.get('TTL', 'N/A'),
                        'Record Value': 'N/A'
                    })

# Converter os dados para um DataFrame do Pandas
df = pd.DataFrame(records_data)

# Salvar o DataFrame em um arquivo Excel
df.to_excel('hosted_zones_records_filtered.xlsx', index=False)

print('Planilha gerada: hosted_zones_records_filtered.xlsx')
