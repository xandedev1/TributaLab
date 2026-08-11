import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Testa com cookie de sessão
cmd = '''curl -s -c /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/login | grep -o 'authenticity_token" value="[^"]*"' | head -1'''

stdin, stdout, stderr = client.exec_command(cmd)
token_line = stdout.read().decode().strip()
print('TOKEN:', token_line[:80] + '...' if len(token_line) > 80 else token_line)

# Extrai o token
import re
match = re.search(r'value="([^"]+)"', token_line)
if match:
    token = match.group(1)
    print('Token extraido, tamanho:', len(token))
    
    # Faz login
    cmd2 = f'''curl -s -b /tmp/cookies.txt -c /tmp/cookies.txt -X POST -d "authenticity_token={token}&username=Xande&password=123321" -L https://realaudittech.com/auditor-fiscal/login | grep -c "fa-company-card"'''
    stdin, stdout, stderr = client.exec_command(cmd2)
    print('CARDS apos login:', stdout.read().decode().strip())
    
    # Verifica empresas
    cmd3 = '''curl -s -b /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company-card"'''
    stdin, stdout, stderr = client.exec_command(cmd3)
    print('CARDS na pagina empresas:', stdout.read().decode().strip())

client.close()
