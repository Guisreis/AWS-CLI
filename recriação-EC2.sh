#!/bin/bash

# Nome do snapshot
snapshot_name="snapshot-GSREIS"

# ID do volume EBS de origem (SO)
source_volume_id_SO="vol-0531652af162eeb53"

# ID da nova instância EC2
source_instance_id="i-09b5a9d51e02e1018"  

# ID do security group da nova instância EC2
security_group_id="sg-0fb2e090b23b90b7b"

# Região da AWS
region="us-east-2"

# Nome da imagem a ser criada
image_name="AMI-GSREIS"

# Nome da nova instância EC2
new_instance_name="VM-GSREIS2"

# Criar snapshot do volume da instância EC2 de origem
echo "Criando snapshot do volume da instância EC2 de origem..."
snapshot_id_SO=$(aws ec2 create-snapshot --volume-id $source_volume_id_SO --description "$snapshot_name" --region $region --query "SnapshotId" --output text)

# Aguardar até que o snapshot esteja pronto
echo "Aguardando a conclusão do snapshot..."
aws ec2 wait snapshot-completed --snapshot-ids $snapshot_id_SO --region $region

# Criar uma imagem a partir do snapshot
echo "Criando uma imagem a partir do snapshot..."
image_id=$(aws ec2 create-image --instance-id $source_instance_id --name "$image_name" --description "AMI gerada a partir do snapshot do volume" --block-device-mappings "DeviceName=/dev/xvda,Ebs={SnapshotId=$snapshot_id_SO,VolumeType=gp3}" --query "ImageId" --output text --region $region)
echo "Nova imagem criada com ID: $image_id"

# Aguardar até que a nova imagem esteja disponível
echo "Aguardando a disponibilidade da nova imagem..."
aws ec2 wait image-available --image-ids $image_id --region $region

# Criar uma nova instância EC2 usando a nova AMI
echo "Criando uma nova instância EC2 usando a nova AMI..."
new_instance_id=$(aws ec2 run-instances --image-id $image_id --instance-type t2.micro --security-group-ids $security_group_id --query "Instances[0].InstanceId" --output text --region $region)
echo "Nova instância EC2 criada com ID: $new_instance_id"

# Adicionar nome à nova instância EC2
echo "Adicionando nome à nova instância EC2..."
aws ec2 create-tags --resources $new_instance_id --tags Key=Name,Value="$new_instance_name" --region $region

# Aguardar até que a nova instância EC2 esteja em execução
echo "Aguardando a inicialização da nova instância EC2..."
aws ec2 wait instance-status-ok --instance-ids $new_instance_id --region $region

echo "Nova instância EC2 está em execução e pronta para uso."
