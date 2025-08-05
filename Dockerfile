FROM nginx:stable-alpine

# If you have a custom nginx.conf, copy it (else skip this line)
# COPY nginx.conf /etc/nginx/nginx.conf

# Copy your static content
COPY html/ /usr/share/nginx/html/

# (Optional) expose port, nginx base image already does this
EXPOSE 80

# Entrypoint/cmd inherited from base image

