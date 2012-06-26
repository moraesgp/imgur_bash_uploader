imgur_bash_uploader
===================

WARNING!!!

This is a work in progress. It's not yet functional

Client photo uploader written in bash shell scripting that talks to imgur.com using Oauth protocol

INSTALL

Since it's a shell script there is no need to install the application. But it does have some dependencies that should be installed:

1) cURL: C URL command line tool

sudo apt-get install curl

2) urlencode: It's an application that transforms strings into 'percent encode' so they can be used on URLs. It is within the package gridsite-clients. More information here: http://packages.debian.org/sid/gridsite-clients

sudo apt-get install gridsite-clients

3) xpath is the Perl wrapper to parse XML tags.

apt-get install libxml-xpath-perl

RUNNING

1) Get a pair of keys from http://imgur.com/. You need to register an application and the OauthConsumerKey and OauthSecretKey will be given to you. For this instructions let's say you gave your app the name Blah (You can give whatever name you want as long as it's not yet taken).

2) Use the keys from step 1 to update imgur_config.sh.

3) run ./main.sh

4) When you run imgur_bash_uploader for the first time it will connect to the imgur server and request a 'request token'. After aquiring the 'request token' it will generate an URL like this on your screen

https://api.imgur.com/oauth/authorize?oauth_token=sdoqe28849ruufdksjkjw92898eifukfjdklfiodioig

5) Open the above URL on your favorite browser. The imgur website will say something like 'the application Blah wants to access your account. Allow / Deny'. Login using your personal account. After that, imgur will generate an access token that will link your personal account with the next request your app Blah will make to imgur. It means, when imgur_bash_uploader uploads photos, they will be uploaded into the personal account you just logged in.

6) A file called valid_access_token.sh will be created with the access keys from the step above. That file will be used for future requests so you don't have to do steps 4 and 5 again. It's said that the access key is valid forever. If for some reason the key is revoked, the next time you run imgur_bash_uploader, it will go automatically thru steps 4 and 5 again and update valid_access_token.sh.

7) In the future imgur_bash_uploader will loop on a certain directory uploading file by file and creating albums from the directories names. That part is not yet implemented!

