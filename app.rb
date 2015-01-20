require 'rubygems'
require 'bundler'
require 'sinatra/namespace'
require 'sinatra/reloader' #dev-only
require 'active_support/core_ext/hash/slice'
require 'json' 
require 'erb'
require 'securerandom'
require "net/http"
require "net/https"
require "cgi"

Bundler.require

# our app files - export to separate require.rb file when grows out of hand

require './lib/mylib'
require './settings'
require './db/mongo'
require_all './bl'
require_all './middleware'

get '/' do
	{msg: 'hello from pickeez_rb_be'}
end	

get '/error' do 
  a = b
end

get "/fb" do
  redirect "https://graph.facebook.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{$root_url}/callback"
end

get '/me' do
  Users.get(session[:user_id]) || 'no user'
end

#app will probably call this endpoint with code. 
get "/callback" do
  code = params[:code]

  endpoint = "https://graph.facebook.com/oauth/access_token?client_id=#{@client_id}&redirect_uri=#{$root_url}/callback&client_secret=#{@client_secret}&code=#{code}"
  response = HTTPClient.new.get endpoint
  access_token = CGI.parse(response.body)["access_token"][0]
  
  #4. use auth-token to get user data
  endpoint = "https://graph.facebook.com/me?access_token=#{access_token}"
  response = HTTPClient.new.get endpoint
  fb_data = JSON.parse(response.body)
  
  user = Users.get_or_create_by_fb_id(fb_data['id'], fb_data)
  session[:user_id] = user['_id']
  redirect "/me"
end

get "/logout" do
  session[:user_id] = {}
  redirect "/me"
end

puts "Ready to rock".light_red