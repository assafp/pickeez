not_found do
  content_type 'application/json'
  {msg: 'Whoops, nothing there: 404.'}.to_json
end

error do
  e = env['sinatra.error']  
  show_errors = !$prod || params[:debug] 
  uri = request.env['REQUEST_URI']  
  errors = {status: 500, uri: uri, msg: e.to_s, custom: "barrium-1776", backtrace: e.backtrace.to_a.slice(0,4).to_s}
  $errors.add(errors)
  hidden_error = {status: 500, msg: "something went wrong."}
  show_errors ? errors : hidden_error  
end

$errors = $mongo.collection('errors')

def log_exception(e)
  backtrace = e.backtrace.to_a.slice(0,4).to_s
  msg = e.message
  $errors.add({backtrace: backtrace, msg: msg})
end