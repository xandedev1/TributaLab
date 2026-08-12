import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/auditor-fiscal/empresas')
print('STATUS:', stdout.read().decode().strip())

stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/auditor-fiscal/empresas | head -20')
print('HTML:', stdout.read().decode()[:500])

client.close()
