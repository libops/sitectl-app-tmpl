ARG BASE_IMAGE=libops/base:3.2.2.0@sha256:aa0c61029734f3293bca068a95c72c0b07ac949292c446c83ada78e81a42c85d
FROM ${BASE_IMAGE}

COPY fixture-httpd.sh fixture-install.sh /tmp/

RUN /tmp/fixture-install.sh

EXPOSE 8080

HEALTHCHECK --interval=2s --timeout=2s --retries=30 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:8080/"]

CMD ["/usr/local/bin/fixture-httpd"]
