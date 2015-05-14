$users = $mongo.collection('users')

$users.ensure_index('phone')
$users.ensure_index('verified_phone')
$users.ensure_index('fb_id')
$users.ensure_index('model')


SETTABLE_USER_FIELDS = [:name, :desc, :img, :phone, 
                :email, :fb_page, :website, :updated_at,
                :phone_verification_code, :verified_phone, :pic_url
              ]

NOMODEL = 'empty'

module Users
  extend self

  def create(params)    
    $users.add(params.merge({token: SecureRandom.urlsafe_base64+SecureRandom.urlsafe_base64}))  
  end

  def get(id)
    $users.get(id)
  end

  def basic_data(field, val)
    $users.project({field.to_s => val}, ['fb_id','name','pic_url','verified_phone', 'phone'])
  end

  def get_or_create_by_fb_id(fb_id, fb_data = {})
    fb_id = fb_id.to_s
    pic_url = "http://graph.facebook.com/#{fb_id}/picture?type=large"
    name = fb_data['name']
    email = fb_data['email']
    data = {fb_id: fb_id, pic_url: pic_url, name: name, email: email, fb_data: fb_data, model: NOMODEL}
    $users.get({fb_id: fb_id}) || create(data)
  end 

  def get_by_email(email)
    $users.find_one({email: email})
  end

  def update(params)    
    fields = params.just(SETTABLE_USER_FIELDS)
    $users.update_id(params[:id], fields)    
  end

  def create_test_users
    (0..10).each {|i|
      i = i.to_s
      $users.update({_id: i}, {"$set" => {fb_id: i, token: i, name: "test_user_#{i}", created_at: Time.now}}, {upsert: true})
    }
  end

end

get '/users' do
  {num: $users.count, users: $users.all}
end

#curl -d "phone=972522934321" "localhost:9292/set_phone" #(also set token in incoming mw)
post '/set_phone' do
  phone = params[:phone]
  code  = rand(1000..9000)
  res = Users.update({phone: phone, phone_verification_code: code, id: cuid}) 
  msg = "Pickeez: Your code is #{code}"
  send_sms(phone, msg)
  Users.get(cuid) || 404
end

post '/resend_code_sms' do
  phone = cu['phone']
  msg = "Pickeez: Your code is #{cu['phone_verification_code']}"  
  send_sms(phone, msg)
  {msg: 'resent'}
end

#curl -d "foo=zomba&phone=0522934321&code=foo&token=0_jUrwgi-xz0rh1QR5WUDQrkRVzOr3WBms3SsWjmF2Hg" "localhost:9292/confirm_phone"
post '/confirm_phone' do
  halt(401, 'no code') unless params['code']
  code = params['code'].to_i
  phone_verification_code = cu['phone_verification_code'].to_i  
  force = true if params['foo'] == 'zomba'

  if (phone_verification_code == code) || force
    verified_phone = cu['phone']
    Users.update({id: cuid, verified_phone: verified_phone});
    Albums.mark_user_albums_as_pending(verified_phone)
    {ok: true}
  else 
    {err: 'wrong code'}
  end
end

get "/fb" do
  redirect "https://graph.facebook.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter_browser&scope=email&scope=user_photos"
end

get '/me' do
  current_user
end

#browser endpoint
get "/fb_enter_browser" do
  code = params[:code]
  endpoint = "https://graph.facebook.com/oauth/access_token?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter_browser&client_secret=#{@client_secret}&code=#{code}&scope=email&scope=user_photos"
  response = HTTPClient.new.get endpoint
  access_token = CGI.parse(response.body)["access_token"][0]
  
  #4. use auth-token to get user data
  endpoint = "https://graph.facebook.com/me?access_token=#{access_token}"
  response = HTTPClient.new.get endpoint
  fb_data = JSON.parse(response.body)
  fb_id = fb_data['id']
  fb_data['code'] = access_token
  user = Users.get_or_create_by_fb_id(fb_id, fb_data)
  {token: user['token'], fb_id: fb_id}
end

