FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Base dependencies: supervisor + nginx + basic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg bash \
    supervisor nginx-full \
    wget \
 && rm -rf /var/lib/apt/lists/*

# Install OpenResty (nginx with built-in LuaJIT & ngx_lua)
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/openresty.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
      | tee /etc/apt/sources.list.d/openresty.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends openresty && \
    rm -rf /var/lib/apt/lists/*

# Non-root user paths (UID 1000)
RUN mkdir -p /home/user && chown -R 1000:1000 /home/user
ENV HOME=/home/user
WORKDIR /home/user

# Logs dir
RUN mkdir -p /home/user/logs && chown -R 1000:1000 /home/user/logs

# Nginx config and static files
RUN mkdir -p /home/user/nginx && chown -R 1000:1000 /home/user/nginx
COPY --chown=1000:1000 nginx/nginx.conf /home/user/nginx/nginx.conf
COPY --chown=1000:1000 nginx/default_admin_config.json /home/user/nginx/default_admin_config.json
COPY --chown=1000:1000 nginx/route-admin /home/user/nginx/route-admin
RUN mkdir -p \
      /home/user/nginx/tmp/body \
      /home/user/nginx/tmp/proxy \
      /home/user/nginx/tmp/fastcgi \
      /home/user/nginx/tmp/uwsgi \
      /home/user/nginx/tmp/scgi \
    && chown -R 1000:1000 /home/user/nginx

# Supervisor config
COPY --chown=1000:1000 supervisor/supervisord.conf /home/user/supervisord.conf

# Download and install GoTTY into /home/user
RUN wget -O /tmp/gotty_v1.6.0_linux_amd64.tar.gz \
      "https://github.com/sorenisanerd/gotty/releases/download/v1.6.0/gotty_v1.6.0_linux_amd64.tar.gz" && \
    tar -xzf /tmp/gotty_v1.6.0_linux_amd64.tar.gz -C /home/user && \
    chown 1000:1000 /home/user/gotty && \
    chmod +x /home/user/gotty && \
    rm /tmp/gotty_v1.6.0_linux_amd64.tar.gz

# Ensure OpenResty binaries present in PATH
ENV PATH=/usr/local/openresty/bin:$PATH

EXPOSE 7860

# Run as UID 1000 (consistent with configs)
USER 1000
CMD ["supervisord", "-c", "/home/user/supervisord.conf"]
