Welcome to pickeez backend for managing Pickeez data. 

Important routes, in expected chronological order of usage (HTTP GET unless otherwise specified):

> '/fb' - will redirect you (in browser) to approve app (temporary app. ID: 311069229089167).

> '/fb_enter?code=abcd...' 
  - hit this route with the code after app-aproval on FB
  - will create user if non-existent, and return pickeez token. Send this token in any further request.
  - this route is redirected to after hitting route '/fb' in browser. 

> '/me' - will return the user pickeez identifies as sending the request. Send with pickeez token, as in '/me?token=wqQjsY0j4-3biVLi8C0EYwCa18RFzzBrNqBVduipoo-w'

> POST '/albums/create' - creates an album, returns created album_id. You may also supply an 'album_local_id' parameter.

> POST '/albums/123?name=donkey' - updates album 123 with params sent, such as 'name'. (Send post params in body request, of course.) You can also update fields like 'local_album_id'.

  > to delete album, supply parameter 'deleted=true' to this call. 

> '/albums/mine' - returns list of albums belonging to requesting user. 

> POST '/photos/' - add a photo. Required params are 's3_path' and a valid album_id. You may also send 's3_server_id' and 'photo_local_id' and 'photo_creation_date' and 'local_creation_date'..

> '/albums/123' - gets album with its photos, grouped by users.  

> POST '/set_phone?phone=4567' - sets phone number of requesting user to 4567. (Does not yet send SMS.)

> POST '/resend_code_sms' - resends the code as an sms. 

> POST '/confirm_phone?code=3456' - marks phone number as confirmed if code is correct.    

> POST "phones[]=555&phones[]=777" '/albums/123/invite_phones' - invites phones 555 and 777 to album 123. Adding parameter "remove=true" *removes* each of these phones instead of adding them (which has the effect of deleting a user from album). If added later, their photos will be re-added. 

> POST '/albums/123/delete' - deletes that album. (Actually only marks it as deleted so it won't be retrieved when calling list of albums). 

> POST '/albums/123/viewed' - adds the sending user to list of users marked that have viewed this album.

> POST '/delete_me?sure=yes' - deletes this user and all albums he is the owner of. 

> log out (client side only, remove token)

> POST '/set_pic_url?pic_url=blabla' - set user pic url by 'pic_url' param.

// new routes, March 2015:

> POST /albums/3573/done_uploading - to signify album is ready to be processed

> POST "album_local_id=123" /albums/7762/set_album_local_id (to set album_local_id)

> POST "type=like" /photos/7762/set_filter  (or "type=dislike")

> POST "photo_local_id=123" /photos/7762/set_photo_local_id (to set photo_local_id)

> POST /photos/7762/delete - remove photo

$ curl -X POST -H "Content-Type: application/json" -d '{"rectangles": [{"x": 1, "y": 2, "width": 3, "height": 4}, {"x": 5.1, "y": 6, "width": 7, "height": 8} ], "detected_faces_data": {"face": "yes", "eyes": "no"} }' "pickeezmetadata.com/photos/9432/set_faces_data"
  # verify by pickeezmetadata.com/photos/9432
> POST /photos/4092/set_faces_data

$ curl -g "www.pickeezmetadata.com/users/which_phones_registered?phones[]=10&phones[]=20"
> /users/which_phones_registered 
  > usage example: GET www.pickeezmetadata.com/users/which_phones_registered?phones[]=972522934321&phones[]=20&token=TOKEN

$ curl -d "field=send_push_notifs&val=false" localhost:9292/set_fields
$ curl -d "field=push_notif_token&val=123abc" localhost:9292/set_fields
> /set_fields (to set push notification setting and token)

// data for invite page:

> /invite_page?album_id=ID -> returns a JSON with album data for invite page. 

$.get('http://pickeezmetadata.com/invite_page?album_id=hvg23nsg49679',function(s) { console.log(s)})


// ALGO part (For Uri and Gidi)

IMPORTANT: In all of the 'algo' routes, you must supply a URL param called 'password' with the correct value. (Ask Sella.)

> /users/algo/pending_model - returns user for which there is no model, along with his profile pics and tagged pics. If you pass a "forced_user_id" parameter it will force this user (and not mark his model when done). E.g.: http://pickeezmetadata.com/users/algo/pending_model?forced_user_id=hwh9qclckg846 

Models are set to 'empty' when a user is created, and set to non-nil after being called on 'pending'. You can set the as whatever you want by /model/set, below. You can also set ALL user models as pending using the following route:

> /users/algo/model/make_all_pending

> /users/algo/model/get - pass parameter 'user_id' to get that user's model. Pass 'limit' to set number of pics to retrieve (default is 100). Pass param 'forced_user_id' to force that user_id (and not update 'pending' status or model). 

> POST /users/algo/model/set - pass 'user_id' (string) and 'model' (JSON) parameters to set that model for that user. 

> /albums/algo/get_pending - gets next pending album. 

> GET /albums/algo/remove_pending - removes list of pending albums. 

> albums/algo/all_pending - debugging route, shows you list of pending albums (but does not update when taking one.)

> albums/algo/set_all_as_pending - sets every single existing album as pending. 

Integration example (if you are unfamiliar with cURL, LMK.)

- Go to www.pickeezmetadata.com/fb (in browser) and get your user TOKEN. 
- $ curl www.pickeezmetadata.com/albums/algo/all_pending?password=PASSWORD - no pending albums (debugging route)
- $ curl www.pickeezmetadata.com/albums/algo/get_pending - empty
- $ curl -d "token=TOKEN" www.pickeezmetadata.com/albums/create - get ALBUM_ID
- $ curl -d "s3_path=123&album_id=ALBUM_ID&token=TOKEN" www.pickeezmetadata.com/photos/
- $ curl www.pickeezmetadata.com/albums/algo/get_pending?password=PASSWORD - empty (60 seconds not passed, and not marked as done_uploading)
- $ curl www.pickeezmetadata.com/albums/algo/all_pending?password=PASSWORD - see there is a pending album, but its time_updated is not old enough.
- Now wait 60 seconds, and then call:
  - $ curl www.pickeezmetadata.com/albums/algo/get_pending?password=PASSWORD - gets the album
  - $ (call get_pending again) - nothing there now.

Repeat all the steps and this time instead of waiting 60 seconds, call

- $ curl -d "token=TOKEN" "www.pickeezmetadata.com/albums/ALBUM_ID/done_uploading"
- $ curl www.pickeezmetadata.com/albums/algo/all_pending?password=PASSWORD - see album's state has changed to 'done uploading'
- $ curl www.pickeezmetadata.com/albums/algo/get_pending?password=PASSWORD - gets the album
- $ (call get_pending again) - nothing there now. 

> POST 'photos/algo/set'
  > curl -X POST -H "Content-Type: application/json" -d '{"photos": {"photo_id": {"user_id_1": true, "user_id_2": false }}}' "www.pickeezmetadata.com/photos/algo/set"

Integration example:

- create album (ALBUM_ID) and photo (PHOTO_ID) with your TOKEN.

- curl www.pickeezmetadata.com/albums/ALBUM_ID - make sure your photo is in the album
- curl -X POST -H "Content-Type: application/json" -d '{"photos": {"PHOTO_ID": {"USER_ID": true }}}' "www.pickeezmetadata.com/photos/algo/set?password=PASSWORD"
- curl www.pickeezmetadata.com/photos/PHOTO_ID to make sure the photo has the filters.
- curl www.pickeezmetadata.com/albums/ALBUM_ID to make sure the album reflects the photo filters. 

******

TBD: Sending push notifs.