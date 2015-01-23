not_found do
  'Whoops, nothing there: 404.'
end

error do
  e = env['sinatra.error']  
  show_errors = !$prod || params[:debug] 
  
  errors = {status: 500, msg: e.to_s, custom: "barrium-1776", backtrace: e.backtrace.to_a.slice(0,4).to_s}
  hidden_error = {status: 500, msg: "something went wrong."}
  show_errors ? errors : hidden_error  
end
