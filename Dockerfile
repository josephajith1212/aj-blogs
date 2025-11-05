# Stage 1: Build Hugo site
FROM hugomods/hugo:0.148.2 AS builder

WORKDIR /src

# Copy your Hugo site including themes
COPY . .

# Install Node.js & npm (needed for Tailwind)
RUN apk add --no-cache nodejs npm

# Install Tailwind CLI and dependencies
# (Assuming a package.json in the root of your project or inside theme)
WORKDIR /src/themes/blowfish
COPY themes/blowfish/package.json themes/blowfish/package-lock.json ./
RUN npm install

# Build the Tailwind CSS
RUN npx @tailwindcss/cli -c ./tailwind.config.js \
      -i ./assets/css/main.css \
      -o ../../assets/css/compiled/main.css

# Return to root and build your Hugo site
WORKDIR /src
# RUN hugo --minify #commenting this due to Nginx serve issue 
RUN hugo --baseURL "https://blogs-ajlabs.duckdns.org/" --minify --destination public/blog


# Stage 2: Serve with Nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
