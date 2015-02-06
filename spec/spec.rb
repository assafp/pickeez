require './lib_spec.rb'

$base_url = 'http://localhost:8002'

#basic test
get_raw '/'
assert(last_res.status = 200, 'ACK from /')

get '/test_login?test=1' #force sign-in as test user

#post album by name, get it by its id
album_name = "Album #{(Random.rand * 10000).to_i}"
post '/albums/', {name: album_name}

album_id = last_res["id"]
get "/albums/#{album_id}"
assert(last_res["name"] == album_name, "post album by name #{album_name}, get it by its id")

#post photo to album, get it by its id
post '/photos/', {album_id: album_id, s3_path: "some_path"}
photo_id = last_res["id"]
get "/photos/#{photo_id}"
assert(last_res["s3_path"] == "some_path", 'post photo, get by id, verify s3_path')
assert(last_res["album_id"] == album_id, 'post photo, get by id, verify album_id')

#repost photo with same album_id and s3_path, get same ID
post '/photos/', {album_id: album_id, s3_path: "some_path"}
should_be_same_photo_id = last_res["id"]
assert(should_be_same_photo_id == photo_id, "repost photo (same album and s3_path), expect to get same photo")

#post another photo to same album. get those photos by album
post '/photos/', {album_id: album_id, s3_path: "some_other_path"}
other_photo_id = last_res["id"]
get '/photos/?album_id='+album_id
photos_arr = last_res['photos']
photos_ids = photos_arr.map {|photo| photo["_id"] }
both_photos_found = (photos_ids.include? photo_id) && (photos_ids.include? other_photo_id)
assert(both_photos_found, "both photos retrieved by album")

#get my albums
get '/albums/mine'
albums = last_res['albums']
existing_album_found = albums.detect { |al| al['name'] == album_name  }
assert(existing_album_found, "previously created album retrieved with mine")
