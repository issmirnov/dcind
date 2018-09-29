FROM amidos/dcind
MAINTAINER Ivan Smirnov <isgsmirnov@gmail.com>

# Install Docker and Docker Compose
RUN apk --update --no-cache \
    add git jq && \
    rm -rf /var/cache/apk/*
