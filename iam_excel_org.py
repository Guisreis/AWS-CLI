import boto3
import pandas as pd

# Esse Script lista todos os users, grupos e permissions sets, em unica planilha dividindo por uma pagina para cada conta.

# Inicializar clientes do Boto3
org_client = boto3.client('organizations')
sts_client = boto3.client('sts')

# Função para assumir um papel em outra conta
def assume_role(account_id, role_name):
    response = sts_client.assume_role(
        RoleArn=f'arn:aws:iam::{account_id}:role/{role_name}',
        RoleSessionName='AssumeRoleSession'
    )
    return response['Credentials']

# Função para obter usuários, grupos e permissões de uma conta
def get_iam_info(account_id, credentials):
    iam_client = boto3.client(
        'iam',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )
    
    users = []
    groups = []
    permissions_sets = []

    # Obter todos os usuários
    response = iam_client.list_users()
    for user in response['Users']:
        user_name = user['UserName']
        user_groups = iam_client.list_groups_for_user(UserName=user_name)
        
        for group in user_groups['Groups']:
            users.append({
                'User': user_name,
                'Account': account_id,
                'Group': group['GroupName']
            })

    # Obter todos os grupos e suas permissões
    response = iam_client.list_groups()
    for group in response['Groups']:
        group_name = group['GroupName']
        group_policies = iam_client.list_attached_group_policies(GroupName=group_name)
        
        for policy in group_policies['AttachedPolicies']:
            groups.append({
                'Group': group_name,
                'Permissions Set': policy['PolicyName']
            })
    
    # Obter todas as permissões sets (políticas)
    response = iam_client.list_policies(Scope='Local')
    for policy in response['Policies']:
        permissions_sets.append({
            'Permissions Set': policy['PolicyName'],
            'Description': policy.get('Description', 'No description')
        })

    return users, groups, permissions_sets

# Função para obter todas as contas da organização
def get_all_accounts():
    accounts = []
    paginator = org_client.get_paginator('list_accounts')
    for page in paginator.paginate():
        accounts.extend(page['Accounts'])
    return accounts

# Obter informações de todas as contas
all_accounts = get_all_accounts()

all_users = []
all_groups = []
all_permissions_sets = []

for account in all_accounts:
    account_id = account['Id']
    account_name = account['Name']
    
    # Assume a role
    try:
        credentials = assume_role(account_id, 'OrganizationAccountAccessRole')
        users, groups, permissions_sets = get_iam_info(account_id, credentials)
        
        all_users.extend(users)
        all_groups.extend(groups)
        all_permissions_sets.extend(permissions_sets)
        
        print(f'Informações coletadas da conta {account_name} ({account_id})')
    except Exception as e:
        print(f'Falha ao acessar a conta {account_name} ({account_id}): {str(e)}')

# Remover duplicatas dos permissions sets
unique_permissions_sets = {ps['Permissions Set']: ps for ps in all_permissions_sets}.values()

# Criar DataFrames do Pandas
df_users = pd.DataFrame(all_users)
df_groups = pd.DataFrame(all_groups)
df_permissions_sets = pd.DataFrame(unique_permissions_sets)

# Criar um objeto ExcelWriter e salvar os DataFrames em diferentes planilhas
with pd.ExcelWriter('iam_info.xlsx') as writer:
    df_users.to_excel(writer, sheet_name='Page 1', index=False)
    df_groups.to_excel(writer, sheet_name='Page 2', index=False)
    df_permissions_sets.to_excel(writer, sheet_name='Page 3', index=False)

print('Planilha gerada com sucesso!')
