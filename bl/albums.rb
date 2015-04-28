$albums = $mongo.collection('albums')
$pending_albums = $mongo.collection('pending_albums')

SETTABLE_ALBUM_FIELDS = [:owner_id, :name, :accepted_members, 
                         :pending_members, :last_modified, :last_modifying_user,
                         :deleted, :local_album_id
                         ]

REQUIRED_ALBUM_FIELDS = [:owner_id]

module Albums
  extend self

  def white_fields(params)
    params.just(SETTABLE_ALBUM_FIELDS)
  end

  def create(params)
    $albums.add(white_fields(params))
  end

  def update(id, params)    
    res = $albums.update_id(id, white_fields(params))    
  end

  def get(id)
    $albums.get(id)
  end

  def add_photos_data_old(al,uid)
    id = al['_id']
    al[:num_photos] = $photos.find({album_id: id}).count 
    #al[:num_liked_or_computed] = $photos.find({:$and => [{album_id: al['_id']}, {:$or => [{"filters.#{cu}" => 'like'}, ] }]}).count
    al[:num_computed] = $photos.find({album_id: id, computed_filters: "#{uid}"}).count 
    al[:num_liked] = $photos.find({album_id: id, "filters.#{uid}" => 'like'}).count 
    al[:total_filtered] = al[:num_computed] + al[:num_liked]
  end

  def album_users(album)
    users = []
    phones_without_users = []
    album.fetch('invited_phones', []).each {|phone|       
      phone_8_digits = phone.to_s.split(//).last(8).join
      user = Users.basic_data(:verified_phone, phone) || Users.basic_data(:phone_8_digits, phone_8_digits)
      user ? users.push(user) : phones_without_users.push(phone)
    }
    owner = Users.basic_data(:_id, album['owner_id'])
    owner[:is_owner] = true
    users.push(owner)
    users.compact! 
    {users: users, phones_without_users: phones_without_users}
  end

  def add_photos_data(album,cuid) #for the app's view
    album_photos        = $photos.find({album_id: album['_id']}).to_a    
    #album[:photos_list] = album_photos
    album_users = Albums.album_users(album)
    users = album_users[:users]
    pending_phones = album_users[:phones_without_users]
    
    album[:total_filtered] = 0

    users.each {|user| 
      user[:photos] = album_photos.select {|p| p['owner_id'] == user['_id'] } 
      user[:photos].each {|p| 
        if p.fetch('filters',{})[cuid] == 'like'
          p['manually_filtered'] = true 
          album[:total_filtered] += 1        
        else 
          p['manually_filtered'] = false
        end

        if p.fetch('filters',{})[cuid] == 'dislike'
          p['manually_unfiltered'] = true 
        else 
          p['manually_unfiltered'] = false
        end

        if p.fetch('computed_filters',[]).include? cuid
          p['computed'] = true 
          album[:total_filtered] += 1
        else 
          p['computed'] = false
        end
        
        p.delete('computed_filters')
        p.delete('filters')
        p.delete('algo_decision')
      }
    }

    album[:pending_phones] = pending_phones
    album[:users] = users    
  end

  def mark_pending(id)
    $pending_albums.update({album_id: id},{'$set' => {time_updated: Time.now}}, {upsert: true})
  end

  def mark_user_albums_as_pending(phone_8_digits)
    albums = Albums.mine_by_phone([phone_8_digits])
    albums.each {|x| }
  end

  def delete_pending_by_user(user_id)
    user_album_ids = $albums.find({owner_id: user_id}).to_a.map {|a| a['_id']}
    user_album_ids.each {|album_id| $pending_albums.remove({album_id: album_id}) }
  end

  def mine_by_phone(phones_arr, owner_id = 123)
    $albums.find(:$and => [      
      {:$or => [{owner_id: owner_id}, {invited_phones: {'$in' => phones_arr}}]},
      {deleted: {'$ne' => 'true'}}
      ]).to_a
  end

end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/mine' do      
    #albums = $albums.find_all({owner_id: cuid}).to_a
    verified_phone = cu['verified_phone'] || 'no-such-phone'
    phone_8_digits = cu['phone_8_digits'] || 'no_8_digit_phone'
    
    albums = Albums.mine_by_phone([verified_phone,phone_8_digits], cuid)

    albums.each {|al| 
      Albums.add_photos_data(al,cuid) 
      al['owner'] = $users.find({_id: al['owner_id']}, {fields: ['name', 'pic_url']}).first
    }

    {albums: albums}
  end

  get '/:id' do
    album = Albums.get(params[:id]) 
    return 404 unless album    
    Albums.add_photos_data(album,cuid)
    album['owner_name'] = (($users.find_one(album['owner_id']) || {})['fb_data'] || {})['name']
    album
  end 

  #create
  post '/create' do
    res = Albums.create(params.merge!({owner_id: cuid}))
    {_id: res[:_id]}
  end

  #update
  post '/:id' do
    id = params[:id]
    album = Albums.get(id)
    return 404 unless album
    halt(401, 'not album owner') unless cuid == album['owner_id']

    res = Albums.update(id, params) 
    Albums.get(id) || 404
  end

  post '/:id/delete' do 
    id = params[:id]
    $albums.update({_id: id}, '$set': {deleted: true})
    Albums.get(id) || 404
  end

  # curl -d "" "localhost:9292/albums/3573/done_uploading"
  post '/:id/done_uploading' do    
    halt(401, "No such album") unless $albums.exists?(params[:id])
    $pending_albums.update({album_id: params[:id]},{'$set' => {done_uploading: "true"}}, {upsert: true})
    {msg: "updated done uploading"}
  end

  #curl -d "phones[]=052444" localhost:9292/albums/3134/invite_phones
  post '/:id/invite_phones' do 
    album = Albums.get(params[:id])
    album_id = album['_id']
    invited_phones = params['phones'] || []
    removing_my_phone = (invited_phones.size == 1) && (invited_phones[0] == cu['verified_phone']) && params['remove']

    halt(401, 'not album owner') unless (cuid == album['owner_id']) || removing_my_phone
    
    invited_phones = invited_phones.map {|phone| phone.to_s.split(//).last(8).join }

    if params['remove'] 
      $albums.update({_id: album_id}, {'$pullAll' => {invited_phones: invited_phones  } })
    else 
      $albums.update({_id: album_id}, {'$addToSet' => {invited_phones: {'$each': invited_phones } } })
    end

    invited_phones.each do |phone_8_digits| 
      invited_existing_user = Users.basic_data(:phone_8_digits, phone_8_digits)
      if invited_existing_user 
        Albums.mark_pending(params[:id])  
        break
      end
    end
    
    updated_album_phones = $albums.project({_id: album_id}, ['invited_phones'])['invited_phones']
    #TODO: send SMSs and push notifications? 
    {updated_album_phones: updated_album_phones, link_id: album_id}
  end  

  post '/:id/viewed' do
    $albums.update({_id: params[:id]}, { '$addToSet' => {users_viewed: cuid } })
    {msg: "ok"}
  end

  # // algo part

  get '/algo/all_pending' do
    {pending_albums: $pending_albums.all,
      msg: 'This is just a debugging route.'}
  end

  post '/algo/remove_pending' do 
    $pending_albums.remove
  end

  get '/algo/get_pending' do
    begin
    
    default_res = { status: 'empty', msg: 'empty' }
    #pending_album   = $pending_albums.find_one({time_updated: { '$lt' => Time.now - 60}}) 
    pending_album ||= $pending_albums.find_one({done_uploading: "true"}) 
    
    forced_album_id = params[:forced_album_id]
    if forced_album_id
      pending_album = $albums.get(forced_album_id) 
      pending_album['album_id'] = forced_album_id
    end

    testing = false
    pending_album = {'_id' => "3573"} if testing

    if pending_album
      pending_id = pending_album['album_id']
      $pending_albums.remove({album_id: pending_id}) unless forced_album_id

      album  = Albums.get(pending_id)
      users  = album.fetch(['invited_phones'], {}).map {|phone| Users.basic_data(:phone, phone) }
      photos = $photos.find_all({album_id: pending_id}).map { |p| p.just(:_id, :s3_path, :computed_filters, :filters, :num_faces, :rectangles, :detected_data, :owner_id) }
      {status: 'ok',
       album_id: pending_id,
       album: album,
       users: Albums.album_users(album)[:users],
       photos: photos
      }
    else 
      default_res
    end
    rescue => e
      $pending_albums.remove({album_id: pending_id}) if pending_id
      default_res.merge({error: e})
    end
  end

end

