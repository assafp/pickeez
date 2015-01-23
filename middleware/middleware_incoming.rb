use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}



before do
  @client_id = ENV['PICKEEZ_FB_APP_ID']
  @client_secret = ENV['PICKEEZ_FB_APP_SECRET']

  #helpers. move to other global place..   
  # def authenticate!
  #   halt(401, {msg: 'No user found. Please sign in.'}) unless cu
  # end 

  def cu#rrent_user
    session && session['user_id']  
  end

  def ensure_params(required_params)    
    required_params.each { |p| halt(400, {msg: "Missing parameter: #{p}"}) unless params[p] }
  end
end

