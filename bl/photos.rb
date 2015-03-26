$photos = $mongo.collection('photos')

SETTABLE_PHOTO_FIELDS = [:s3_path, :album_id, :inferred_data, 
                         :uploader_id, :name,
                         :computed_filters, :removed_by, :owner_id]

REQUIRED_PHOTO_FIELDS = [:s3_path, :album_id]

module Photos
  extend self

  def white_fields(params)
    params.just(SETTABLE_PHOTO_FIELDS)
  end

  def create(params)
    $photos.find_one(params.slice('album_id', 's3_path')) || $photos.add(white_fields(params))
  end

  def update(id, params)    
    res = $photos.update_id(id, white_fields(params))    
  end

  def get(id) #finds just one! 
    $photos.get(id)
  end

  def find_by(crit)
    $photos.find(crit).to_a
  end

end

namespace '/photos' do
  # before  { authenticate! }

  get '/stats' do
    {num: $photos.count, photos: $photos.all}
  end

  # get '/' do
  #   crit = params.slice('album_id')
  #   halt(401, {msg: 'Invalid params supplied.'}) unless crit['album_id']
  #   photos = Photos.find_by(crit)
  #   {photos: photos}
  # end

  get '/:id' do
    Photos.get(params[:id]) || 404
  end 

  # curl -d "s3_path=456&album_id=3573" localhost:9292/photos/
  post '/' do    
    ensure_params REQUIRED_PHOTO_FIELDS
    halt(401, "No such album") unless $albums.exists?(params[:album_id])
    data = params
    data[:owner_id] = cuid
    res = Photos.create(data)
    Albums.mark_pending(params[:album_id])
    {_id: res._id}
  end

  # post '/:id' do
  #   ensure_params REQUIRED_PHOTO_FIELDS
  #   halt(401, "Bad album ID - no such album") unless $albums.exists?(params[:album_id])
  #   res = Photos.update(params[:id], params) 
  #   (res[:updatedExisting] && res[:_id]) ? {id: res[:_id]} : 404      
  # end

  #curl -d "type=like" localhost:9292/photos/4128/set_filter
  post '/:id/set_filter' do     
    filter_type = {like: 'like', dislike: 'dislike'}[params[:type].to_sym] || 'none'
    $photos.update_id(params[:id], { "filters.#{cuid}" => filter_type } )
    {msg: "ok"}
  end

  #curl -d "action=push" localhost:8002/photos/4128/set_computed
  # post '/:id/set_computed' do     
  #   action = params[:action] == 'push' ? '$addToSet' : '$pull'
  #   $photos.update({_id: params[:id]}, { action => {computed_filters: cuid } })
  #   {msg: "ok"}
  # end

  # algo 

  # curl -X POST -H "Content-Type: application/json" -d '{"photos": {"4128": {"2": true, "1": false }}}' "localhost:9292/photos/algo/set"
  post '/algo/set' do
    photos = params[:photos]
    stop_401("No photos supplied.") unless photos    
    photos.each {|photo_id, tuples|
      #puts photo_id;
      tuples.each { |user_id, flag| 
        #puts "updating photo #{photo_id} for #{user_id}"
        action = flag == true ? '$addToSet' : '$pull'
        puts "running #{action} on #{user_id}"
        $photos.update({_id: photo_id}, { action => {computed_filters: user_id } }) 
      }       
    }
    'ok, set'
  end

end

