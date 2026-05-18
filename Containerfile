# Terrain Profile / Radio Path Analyzer — container image
#
# Static HTML served by nginx. Uses nginx-alpine for a small (~50MB) image.
#
# Build:  podman build -t terrain-profile .
# Run:    podman run -d -p 8080:80 --name terrain terrain-profile
# Visit:  http://localhost:8080

FROM docker.io/library/nginx:alpine

# Replace nginx's default welcome page with our app
COPY terrain-profile.html /usr/share/nginx/html/index.html

# Custom nginx config: gzip text assets, set sensible cache headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# nginx:alpine already sets a healthcheck-friendly CMD; nothing more needed.
