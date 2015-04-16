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
  {msg: "pong from pickeez"}
end

get '/routes' do
  send_file 'README.md', :type => :txt
end

get '/raise404' do
  status 404
end

get '/error' do 
  a = b
end

get '/halt' do
  halt(400, {a:1})
end

get '/invite_page' do
  cross_origin
  album_id = params[:album_id]
  album = $albums.get(album_id)
  owner = $users.get(album['owner_id'])
  photos = $photos.find({album_id: album_id}).limit(10).to_a
  {msg: "Hello!", album: album, owner_name: owner['name'], photos: photos}
end

puts "Ready to rock".light_red