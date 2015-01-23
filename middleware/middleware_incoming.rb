use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}

before do
  @client_id = ENV['PICKEEZ_FB_APP_ID']
  @client_secret = ENV['PICKEEZ_FB_APP_SECRET']

  def cu#rrent_user
    session && session['user_id']  
  end

end