# The following are exposed globally via settings.key_name.
set :raise_errors,    false
set :show_exceptions, false

#set :sessions,        true 
#set :session_secret,  ENV['PICKEEZ_SESSION_SECRET']

set :my_key,          'my_val' # settings.my_key == 'my_val
set :twilio_auth_token,   ENV['TWILIO_AUTH_TOKEN']
set :algo_password,       ENV['PICKEEZ_ALGO_PASSWORD']
# The following are exposed globally via $varname.
$app_name   = 'pickeez'
$prod       = settings.production? #env is set via RACK_ENV=production in prod 
$root_url   = $prod ? 'http://www.pickeezmetadata.com' : 'http://localhost:8002'
