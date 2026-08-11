import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && export $(cat .env | xargs) && bundle exec rails runner "
user = FiscalAuditor::User.active.find_by('LOWER(username) = ?', 'xande')
puts user ? 'Xande existe' : 'Xande nao existe'
user2 = FiscalAuditor::User.active.find_by('LOWER(username) = ?', 'lobo')
puts user2 ? 'Lobo existe' : 'Lobo nao existe'
puts FiscalAuditor::User.count
"'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
