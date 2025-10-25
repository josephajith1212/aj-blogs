# Stage 1: Build Hugo site
FROM klakegg/hugo:ext-alpine AS builder

# Set working directory
WORKDIR /src

# Copy all site files
COPY . .

# Build the site in "public" folder
RUN hugo --minify

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built site from previous stage
COPY --from=builder /src/public /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
