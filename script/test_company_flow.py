import paramiko
import re

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Pega token
stdin, stdout, stderr = client.exec_command('curl -s -c /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/login | grep -o \'authenticity_token" value="[^"]*"\' | head -1')
token_line = stdout.read().decode().strip()
match = re.search(r'value="([^"]+)"', token_line)
token = match.group(1) if match else ''

# Login
stdin, stdout, stderr = client.exec_command(f'curl -s -b /tmp/cookies.txt -c /tmp/cookies.txt -X POST -d "authenticity_token={token}&username=Xande&password=123321" -L https://realaudittech.com/auditor-fiscal/login | grep -c "fa-company-card"')
print('CARDS apos login:', stdout.read().decode().strip())

# Seleciona SOLUCOES
stdin, stdout, stderr = client.exec_command('curl -s -b /tmp/cookies.txt -X POST -d "company=solucoes" -L https://realaudittech.com/auditor-fiscal/empresas/solucoes | grep -c "Nenhum arquivo"')
print('SOLUCOES vazio:', stdout.read().decode().strip())

# Seleciona APPA
stdin, stdout, stderr = client.exec_command('curl -s -b /tmp/cookies.txt -X POST -d "company=appa" -L https://realaudittech.com/auditor-fiscal/empresas/appa | grep -c "Faturamento"')
print('APPA tem dados:', stdout.read().decode().strip())

client.close()
