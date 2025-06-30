#!/bin/sh
set -eo pipefail # Exit on error, exit on unset variables, exit on pipefail

echo "DEBUG: entry_point.sh started at $(date)"
echo "DEBUG: Arguments passed: \"$@\"" # Show what arguments are being passed

DATABASE_URL_FILE="/run/secrets/DATABASE_URL"

# --- Verify Secret File Existence and Readability ---
if [ ! -f "$DATABASE_URL_FILE" ]; then
    echo "ERROR: Secret file not found at $DATABASE_URL_FILE. This is critical!"
    echo "ERROR: Ensure the 'DATABASE_URL' secret is properly mounted in your stack file."
    exit 1
fi

if [ ! -r "$DATABASE_URL_FILE" ]; then
    echo "ERROR: Secret file at $DATABASE_URL_FILE is not readable. Check permissions."
    exit 1
fi

# --- Read Secret Content ---
# Using read -r to prevent backslash interpretation and avoid leading/trailing whitespace issues
if IFS= read -r DB_SECRET_CONTENT < "$DATABASE_URL_FILE"; then
    echo "DEBUG: Secret content successfully read."
else
    echo "ERROR: Failed to read content from $DATABASE_URL_FILE."
    exit 1
fi

# Trim potential whitespace (though `read -r` should help, defensive coding)
DB_SECRET_CONTENT=$(echo "$DB_SECRET_CONTENT" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

echo "DEBUG: Raw DSN from secret: ->${DB_SECRET_CONTENT}<-"

# --- Validate DSN Content (Basic Check) ---
if [ -z "$DB_SECRET_CONTENT" ]; then
    echo "ERROR: DATABASE_URL content is empty after reading from secret. This is critical!"
    exit 1
fi
if ! echo "$DB_SECRET_CONTENT" | grep -q "postgres://"; then
    echo "WARNING: DATABASE_URL does not start with 'postgres://'. Check format: ->${DB_SECRET_CONTENT}<-"
fi


# --- Export the Environment Variable ---
export DATABASE_URL="$DB_SECRET_CONTENT"
echo "DEBUG: DATABASE_URL exported to environment."

# --- Verify Exported Variable (Crucial Test) ---
if [ -z "$(env | grep ^DATABASE_URL=)" ]; then
    echo "ERROR: DATABASE_URL was NOT successfully exported to the environment."
    echo "ERROR: This is a major issue in the script or shell environment."
    exit 1
fi
echo "DEBUG: DATABASE_URL in current environment (from env command): ->$(env | grep ^DATABASE_URL= | cut -d'=' -f2- )<-"


# --- Final Action: Execute pg_tileserv ---
echo "DEBUG: About to execute the original command: $@"
# Verify the actual command to be executed exists and is executable
if ! command -v "$1" >/dev/null 2>&1; then # Check if the first arg is an executable command
    echo "ERROR: The command '$1' (from \$@) was not found or is not executable."
    echo "ERROR: Ensure the base image's entrypoint is correct and available."
    exit 1
fi

# If the error is still "dial unix /tmp/.s.PGSQL.5432", it means pg_tileserv is likely NOT seeing the env var.
# This might indicate that the actual pg_tileserv executable does not pick up environment variables correctly
# OR there's another script/shim in the base image that overwrites or ignores it.

# Alternative: Pass DATABASE_URL directly as an argument if pg_tileserv supports it (usually not for this env var)
# Or, if pg_tileserv has an explicit flag for DB connection string:
# exec /usr/local/bin/pg_tileserv --database-url "$DATABASE_URL" "$@"

# Most likely scenario: the exec "$@" is correct if DATABASE_URL is truly exported
exec "$@"

# Fallback in case exec fails (though it shouldn't reach here if exec works)
echo "ERROR: exec command failed. This should not happen."
exit 1