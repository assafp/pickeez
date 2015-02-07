$albums = $mongo.collection('albums')

SETTABLE_ALBUM_FIELDS = [:owner_id, :name, :accepted_members, 
                         :pending_members, :last_modified, :last_modifying_user
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

  def add_photos_data(al,uid)
    id = al['_id']
    bp
    al[:num_photos] = $photos.find({album_id: id}).count 
    #al[:num_liked_or_computed] = $photos.find({:$and => [{album_id: al['_id']}, {:$or => [{"filters.#{cu}" => 'like'}, ] }]}).count
    al[:num_computed] = $photos.find({album_id: id, computed_filters: "#{uid}"}).count 
    al[:num_liked] = $photos.find({album_id: id, "filters.#{uid}" => 'like'}).count 
  end 
end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/mine' do  
    albums = $albums.find_all({owner_id: cuid}).to_a
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

    album_photos        = $photos.find({album_id: album['_id']}).to_a    
    #album[:photos_list] = album_photos

    users = album['invited_phones'].map {|phone| Users.basic_data(:phone, phone) }
    users.push(Users.basic_data(:_id, album['owner_id']))
    users.compact! 
    
    users.each {|user| user[:photos] = album_photos.select {|p| p['owner_id'] == user['_id'] } }
    album[:users] = users    
    album
  end 

  #create
  post '/' do
    res = Albums.create(params.merge!({owner_id: cuid}))
    {_id: res[:_id]}
  end

  #update
  post '/:id' do
    res = Albums.update(params[:id], params) 
    Albums.get(params[:id]) || 404
    #(res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  end

  post '/:id/invite_phones' do 
    album = Albums.get(params[:id])
    album_id = album['_id']
    invited_phones = params['phones']
    halt(401, 'not album owner') unless cuid == album['owner_id']
    $albums.update({_id: album_id}, {'$addToSet': {invited_phones: {'$each': invited_phones } } })
    #TODO: send SMSs and push notifications 
    {invited_phones: invited_phones}
  end

end

