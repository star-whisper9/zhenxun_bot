FROM python:3.11-bookworm AS requirements-stage

WORKDIR /tmp

ENV POETRY_HOME="/opt/poetry" PATH="${PATH}:/opt/poetry/bin"
ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/

ENV POETRY_HOME="/opt/poetry" PATH="${PATH}:/opt/poetry/bin"

COPY ./poetry-shell.py /tmp/poetry-shell.py

RUN python /tmp/poetry-shell.py -y && \
  poetry self add poetry-plugin-export

COPY ./pyproject.toml ./poetry.lock* /tmp/

RUN poetry export \
      -f requirements.txt \
      --output requirements.txt \
      --without-hashes \
      --without-urls

FROM python:3.11-bookworm AS build-stage

WORKDIR /wheel

COPY --from=requirements-stage /tmp/requirements.txt /wheel/requirements.txt

# RUN python3 -m pip config set global.index-url https://mirrors.aliyun.com/pypi/simple

RUN pip wheel --wheel-dir=/wheel --no-cache-dir --requirement /wheel/requirements.txt

FROM python:3.11-bookworm AS metadata-stage

WORKDIR /tmp

RUN --mount=type=bind,source=./.git/,target=/tmp/.git/ \
  git describe --tags --exact-match > /tmp/VERSION 2>/dev/null \
  || git rev-parse --short HEAD > /tmp/VERSION \
  && echo "Building version: $(cat /tmp/VERSION)"

FROM python:3.11-slim-bookworm

WORKDIR /app/zhenxun

ENV TZ=Asia/Shanghai PYTHONUNBUFFERED=1
#COPY ./scripts/docker/start.sh /start.sh
#RUN chmod +x /start.sh

EXPOSE 8080

RUN apt update && \
    apt install -y --no-install-recommends \
        curl \
        fontconfig \
        fonts-noto-color-emoji \
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
    && apt clean \
    && fc-cache -fv \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖项和应用代码
COPY --from=build-stage /wheel /wheel
COPY . .

RUN pip install --no-cache-dir --no-index --find-links=/wheel -r /wheel/requirements.txt && rm -rf /wheel

RUN playwright install --with-deps chromium \
  && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=metadata-stage /tmp/VERSION /app/VERSION

# VOLUME ["/app/zhenxun/data", "/app/zhenxun/resources", "/app/zhenxun/log"]

CMD ["python", "bot.py"]
