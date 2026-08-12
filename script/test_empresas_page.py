import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company"')
print('EMPRESAS:', stdout.read().decode().strip())

stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/auditor-fiscal/empresas | grep -o "APPA\\|Solucoes" | sort | uniq -c')
print('CONTEUDO:', stdout.read().decode())

client.close()
