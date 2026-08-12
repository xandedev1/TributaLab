import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && curl -s https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company-card" && echo "---" && curl -s https://realaudittech.com/auditor-fiscal/ | grep -c "R\\$" && echo "---" && curl -s https://realaudittech.com/auditor-fiscal/ | grep -c "Nenhum dado"'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