get '/fb_enter' do
  code = params[:code]
  endpoint = "https://graph.facebook.com/me?access_token=#{code}"
  response = HTTPClient.new.get endpoint
  fb_data = JSON.parse(response.body)
  fb_data['code'] = code
  fb_id = fb_data['id']
  user = Users.get_or_create_by_fb_id(fb_id, fb_data)
  {token: user['token'], fb_id: fb_id}
end

post '/delete_me' do
  if params['sure'] == 'yes' 
    Albums.delete_pending_by_user(cuid)    
    $albums.remove({owner_id: cuid})    
    $users.remove({_id: cuid}, {justOne: true})
    {msg: 'removed'}
  else 
    {msg: 'please send "sure" parameter as "yes" if you are sure.'}
  end
end

post '/set_pic_url' do
  url = params['pic_url']
  url ? $users.update_id(cuid, {pic_url: url}) : halt(404, 'no pic_url provided')
end

# curl -d "field=send_push_notifs&val=false" localhost:9292/set_fields
# curl -d "field=push_notif_token&val=123" localhost:9292/set_fields
post '/set_fields' do
  field = params['field']
  val   = params['val']
  halt(401, 'bad_field') unless ['send_push_notifs', 'push_notif_token'].include? field  
  $users.update_id(cuid, {field => val})

  PushNotifs.register_device_token(val) if field == 'push_notif_token'

  {msg: 'ok'}
end

get '/users/which_phones_registered' do
  phones = params['phones'] || []
  res = {}; 
  phones.each { |phone| 
    user = $users.project({phone: phone}, [:_id]) || {}; 
    res[phone] = user['_id'] 
  }
  res
end

# ALGO part

def get_json(path)
  JSON.parse ((HTTPClient.new.get path).body) 
end

def get_facebook_profile_pics(user_fb_id, code)
  #get profile pics album_id
  path = "https://graph.facebook.com/v2.3/#{user_fb_id}/albums?access_token=#{code}"
  albums = get_json(path)
  
  profile_pics_album = (albums.data.select {|album| album['name'] == 'Profile Pictures'})[0]
  return [] unless profile_pics_album
  profile_pics_album_id = profile_pics_album['id']

  #get those pics
  pics_path = "https://graph.facebook.com/v2.3/#{profile_pics_album_id}/photos?access_token=#{code}"
  profile_pics = get_json(pics_path)
  final_pics = profile_pics.data.map {|photo| {image: photo['images'][0]}}
end

def get_facebook_tagged_pics(user_fb_id, code, limit)
  path = "https://graph.facebook.com/v2.3/#{user_fb_id}/photos?access_token=#{code}&limit=#{limit}"
  payload = get_json(path)
  res = payload['data'].map { |photo|     
     {image: photo['images'][0], 
     tag: photo['tags']['data'].select {|tag| tag['id'].to_s == user_fb_id.to_s}[0]
     } 
  }
end

def get_fb_pics_data(user_fb_id, code, limit)
  {
    user_fb_id: user_fb_id,
    profile_pics: get_facebook_profile_pics(user_fb_id, code),
    tagged_pics:  get_facebook_tagged_pics(user_fb_id, code, limit)
  }
end

get '/users/algo/pending_model' do 
  forced_user_id = params[:forced_user_id]
  if forced_user_id
    user = $users.get(forced_user_id)
  else 
    user = $users.find_one({model: NOMODEL})
  end

  return {msg: 'empty'} unless user

  limit = params[:limit] || 100
  fb_data = get_fb_pics_data(user['fb_id'], user['fb_data']['code'], limit)  
  $users.update_id(user['_id'], {model: {retrieved_at: Time.now}}) unless forced_user_id

  {user_id: forced_user_id || user['_id'],
   fb_data: fb_data}
end

post '/users/algo/model/set' do
  $users.update_id(params[:user_id],{model: params[:model]})
end

get '/users/algo/model/make_all_pending' do 
  $users.update({},{'$set': {model: NOMODEL}}, {multi: true})
end

get '/users/algo/model/get' do
  {model: $users.get(params[:user_id])['model']}
end