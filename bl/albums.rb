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

  def add_photos_data(al,cuid)
    id = al['_id']
    al[:num_photos] = $photos.find({album_id: id}).count 
    #al[:num_liked_or_computed] = $photos.find({:$and => [{album_id: al['_id']}, {:$or => [{"filters.#{cu}" => 'like'}, ] }]}).count
    al[:num_computed] = $photos.find({album_id: id, computed_filters: "#{cuid}"}).count 
    al[:num_liked] = $photos.find({album_id: id, "filters.#{cuid}" => 'like'}).count 
  end 
end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/mine' do  
    albums = $albums.find_all({owner_id: cuid}).to_a
    albums.each {|al| Albums.add_photos_data(al,cuid) }

    {albums: albums}
  end

  get '/:id' do
    album = Albums.get(params[:id]) 
    return 404 unless album
    album_photos        = $photos.find({album_id: album['_id']}).to_a    
    album[:photos_list] = album_photos
    Albums.add_photos_data(album,cu)
    album
  end 

  #create
  post '/' do
    res = Albums.create(params.merge!({owner_id: cuid}))
    {id: res[:_id]}
  end

  #update
  post '/:id' do
    res = Albums.update(params[:id], params) 
    Albums.get(params[:id]) || 404
    #(res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  end

end

