import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = 'journalctl -u tributa-lab --since "5 min ago" --no-pager | grep -A 20 "Completed 500" | tail -30'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())

client.close()
