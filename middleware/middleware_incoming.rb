use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}

before do
  @client_id = ENV['PICKEEZ_FB_APP_ID']
  @client_secret = ENV['PICKEEZ_FB_APP_SECRET']
  
  PUBLIC_ROUTES = ['/fb', '/fb_enter', '/routes', '/']  

  def test?
    return false if $prod 
    return true if request.user_agent.include?('curl')
    false
  end

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

  def cuid
    cu['_id']
  end

  def ensure_params(required_params)    
    required_params.each { |p| halt(400, {msg: "Missing parameter: #{p}"}) unless params[p] }
  end

  params[:token] = 1 if test?
  @user = $users.find_one(token: params[:token]) 
  stop_401 unless (params[:token] && @user) || public_route?
end

