Welcome to pickeez backend for managing Pickeez data. 

Important routes, in expected chronological order of usage (HTTP GET unless otherwise specified):

> '/fb' - will redirect you (in browser) to approve app (temporary app).

> '/fb_enter?code=abcd...' 
  - hit this route with the code after app-aproval on FB
  - will create user if non-existent, and return pickeez token. Send this token in any further request.
  - this route is redirected to after hitting route '/fb' in browser. 

> '/me' - will return the user pickeez identifies as sending the request. Send with pickeez token, as in '/me?token=wqQjsY0j4-3biVLi8C0EYwCa18RFzzBrNqBVduipoo-w'

> POST '/albums/create' - creates an album, returns created album_id.

> POST '/albums/123?name=donkey' - updates album 123 with params sent, such as 'name'. (Send post params in body request, of course.) 

> '/albums/mine' - returns list of albums belonging to requesting user. 

> POST '/photos/' - add a photo. Required params are 's3_path' and a valid album_id.

> '/albums/123' - gets album with its photos. 

> POST '/set_phone?phone=4567' - sets phone number of requesting user to 4567. (Does not yet send SMS.)

> POST '/resend_code_sms' - resends the code as an sms. (Does not yet send SMS.)

> POST '/confirm_phone?code=3456' - marks phone number as confirmed if code is correct.    

> POST "phones[]=555&phones[]=777" '/albums/123/invite_phones' - invites phones 555 and 777 to album 123. 

TBD:

> Send SMS with code upon entering phone and when requesting resend. 
> Send SMS/push notif when inviting user to album

> when returning single album, include list of users. for each user:
            - id, name, thumbnailUrl, list of photos, for each photo
                                                        - url, id, camera_roll_id, is_algo_filtered (for requesting user), is_liked (for requesting user)
> delete album (by creator)

> remove user from album 
> log out
> delete user? 
> change profile pic 