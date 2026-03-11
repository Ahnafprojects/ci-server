# Dockerfile
FROM nginx:alpine
RUN apk upgrade --no-cache
COPY index.html /usr/share/nginx/html
EXPOSE 80
