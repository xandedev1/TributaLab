import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check the actual code on VPS
cmd = 'sed -n "110,125p" /var/www/tributa-lab/app/services/fiscal_auditor/efd_razao_dashboard.rb'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("Code on VPS:")
print(stdout.read().decode())

# Check if JSON is being parsed correctly
cmd2 = '''cd /var/www/tributa-lab && bundle exec rails runner "
require 'json'
data = JSON.parse(File.read('tmp/razao_servicos.json'))
puts 'Type: ' + data.class.to_s
puts 'Keys: ' + data.keys.inspect if data.is_a?(Hash)
puts 'Records type: ' + data['records'].class.to_s if data.is_a?(Hash)
puts 'First record: ' + data['records'].first.inspect if data.is_a?(Hash) && data['records'].is_a?(Array)
" 2>&1'''
stdin, stdout, stderr = client.exec_command(cmd2, timeout=60)
print("Rails test:")
print(stdout.read().decode())
print(stderr.read().decode())

client.close()
