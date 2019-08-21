require 'sinatra'
require 'faraday'

set :port, ENV['MONZO_AUTH_PORT']

get '/' do
  response = Faraday.post(
    'https://api.monzo.com/oauth2/token',
     grant_type: 'authorization_code',
     client_id: ENV.fetch('MONZO_CLIENT_ID'),
     client_secret: ENV.fetch('MONZO_CLIENT_SECRET'),
     redirect_uri: ENV.fetch('MONZO_REDIRECT_URI'),
     code: params['code'])

  if response.success?
    File.write('monzo_credentials.json', response.body)
    'OK!'
  else
    'Failed!'
  end
end

get '/ping' do
  'pong'
end
