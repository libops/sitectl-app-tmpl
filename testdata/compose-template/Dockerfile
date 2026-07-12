ARG BASE_IMAGE=libops/base:3.2.2.0@sha256:2382876ad70c936e99f6b838fb16c709cb9d9f91e6aa3be5625355ee1f3fab90
FROM ${BASE_IMAGE}

RUN install -d -m 0755 /srv/app && \
    printf '%s\n' 'sitectl application template fixture' >/srv/app/index.html && \
    touch /installed

EXPOSE 8080

HEALTHCHECK --interval=2s --timeout=2s --retries=30 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

CMD ["busybox", "httpd", "-f", "-p", "8080", "-h", "/srv/app"]
