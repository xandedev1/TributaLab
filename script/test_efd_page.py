import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Test the page with curl (simulating logged in user via session cookie)
# First get login page to get CSRF token
cmd = '''cd /var/www/tributa-lab && curl -s -c /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/login | grep -o 'name="authenticity_token" value="[^"]*"' | head -1'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
token_line = stdout.read().decode().strip()
print("CSRF token line:", token_line)

# Extract token value
import re
match = re.search(r'value="([^"]*)"', token_line)
if match:
    token = match.group(1)
    print("Token:", token[:50] + "...")
    
    # Login
    cmd2 = f'''curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -X POST -d "authenticity_token={token}&username=Xande&password=123321" https://realaudittech.com/auditor-fiscal/login -o /dev/null -w "%{{http_code}}"'''
    stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
    print("Login status:", stdout.read().decode())
    
    # Select SOLUCOES
    cmd3 = '''curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -X POST https://realaudittech.com/auditor-fiscal/empresas/solucoes -o /dev/null -w "%{http_code}"'''
    stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
    print("Select SOLUCOES:", stdout.read().decode())
    
    # Access EFD Razao page
    cmd4 = '''curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/cruzamento-efd-razao -o /tmp/efd_page.html -w "%{http_code}"'''
    stdin, stdout, stderr = client.exec_command(cmd4, timeout=30)
    print("EFD Razao page:", stdout.read().decode())
    
    # Check content
    cmd5 = '''grep -c "Cruzamento EFD" /tmp/efd_page.html; grep -c "A100" /tmp/efd_page.html; grep -c "C100" /tmp/efd_page.html; grep -c "fa-report-nav" /tmp/efd_page.html'''
    stdin, stdout, stderr = client.exec_command(cmd5, timeout=30)
    print("Content check:", stdout.read().decode())
    
    # Check for errors
    cmd6 = '''journalctl -u tributa-lab --since "1 min ago" --no-pager | grep -iE "error|500|exception" | tail -5'''
    stdin, stdout, stderr = client.exec_command(cmd6, timeout=30)
    print("Errors:", stdout.read().decode() or "None")
else:
    print("Could not get CSRF token")

client.close()
