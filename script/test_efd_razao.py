import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check .env for PYTHON var
cmd = 'grep -i python /var/www/tributa-lab/.env || echo "PYTHON not set"'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("ENV:", stdout.read().decode())

# Test the page
cmd2 = 'curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/auditor-fiscal/cruzamento-efd-razao'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("Page status:", stdout.read().decode())

# Check recent logs
cmd3 = 'journalctl -u tributa-lab --since "1 min ago" --no-pager | tail -20'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
print("Logs:", stdout.read().decode())

client.close()
