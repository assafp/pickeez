$photos = $mongo.collection('photos')

SETTABLE_PHOTO_FIELDS = [:s3_path, :album_name, :inferred_data, 
                         :uploader_id, :name,
                         :computed_filters, :removed_by, :added_by]

REQUIRED_PHOTO_FIELDS = [:s3_path, :album_name]

module Photos
  extend self

  def white_fields(params)
    params.just(SETTABLE_PHOTO_FIELDS)
  end

  def create(params)
    $photos.add(white_fields(params))
  end

  def update(id, params)    
    res = $photos.update_id(id, white_fields(params))    

  end

  def get(id)
    $photos.get(id)
  end

end

namespace '/photos' do
  # before  { authenticate! }

  get '/stats' do
    {num: $photos.count, photos: $photos.all}
  end

  get '/:id' do
    Photos.get(params[:id]) || 404
  end 

  post '/' do    
    res = Photos.create(params)
    {id: res[:_id]}
  end

  post '/:id' do
    ensure_params REQUIRED_PHOTO_FIELDS
    res = Photos.update(params[:id], params) 
    (res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  end

end

