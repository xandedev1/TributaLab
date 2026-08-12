import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main && systemctl restart tributa-lab && sleep 10 && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "15 sec ago" --no-pager | grep -iE "error|500" | tail -5'
stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
