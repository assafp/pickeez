#\ -p 8002
$stdout.sync = true  # Disable log buffering.

# Run the Sinatra application.
require './app'
run Sinatra::Application
