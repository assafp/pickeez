def send_push_notif(device_tokens_arr, alert, info, badge)
  body  = info.merge({auth_token: ENV['PICKEEZ_ZEROPUSH_TOKEN']})
  route = "https://api.zeropush.com/notify"  
  token = ENV['PICKEEZ_ZEROPUSH_TOKEN'] 
  #res = HTTPClient.new.post(route, {auth_token:ENV['PICKEEZ_ZEROPUSH_TOKEN'], "device_tokens[]" => device_tokens_arr, badge: params[:badge], category: params[:category], alert: params[:alert]})
  res = HTTPClient.new.post(route, {auth_token:token, "device_tokens[]" => device_tokens_arr, info: info.to_json, alert: alert, badge: badge})
  
  {msg: "ok", res: res.body}
end  