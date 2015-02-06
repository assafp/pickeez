$users = $mongo.collection('users')

SETTABLE_USER_FIELDS = [:name, :desc, :img, :phone, :email, :fb_page, :website,]

module Users
  extend self

  def create(params)
    $users.add(params.merge({token: SecureRandom.urlsafe_base64+SecureRandom.urlsafe_base64}))  
  end

  def get(id)
    $users.get(id)
  end

  def get_or_create_by_fb_id(fb_id, fb_data = {})
    fb_id = fb_id.to_s
    $users.get({fb_id: fb_id}) || create({fb_id: fb_id, fb_data: fb_data})
  end 

  def get_by_email(email)
    $users.find_one({email: email})
  end

  def update(params)    
    fields = params.just(SETTABLE_USER_FIELDS)
    $users.update_id(params.user_id, fields)    
  end

  def create_test_users
    (0..10).each {|i|
      $users.update({_id: i}, {_id: i, fb_id: i, token: i, name: "test_user_#{i}"}, {upsert: true})
    }
  end

end

get '/users' do
  {num: $users.count, users: $users.all}
end

get "/fb" do
  redirect "https://graph.facebook.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter"
end

get '/me' do
  current_user
end

#app will probably call this endpoint with code. 
get "/fb_enter" do
  code = params[:code]
  endpoint = "https://graph.facebook.com/oauth/access_token?client_id=#{@client_id}&redirect_uri=#{$root_url}/fb_enter&client_secret=#{@client_secret}&code=#{code}"
  response = HTTPClient.new.get endpoint
  access_token = CGI.parse(response.body)["access_token"][0]
  
  #4. use auth-token to get user data
  endpoint = "https://graph.facebook.com/me?access_token=#{access_token}"
  response = HTTPClient.new.get endpoint
  fb_data = JSON.parse(response.body)
  
  user = Users.get_or_create_by_fb_id(fb_data['id'], fb_data)
  {token: user['token']}
end

Users.create_test_users

