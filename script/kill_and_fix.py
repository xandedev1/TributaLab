import paramiko
import time

# Try to connect and kill python processes
for i in range(3):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host', timeout=30)
        break
    except Exception as e:
        print(f"Attempt {i+1}: {e}")
        time.sleep(10)
else:
    print("Failed to connect")
    exit(1)

# Kill all python processes
cmd = 'pkill -9 python3; pkill -9 python; sleep 2; ps aux | grep python | grep -v grep || echo "No python processes"'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print(stdout.read().decode())

# Check memory
cmd2 = 'free -h'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("MEMORY:", stdout.read().decode())

# Deploy fix
cmd3 = 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=60)
print("DEPLOY:", stdout.read().decode())

# Restart
cmd4 = 'systemctl restart tributa-lab'
stdin, stdout, stderr = client.exec_command(cmd4, timeout=30)
print("RESTART:", stdout.read().decode())

time.sleep(10)

# Check
cmd5 = 'curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "10 sec ago" --no-pager | grep -iE "error|500" | tail -3'
stdin, stdout, stderr = client.exec_command(cmd5, timeout=30)
print("CHECK:", stdout.read().decode())

client.close()
