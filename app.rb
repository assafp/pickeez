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
require 'sinatra/cross_origin'

Bundler.require

# our app files - export to separate require.rb file when grows out of hand

require './lib/mylib'
require './settings'
require './db/mongo'
require_all './bl'
require_all './comm'
require_all './middleware'

get '/' do
	{msg: "welcome to pickeez_rb_be"}
end	

get '/ping' do 
  cross_origin
  {msg: "pong from pickeez", pid: Process.pid, thread_id: Thread.current.object_id}
end

get '/routes' do
  send_file 'README.md', :type => :txt
end

get '/raise404' do
  status 404
end

get '/send_push_notif' do
  user_id = params[:user_id]
  alert = params[:alert].to_s || "Pickeez Notification"
  info = {album_id: params[:album_id], type: params[:type]}
  badge = params[:badge]
  PushNotifs.send_notif([user_id],alert,info,badge)  
end

get '/error' do 
  a = b
end

get '/errors' do 
  #halt(401, 'Nothing to see here') unless params[:password]==settings.algo_password
  errors = $errors.find.sort(created_at: -1).limit(30).to_a.map {|e| e.just('created_at', 'msg', 'backtrace')}
    {errors: errors}
end

get '/halt' do
  halt(400, {a:1})
end

get '/invite_page' do
  cross_origin
  album_id = params[:album_id]
  halt(400, "No album ID") unless album_id
  
  album = $albums.get(album_id)
  owner = $users.get(album['owner_id'])
  photos = $photos.find({album_id: album_id}).limit(10).map {|p| {url: p['s3_path']} }.to_a
  
  {album_name: album['name'], owner_name: owner['name'], photos: photos}
end

puts "Ready to rock".light_red