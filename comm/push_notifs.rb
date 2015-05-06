module PushNotifs
  extend self

  def send_notif(user_ids, alert, info, badge = nil)
    device_tokens_arr = get_device_tokens(user_ids)
    body  = info.merge({auth_token: ENV['PICKEEZ_ZEROPUSH_TOKEN']})
    route = "https://api.zeropush.com/notify"  
    token = ENV['PICKEEZ_ZEROPUSH_TOKEN'] 
    res = HTTPClient.new.post(route, {auth_token:token, "device_tokens[]" => device_tokens_arr, info: info.to_json, alert: alert, badge: badge})
    
    {msg: "ok", res: res.body}
  end  

  def send_album_filtered(user_ids, album_id)
    album_name = $albums.get(album_id)['name']
    alert = "Your best pictures are waiting for you from your album #{album_name}!"
    
    send(user_ids, alert, {album_id: album_id})
  end

  def send_uploaded_photos(uploader_id, album_id)
    uploader_name = $users.get(uploader_id)['name']
    album = $albums.get(album_id)
    album_name = album['name']
    album_users = Albums.album_users(album)[:users]
    other_users = album_users.reject {|id| id == uploader_id}
    alert = "#{uploader_name} has added photos to the album #{album_name}! Come see your best pics from pickeez!"
    
    send_notif(other_users, alert, {album_id: album_id})
  rescue => e
    res = $errors.add(e.to_json)
  end

  #helpers

  def get_device_tokens(user_ids)
    $users.find({_id: {"$in": user_ids}}).map {|u| u['push_notif_token'] }.compact
  end

end


