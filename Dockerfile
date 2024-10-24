# Use the nginx base image
FROM nginx:alpine

# Copy survey.html to be served as index.html
COPY ./survey.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
