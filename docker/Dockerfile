# syntax=docker/dockerfile:1.7
# Satu Dockerfile untuk semua versi Odoo (14 s/d 19+).
# Base image dipilih Makefile: 14/15 -> 20.04, 16/17/18 -> 22.04, 19+ -> 24.04
ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_CODENAME=jammy
ARG PG_VERSION=16
ARG WKHTMLTOPDF_VERSION=0.12.6.1-3
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH=/opt/venv/bin:$PATH

# ---- Paket sistem + library build untuk dependensi Python Odoo ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git gnupg build-essential \
        python3 python3-dev python3-venv \
        libpq-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
        libssl-dev libffi-dev libjpeg-dev zlib1g-dev libfreetype6-dev \
        liblcms2-dev libwebp-dev \
        node-less npm \
        fontconfig libxrender1 libxext6 xfonts-75dpi xfonts-base \
        fonts-dejavu-core fonts-liberation fonts-noto-core \
    && npm install -g rtlcss \
    && rm -rf /var/lib/apt/lists/*

# ---- postgresql-client sama versi dengan server (agar pg_dump/backup jalan) ----
RUN install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${UBUNTU_CODENAME}-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-${PG_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# ---- wkhtmltopdf (patched Qt) - wajib untuk header/footer PDF Odoo ----
# Rilis resmi belum punya build "noble", paket "jammy" kompatibel di 24.04.
RUN set -eux; \
    case "${UBUNTU_CODENAME}" in noble) WK=jammy ;; *) WK="${UBUNTU_CODENAME}" ;; esac; \
    curl -fsSL -o /tmp/wkhtmltox.deb \
      "https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.${WK}_${TARGETARCH:-amd64}.deb"; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb; \
    rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*; \
    wkhtmltopdf --version

# ---- User non-root dengan UID/GID sama seperti host (file hasil edit tidak jadi milik root) ----
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && groupadd -o -g ${HOST_GID} odoo \
    && useradd -m -o -u ${HOST_UID} -g odoo -s /bin/bash odoo \
    && mkdir -p /opt/odoo /opt/enterprise /mnt/extra-addons /var/lib/odoo /etc/odoo \
    && chown -R odoo:odoo /opt/odoo /opt/enterprise /mnt/extra-addons /var/lib/odoo

# ---- Virtualenv + dependensi Python (diambil dari requirements.txt source Odoo) ----
RUN python3 -m venv /opt/venv
COPY --from=odoo_src requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -U pip wheel "setuptools<81" \
    && pip install -r /tmp/requirements.txt \
    && pip install debugpy watchdog ipython

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER odoo
WORKDIR /opt/odoo
EXPOSE 8069 5678
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c", "/etc/odoo/odoo.conf"]
