#!/bin/bash

region='us-east-1'

# Insira manualmente os IDs dos volumes separados por espaço
volume_ids_array=( "vol-0a0229787f661ee69" "vol-026cbe1d8a78875e4" "vol-06bc533adfec8268e" "vol-08e808e7ba4ed3c6d" "vol-014d5e214817d2a56" )

# Iterar sobre os IDs dos volumes fornecidos
for volume_id in "${volume_ids_array[@]}"; do
    # Alterar o tipo do volume para gp3
    result=$(/usr/bin/aws ec2 modify-volume --region "${region}" --volume-type=gp3 --volume-id "${volume_id}" | jq '.VolumeModification.ModificationState' | sed 's/"//g')
    
    if [ $? -eq 0 ] && [ "${result}" == "modifying" ]; then
        echo "OK: volume ${volume_id} alterado para o estado 'modificando'"
    else
        echo "ERRO: não foi possível alterar o tipo do volume ${volume_id} para gp3!"
    fi
done
