$albums = $mongo.collection('albums')

SETTABLE_ALBUM_FIELDS = [:owner, :name, :accepted_members, 
                         :pending_members, :last_modified, :last_modifying_user
                         ]

REQUIRED_ALBUM_FIELDS = [:owner]

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

  def add_photos_data(al,cu)
    id = al['_id']
    al[:num_photos] = $photos.find({album_id: id}).count 
    #al[:num_liked_or_computed] = $photos.find({:$and => [{album_id: al['_id']}, {:$or => [{"filters.#{cu}" => 'like'}, ] }]}).count
    al[:num_computed] = $photos.find({album_id: id, computed_filters: "#{cu}"}).count 
    al[:num_liked] = $photos.find({album_id: id, "filters.#{cu}" => 'like'}).count 
  end 
end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/mine' do 
    albums = $albums.find_all({owner: current_user}).to_a
    albums.each {|al| Albums.add_photos_data(al,cu) }

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

  post '/' do
    res = Albums.create(params.merge!({owner: current_user}))
    {id: res[:_id]}
  end

  post '/:id' do
    res = Albums.update(params[:id], params) 
    (res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  end

end

