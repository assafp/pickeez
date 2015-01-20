$users = $mongo.collection('users')

SETTABLE_USER_FIELDS = [:name, :desc, :img, :phone, :email, :fb_page, :website,]

module Users
  extend self

  def create(params)
    $users.add(params)  
  end

  def get(id)
    $users.get(id)
  end

  def get_or_create_by_fb_id(fb_id, fb_data)
    $users.get({fb_id: fb_id}) || create({fb_id: fb_id, fb_data: fb_data})
  end 

  def get_by_email(email)
    $users.find_one({email: email})
  end

  def update(params)    
    fields = params.just(SETTABLE_USER_FIELDS)
    $users.update_id(params.user_id, fields)    
  end

end
