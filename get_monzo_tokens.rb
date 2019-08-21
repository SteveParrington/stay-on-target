require 'subprocess'
require 'net/http'
require 'securerandom'
require 'rb-inotify'

def server_has_started?(remaining_attempts)
  response = Net::HTTP.get_response('localhost', '/ping', ENV.fetch('MONZO_AUTH_PORT'))

  response.code == "200"
rescue StandardError
  return false if remaining_attempts == 0
  sleep 1

  server_has_started?(remaining_attempts - 1)
end

begin
  server_process = Subprocess.popen(['bundle', 'exec', 'ruby', 'monzo_auth_server.rb'])

  if server_has_started?(10)
    uri = URI::HTTPS.build(host: 'auth.monzo.com', path: '/', query: URI.encode_www_form({ 
      client_id: ENV.fetch('MONZO_CLIENT_ID'),
      redirect_uri: ENV.fetch('MONZO_REDIRECT_URI'),
      response_type: 'code',
      state: SecureRandom.hex(32)
    })).to_s
    Subprocess.call(['firefox', uri])
  else
    abort "Error! Server either did not start or was not detected."
  end

  notifier = INotify::Notifier.new
  notifier.watch("monzo_credentials.json", :modify, :create) do
    puts "Credentials saved!"
  end

  notifier.process
ensure
  server_process.terminate
end
