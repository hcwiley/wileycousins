
#!/bin/sh
source .env
T="$(date "+%Y-%m-%dT%H:%M")"
mkdir -p ~/Dropbox/mongo-dumps/wileycousins-$T

mongodump -u $PRODUCTION_DB_USER -p $PRODUCTION_DB_USER -h $PRODUCTION_DB_HOST -d $PRODUCTION_DB_NAME -o ~/Dropbox/mongo-dumps/$PRODUCTION_DB_NAME-$T
