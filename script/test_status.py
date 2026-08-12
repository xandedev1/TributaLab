import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/auditor-fiscal/empresas && echo "" && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/auditor-fiscal/ && echo "" && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
