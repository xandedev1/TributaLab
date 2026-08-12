import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Get full error
cmd = 'journalctl -u tributa-lab --since "5 min ago" --no-pager | grep -B 10 -A 30 "TypeError" | tail -50'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())

client.close()
