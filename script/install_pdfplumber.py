import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = 'pip3 install --break-system-packages pdfplumber 2>&1 | tail -5'
stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
print(stdout.read().decode())
print(stderr.read().decode())

# Verify
cmd2 = 'python3 -c "import pdfplumber; print(pdfplumber.__version__)"'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("Verify:", stdout.read().decode())
print(stderr.read().decode())

client.close()
