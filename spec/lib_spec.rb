require 'httpclient'
require 'colorize' 
require 'json'
require 'pry-byebug'
# helpers
def bp
  binding.pry
end

# comm
$http = HTTPClient.new

def full_route(relative_route)
  "#{$base_url}#{relative_route}"
end

def parse_http_response(res)  
  JSON.parse res.body
rescue => e
  res.body 
end

def get(route, params = {}) 
  @last_res = parse_http_response (get_raw(route, params))
end

def get_raw(route, params = {})
  puts "Getting #{route}".light_blue
  @last_res = $http.get full_route(route), params
end

def post(route, params = {})
  @last_res = parse_http_response (post_raw(route, params))
end

def post_raw(route, params = {})
  puts "Posting #{route} with params #{params}".light_blue  
  @last_res = ($http.post full_route(route), params.to_json, "Content-Type" => "application/json")
  puts ("Got: "+@last_res.status.to_s+" "+@last_res.body).light_blue if @last_res
  return @last_res
end

def last_res 
  @last_res
end

# testing
$assert_counter = 0

def assert(cond, msg = "<msg missing>") 
  $assert_counter += 1
  line = cond ? msg.green : "*** Failed *** on #{msg}".red
  line = "[#{$assert_counter}] #{line}"
  puts line
  puts ("---")
end