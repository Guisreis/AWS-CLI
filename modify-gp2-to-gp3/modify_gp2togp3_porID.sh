#!/bin/bash

region='us-east-1'

# Insira manualmente os IDs dos volumes separados por espaço
volume_ids_array=( "vol-0515110231456" "vol-084184152616" "vol-015162629645810" "vol-051651dwa6515" "vol-055561a561616d" )

# AIterar sobre os IDs dos volumes fornecidos
for volume_id in "${volume_ids_array[@]}"; do
    # Alterar o tipo do volume para gp3
    result=$(/usr/bin/aws ec2 modify-volume --region "${region}" --volume-type=gp3 --volume-id "${volume_id}" | jq '.VolumeModification.ModificationState' | sed 's/"//g')
    
    if [ $? -eq 0 ] && [ "${result}" == "modifying" ]; then
        echo "OK: volume ${volume_id} alterado para o estado 'modificando'"
    else
        echo "ERRO: não foi possível alterar o tipo do volume ${volume_id} para gp3!"
    fi
done
