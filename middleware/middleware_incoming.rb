use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}

helpers do 
  def foo #global
    'bar'
  end

  def stop_401(msg = nil)
    stop(401, msg || {msg: 'No user found. Please supply token or sign in.'})
  end

  def stop(status, msg)
    halt(status, msg)
  end
end

before '*/algo/*' do
  return unless $prod
  stop_401({msg: 'wrong password.'}) unless params[:password] == settings.algo_password
end

before do
  @client_id = ENV['PICKEEZ_FB_APP_ID']
  @client_secret = ENV['PICKEEZ_FB_APP_SECRET']
  
  PUBLIC_ROUTES = ['/fb', '/fb_enter', '/fb_enter_browser', '/routes', '/']  

  def test?
    return false if $prod 
    return true if request.user_agent.include?('curl')
    false
  end

  def public_route?
    PUBLIC_ROUTES.include?(request.env['REQUEST_PATH'])
  end

  def cu#rrent_user
    @user
  end

  def current_user 
    cu
  end

  def cuid
    cu['_id']
  end

  def ensure_params(required_params)    
    required_params.each { |p| halt(400, {msg: "Missing parameter: #{p}"}) unless params[p] }
  end

  params[:token] ||= "2" if test?
  @user = $users.find_one(token: params[:token]) 
  stop_401 unless (params[:token] && @user) || public_route?
end

