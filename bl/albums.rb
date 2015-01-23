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

end

namespace '/albums' do

  get '/stats' do
    {num: $albums.count, albums: $albums.all}
  end

  get '/:id' do
    Albums.get(params[:id]) || 404
  end 

  post '/' do
    res = Albums.create(params)
    {id: res[:_id]}
  end

  post '/:id' do

    res = Albums.update(params[:id], params) 
    (res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  end

end

