$photos = $mongo.collection('photos')

SETTABLE_PHOTO_FIELDS = [:s3_path, :album_name, :inferred_data, 
                         :uploader_id, :foo,
                         :computed_filters, :removed_by, :added_by]

module Photos
  extend self

  def white_fields(params)
    params.just(SETTABLE_PHOTO_FIELDS)
  end

  def create(params)
    $photos.add(white_fields(params))
  end

  def update(id, params)    
    $photos.update_id(id, white_fields(params))    
  end

  def get(id)
    $photos.get(id)
  end

end

namespace '/photos' do

  get '/stats' do
    {num: $photos.count, photos: $photos.all}
  end

  get '/:id' do
    Photos.get(params[:id]) || 404
  end 

  post '/' do
    Photos.create(params)
  end

  post '/:id' do
    Photos.update(params[:id], params)
  end

end

