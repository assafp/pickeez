use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}

before do
  @client_id = ENV['PICKEEZ_FB_APP_ID']
  @client_secret = ENV['PICKEEZ_FB_APP_SECRET']
  
  @user = $users.find_one(token: params[:token]) 
  
  PUBLIC_ROUTES = ['/fb_enter']  

  def test?
    return false if $prod 
    return true  if params[:test] || request.user_agent.include?('curl')
    false
  end

  # def test_login
  #   @user ||= Users.get_or_create_by_fb_id('test')['_id'] if test?
  # end
  def public_route?
    PUBLIC_ROUTES.include?(request.env['REQUEST_PATH'])
  end

  def stop_401
    halt(401, {msg: 'No user found. Please supply token or sign in.'})
  end

  def cu#rrent_user
    @user
  end

  def current_user 
    cu
  end

  def ensure_params(required_params)    
    required_params.each { |p| halt(400, {msg: "Missing parameter: #{p}"}) unless params[p] }
  end

  #test_login if test?
  stop_401 unless @user || public_route?
end

