import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Verifica se a página de empresas existe e o que retorna
stdin, stdout, stderr = client.exec_command('curl -s -L https://realaudittech.com/auditor-fiscal/empresas 2>&1 | head -100')
print(stdout.read().decode())
print('---STDERR---')
print(stderr.read().decode())

client.close()
