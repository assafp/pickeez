$albums = $mongo.collection('albums')

SETTABLE_ALBUM_FIELDS = [:owner_id, :name, :accepted_members, 
                         :pending_members, :last_modified, :last_modifying_user,
                         :deleted
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

  def add_photos_data(album,cuid)
    album_photos        = $photos.find({album_id: album['_id']}).to_a    
    #album[:photos_list] = album_photos

    users = album['invited_phones'].map {|phone| Users.basic_data(:phone, phone) }
    users.push(Users.basic_data(:_id, album['owner_id']))
    users.compact! 
    
    album[:total_filtered] = 0

    users.each {|user| 
      user[:photos] = album_photos.select {|p| p['owner_id'] == user['_id'] } 
      user[:photos].each {|p| 
        if p.fetch('filters',{})[cuid] == 'like'
          p['manually_filtered'] = true 
          album[:total_filtered] += 1        
        elsif p.fetch('filters',{})[cuid] == 'dislike'
          p['manually_unfiltered'] = true 
        elsif p.fetch('computed_filters',[]).include? cuid
          p['computed'] = true 
          album[:total_filtered] += 1
        end
        p.delete('computed_filters')
        p.delete('filters')
      }
    }
    album[:users] = users    
  end

end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/mine' do      
    #albums = $albums.find_all({owner_id: cuid}).to_a
    albums = $albums.find(:$and => [{owner_id: "2"}, {deleted: {'$ne' => 'true'}}]).to_a

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
    album
  end 

  #create
  post '/' do
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

  post '/:id/invite_phones' do 
    album = Albums.get(params[:id])
    album_id = album['_id']
    invited_phones = params['phones'] || []
    halt(401, 'not album owner') unless cuid == album['owner_id']
    
    if params['remove'] 
      $albums.update({_id: album_id}, {'$pullAll' => {invited_phones: invited_phones  } })
    else 
      $albums.update({_id: album_id}, {'$addToSet' => {invited_phones: {'$each': invited_phones } } })
    end

    updated_album_phones = $albums.project({_id: album_id}, ['invited_phones'])['invited_phones']
    #TODO: send SMSs and push notifications 
    {updated_album_phones: updated_album_phones}
  end  
end

