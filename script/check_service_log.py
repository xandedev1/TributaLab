import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

stdin, stdout, stderr = client.exec_command('journalctl -u tributa-lab -n 30 --no-pager | tail -20')
print(stdout.read().decode())

client.close()
