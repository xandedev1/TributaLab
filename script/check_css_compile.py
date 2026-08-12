import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check compiled CSS
cmd = 'grep -o "fa-report-nav[^}]*}" /var/www/tributa-lab/public/assets/fiscal_auditor-*.css | head -5'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print(stdout.read().decode())

# Check if the new CSS is there
cmd2 = 'grep "justify-content: center" /var/www/tributa-lab/public/assets/fiscal_auditor-*.css | head -3'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("justify-content:", stdout.read().decode())

client.close()
