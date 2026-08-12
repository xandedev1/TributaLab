import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = 'journalctl -u tributa-lab --since "10 min ago" --no-pager | grep -iE "error|500|exception|NoMethodError|undefined" | tail -20'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())

cmd2 = 'journalctl -u tributa-lab --since "10 min ago" --no-pager | grep -A 15 "Completed 500" | tail -40'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=60)
print("DETAILS:", stdout.read().decode())

client.close()
