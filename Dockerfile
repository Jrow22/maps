# Use the official pg_tileserv image
FROM pramsey/pg_tileserv:latest

# Expose the port pg_tileserv uses
EXPOSE 7800

# --- ADD THESE LINES ---

# Copy the custom entrypoint script into the image
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set this script as the container's entrypoint
# This means /usr/local/bin/entrypoint.sh will be executed first
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]