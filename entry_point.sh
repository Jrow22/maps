#!/bin/sh

# Read the content of the secret file
DB_SECRET_CONTENT=$(cat /run/secrets/DATABASE_URL)

# Set the DATABASE_URL environment variable to the content of the secret

echo "DEBUG: DSN read from secret: ->${DB_SECRET_CONTENT}<-"


export DATABASE_URL="$DB_SECRET_CONTENT"

# Execute the original command of the image (which starts pg_tileserv)
# This uses "$@" to pass any arguments that would normally be given to the container.
exec "$@"