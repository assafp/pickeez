$users = $mongo.collection('users')

SETTABLE_USER_FIELDS = [:name, :desc, :img, :phone, 
                :email, :fb_page, :website, :updated_at,
                :phone_verification_code, :verified_phone, :pic_url,
                :phone_8_digits
              ]

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
    pic_url = "http://graph.facebook.com/#{fb_id}/picture"
    name = fb_data['name']
    email = fb_data['email']
    data = {fb_id: fb_id, pic_url: pic_url, name: name, email: email, fb_data: fb_data}
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
    phone_8_digits = verified_phone.to_s.split(//).last(8).join #we use last 8 digits so 972521234567 matches 21234567, so when people invite using local number it'll work out.
    Users.update({id: cuid, verified_phone: verified_phone, phone_8_digits: phone_8_digits});
    Albums.mark_user_albums_as_pending(phone_8_digits)
    {ok: true}
  else 
    {err: 'wrong code'}
  end
end

get "/fb" do
  redirect "https://graph.facebook.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter_browser&scope=email"
end

get '/me' do
  current_user
end

#browser endpoint
get "/fb_enter_browser" do
  code = params[:code]
  endpoint = "https://graph.facebook.com/oauth/access_token?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter_browser&client_secret=#{@client_secret}&code=#{code}&scope=email"
  response = HTTPClient.new.get endpoint
  access_token = CGI.parse(response.body)["access_token"][0]
  
  #4. use auth-token to get user data
  endpoint = "https://graph.facebook.com/me?access_token=#{access_token}"
  response = HTTPClient.new.get endpoint
  fb_data = JSON.parse(response.body)
  fb_id = fb_data['id']
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

#Users.create_test_users

