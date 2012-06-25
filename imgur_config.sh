
# Get application keys from imgur.com and update below
export OAUTH_CONSUMER_KEY="GET-YOUR-OWN-OAUTH_CONSUMER_KEY"
export OAUTH_CONSUMER_SECRET="GET-YOUR-OWN-OAUTH_CONSUMER_SECRET"

# Update below path with the directory where pictures are
export PHOTO_ROOT_DIR=/home/moraesgp/pictures-test
export MOVE_PHOTO_DIR=/home/moraesgp/pictures-test-moved

# Change the logging diretory if you want but it's not mandatory
export LOGTEMPDIR=logtmp

# You should leave the rest of this file alone
export OAUTH_SIGN_METHOD="HMAC-SHA1"
export OAUTH_VERSION="1.0"

export REQUEST_TOKEN_URL="https://api.imgur.com/oauth/request_token"
export AUTHORIZE_URL="https://api.imgur.com/oauth/authorize"
export ACCESS_TOKEN_URL="https://api.imgur.com/oauth/access_token"
export IMAGES_API_URL="http://api.imgur.com/2/account/images"

export ACCESS_TOKEN_FILE="valid_access_token.sh"

export ALBUM_FILE_SUFFIX="_photo_to_album"
