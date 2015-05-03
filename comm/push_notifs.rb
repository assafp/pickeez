def send_push_notif(device_tokens_arr,info)
  body  = info.merge({auth_token: ENV['PICKEEZ_ZEROPUSH_TOKEN']})
  route = "https://api.zeropush.com/notify"  
  token = ENV['PICKEEZ_ZEROPUSH_TOKEN']
  bp
  #res = HTTPClient.new.post(route, {auth_token:ENV['PICKEEZ_ZEROPUSH_TOKEN'], "device_tokens[]" => device_tokens_arr, badge: params[:badge], category: params[:category], alert: params[:alert]})
  res = HTTPClient.new.post(route, {auth_token:token, "device_tokens[]" => device_tokens_arr, info: info.to_json})
  
  {msg: "ok", res: res.body}
end  