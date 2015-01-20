use Rack::Parser, :content_types => {
  'application/json'  => Proc.new { |body| ::MultiJson.decode body }
}

before do
  @client_id = sc[:facebook_app_id]
  @client_secret = sc[:facebook_app_secret]
end