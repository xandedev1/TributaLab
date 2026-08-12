import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

stdin, stdout, stderr = client.exec_command('cat /etc/nginx/sites-enabled/tributa-lab | grep -A 5 "location /"')
print(stdout.read().decode())

client.close()
