FROM python:3.11-bookworm AS requirements-stage

WORKDIR /tmp

# 合并 pip 配置和 poetry 安装
ENV POETRY_HOME="/opt/poetry" PATH="${PATH}:/opt/poetry/bin"
RUN pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple && \
    pip install --no-cache-dir poetry poetry-plugin-export

COPY ./pyproject.toml ./poetry.lock* /tmp/

RUN poetry export \
      -f requirements.txt \
      --output requirements.txt \
      --without-hashes \
      --without-urls

FROM python:3.11-bookworm AS metadata-stage

WORKDIR /tmp

RUN --mount=type=bind,source=./.git/,target=/tmp/.git/ \
  git describe --tags --exact-match > /tmp/VERSION 2>/dev/null \
  || git rev-parse --short HEAD > /tmp/VERSION \
  && echo "Building version: $(cat /tmp/VERSION)"

FROM python:3.11-slim-bookworm

WORKDIR /app/zhenxun

# 设置 pip 镜像源（提前设置，避免后续重复）
RUN pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple

# 使用国内源加速 apt
RUN rm -f /etc/apt/sources.list.d/debian.sources
COPY ./dockerfiles/debian.sources /etc/apt/sources.list.d/debian.sources

ENV TZ=Asia/Shanghai PYTHONUNBUFFERED=1

EXPOSE 8080

RUN apt update && \
    apt install -y --no-install-recommends \
        fontconfig \
        fonts-noto-color-emoji \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-dejavu-core \
        fonts-liberation \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
        libegl1 \
        libgl1 \
        libgl1-mesa-glx \
        libglib2.0-bin \
        libgomp1 \
        libxcomposite1 \
        libxdamage1 \
        libxi6 \
        libxtst6 \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libdrm2 \
        libgbm1 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libxrandr2 \
        libasound2 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libxss1 \
        libgconf-2-4 \
        libxfixes3 \
        libxcursor1 \
        libgtk-3-0 \
        libgdk-pixbuf2.0-0 \
        libcairo-gobject2 \
        libdbus-glib-1-2 \
        libatspi2.0-0 \
        libappindicator3-1 \
        libsecret-1-0 \
        xdg-utils \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
    && fc-cache -fv \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 先复制需求文件和版本信息（这些文件变化较少，有利于缓存）
COPY --from=requirements-stage /tmp/requirements.txt /app/zhenxun/requirements.txt
COPY --from=metadata-stage /tmp/VERSION /app/VERSION
COPY ./dockerfiles/fonts/ /usr/share/fonts/truetype/custom/
RUN fc-cache -fv

# 最后复制应用代码和设置权限（这些文件变化较频繁）
COPY . .
RUN chmod +x dockerfiles/docker-requirement.sh

CMD ["bash"]