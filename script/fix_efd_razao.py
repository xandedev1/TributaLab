import paramiko
import time

# Wait for VPS to recover
for i in range(5):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host', timeout=30)
        break
    except Exception as e:
        print(f"Attempt {i+1}: {e}")
        time.sleep(15)
else:
    print("Failed to connect after 5 attempts")
    exit(1)

# Check if extraction files exist
cmd = '''ls -la /var/www/tributa-lab/tmp/efd_razao.json /var/www/tributa-lab/tmp/razao_servicos.json /var/www/tributa-lab/tmp/razao_vendas.json 2>&1; echo "---"; ps aux | grep python | grep -v grep; echo "---"; cat /tmp/efd_extract.log 2>/dev/null | tail -5; echo "---"; cat /tmp/razao_servicos.log 2>/dev/null | tail -5; echo "---"; cat /tmp/razao_vendas.log 2>/dev/null | tail -5'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())
print(stderr.read().decode())

# Deploy the fix
cmd2 = 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=60)
print("DEPLOY:", stdout.read().decode())

# Restart service
cmd3 = 'systemctl restart tributa-lab'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
print("RESTART:", stdout.read().decode())

time.sleep(10)

# Check
cmd4 = 'curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "10 sec ago" --no-pager | grep -iE "error|500" | tail -3'
stdin, stdout, stderr = client.exec_command(cmd4, timeout=30)
print("CHECK:", stdout.read().decode())

client.close()
