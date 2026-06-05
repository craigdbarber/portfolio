# Stage 1: Build the static assets
FROM node:20-alpine AS builder

WORKDIR /app

# Leveraging Docker cache for dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Stage 2: Serve via Nginx (Non-Root for Security)
FROM nginx:alpine

# Copy the server template
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Create a hardened, non-root main Nginx configuration
RUN rm /etc/nginx/nginx.conf && \
    printf 'worker_processes auto;\n\
pid /tmp/nginx.pid;\n\
events { worker_connections 1024; }\n\
http {\n\
    include /etc/nginx/mime.types;\n\
    client_body_temp_path /tmp/client_temp;\n\
    proxy_temp_path       /tmp/proxy_temp;\n\
    fastcgi_temp_path     /tmp/fastcgi_temp;\n\
    uwsgi_temp_path       /tmp/uwsgi_temp;\n\
    scgi_temp_path        /tmp/scgi_temp;\n\
    include /etc/nginx/conf.d/*.conf;\n\
}' > /etc/nginx/nginx.conf

# Copy the built Vite assets from Stage 1
COPY --from=builder /app/dist /usr/share/nginx/html

# Cloud Run best practice: SIGQUIT for graceful shutdown
STOPSIGNAL SIGQUIT

# Support non-root execution
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    chmod -R 755 /usr/share/nginx/html && \
    mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R nginx:nginx /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

USER nginx

# Cloud Run defaults to 8080
EXPOSE 8080
ENV PORT=8080

# The base image's entrypoint will use envsubst on our template at startup
