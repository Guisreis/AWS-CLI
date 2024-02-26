#! /bin/bash

region='us-east-1'

# Find all gp2 volumes within the given region
volume_ids=$(/usr/bin/aws ec2 describe-volumes --region "${region}" --filters Name=volume-type,Values=gp2 | jq -r '.Volumes[].VolumeId')

# Iterate all gp2 volumes and change its type to gp3
for volume_id in ${volume_ids};do
    result=$(/usr/bin/aws ec2 modify-volume --region "${region}" --volume-type=gp3 --volume-id "${volume_id}" | jq '.VolumeModification.ModificationState' | sed 's/"//g')
    if [ $? -eq 0 ] && [ "${result}" == "modifying" ];then
        echo "OK: volume ${volume_id} changed to state 'modifying'"
    else
        echo "ERROR: couldn't change volume ${volume_id} type to gp3!"
    fi
done
