FROM ubuntu:latest

WORKDIR /home/user

# Install nginx (with Lua module), supervisor and tools to download GoTTY
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nginx \
      libnginx-mod-http-lua \
      lua-cjson \
      supervisor \
      ca-certificates \
      wget \
      tar && \
    rm -rf /var/lib/apt/lists/*

# Copy nginx configuration and static files
COPY nginx /home/user/nginx

# Copy supervisord configuration to expected location
COPY supervisor/supervisord.conf /home/user/supervisord.conf

# Prepare directories used by nginx logs and temp files
RUN mkdir -p /home/user/logs \
    /home/user/nginx/tmp/body \
    /home/user/nginx/tmp/proxy \
    /home/user/nginx/tmp/fastcgi \
    /home/user/nginx/tmp/uwsgi \
    /home/user/nginx/tmp/scgi

# Download and install GoTTY into /home/user
RUN wget -O /tmp/gotty_v1.6.0_linux_amd64.tar.gz \
      "https://github.com/sorenisanerd/gotty/releases/download/v1.6.0/gotty_v1.6.0_linux_amd64.tar.gz" && \
    tar -xzf /tmp/gotty_v1.6.0_linux_amd64.tar.gz -C /home/user && \
    chmod +x /home/user/gotty && \
    rm /tmp/gotty_v1.6.0_linux_amd64.tar.gz

EXPOSE 7860

CMD ["supervisord", "-c", "/home/user/supervisord.conf"]
