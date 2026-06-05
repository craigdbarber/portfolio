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

# Copy the non-root template
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Override the default Nginx config to use our custom one
RUN rm /etc/nginx/conf.d/default.conf && \
    sed -i 's|/etc/nginx/conf.d/\*.conf|/etc/nginx/nginx.conf|' /etc/nginx/nginx.conf

# Copy the built Vite assets from Stage 1
COPY --from=builder /app/dist /usr/share/nginx/html

# Cloud Run best practice: SIGQUIT for graceful shutdown
STOPSIGNAL SIGQUIT

# Support non-root execution
RUN touch /tmp/nginx.pid && \
    chown -R nginx:nginx /tmp/nginx.pid /var/cache/nginx /var/log/nginx /etc/nginx/conf.d

USER nginx

# Cloud Run defaults to 8080
EXPOSE 8080
ENV PORT=8080

# The base image's entrypoint will use envsubst on our template at startup
