Welcome to pickeez backend for managing Pickeez data. 

Important routes, in expected chronological order of usage (HTTP GET unless otherwise specified):

> '/fb' - will redirect you (in browser) to approve app (temporary app. ID: 311069229089167).

> '/fb_enter?code=abcd...' 
  - hit this route with the code after app-aproval on FB
  - will create user if non-existent, and return pickeez token. Send this token in any further request.
  - this route is redirected to after hitting route '/fb' in browser. 

> '/me' - will return the user pickeez identifies as sending the request. Send with pickeez token, as in '/me?token=wqQjsY0j4-3biVLi8C0EYwCa18RFzzBrNqBVduipoo-w'

> POST '/albums/create' - creates an album, returns created album_id.

> POST '/albums/123?name=donkey' - updates album 123 with params sent, such as 'name'. (Send post params in body request, of course.) 

  > to delete album, supply parameter 'deleted=true' to this call. 

> '/albums/mine' - returns list of albums belonging to requesting user. 

> POST '/photos/' - add a photo. Required params are 's3_path' and a valid album_id.

> '/albums/123' - gets album with its photos, grouped by users.  

> POST '/set_phone?phone=4567' - sets phone number of requesting user to 4567. (Does not yet send SMS.)

> POST '/resend_code_sms' - resends the code as an sms. (Does not yet send SMS.)

> POST '/confirm_phone?code=3456' - marks phone number as confirmed if code is correct.    

> POST "phones[]=555&phones[]=777" '/albums/123/invite_phones' - invites phones 555 and 777 to album 123. Adding parameter "remove=true" *removes* each of these phones instead of adding them (which has the effect of deleting a user from album). If added later, their photos will be re-added. 

> POST '/albums/123/delete' - deletes that album. (Actually only marks it as deleted so it won't be retrieved when calling list of albums). 

> POST '/delete_me?sure=yes' - deletes this user and all albums he is the owner of. 

> log out (client side only, remove token)

> POST '/set_pic_url?pic_url=blabla' - set user pic url by 'pic_url' param.

// new routes, March 2015:

> POST /albums/3573/done_uploading

// ALGO part (For Uri and Gidi)

In all of the 'algo' routes, you must supply a URL param called 'password' with the correct value. (Ask Sella.)

> POST 'photos/algo/set'
  > curl -X POST -H "Content-Type: application/json" -d '{"photos": {"photo_id": {"user_id_1": true, "user_id_2": false }}}' "www.pickeezmetadata.com/photos/algo/set"

> /albums/algo/get_pending - gets next pending album. 

> /algo/all_pending - debugging route, shows you list of pending albums (but does not update when taking one.)

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

TBD:

> Send SMS with code upon entering phone and when requesting resend. 
> Send SMS/push notif when inviting user to album