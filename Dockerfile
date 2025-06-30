# Use the official pg_tileserv image
FROM pramsey/pg_tileserv:latest

# Expose the port pg_tileserv uses
EXPOSE 7800

# --- CORRECTED LINE ---
# Copy the custom entrypoint script into the image and set permissions directly using octal format
COPY --chmod=0755 entry_point.sh /usr/local/bin/entry_point.sh

# Remove the problematic RUN chmod +x line:
# RUN chmod +x /usr/local/bin/entrypoint.sh

# Set this script as the container's entrypoint
ENTRYPOINT ["/usr/local/bin/entry_point.sh"]