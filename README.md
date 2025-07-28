<!-- markdownlint-disable MD033 MD041 -->
<div align=center>

<img width="250" height="312" src=./docs_image/tt.jpg alt="zhenxun_bot"/>

</div>

<div align=center>
<a href="./LICENSE">
    <img src="https://img.shields.io/badge/license-AGPL3.0-FE7D37" alt="license">
</a>
<a href="https://www.python.org">
    <img src="https://img.shields.io/badge/Python-3.10%20%7C%203.11%20%7C%203.12-blue" alt="python">
</a>
<a href="https://nonebot.dev/">
    <img src="https://img.shields.io/badge/nonebot-v2.1.3-EA5252" alt="nonebot">
</a>
</div>

<div align=center>

# 绪山真寻 Bot (Docker Fork)

这是一个 [HibiKier/zhenxun_bot](https://github.com/HibiKier/zhenxun_bot) 的 Fork 仓库。

</div>

## 📖 关于此 Fork

本仓库是原版真寻的一个 Fork。创建此 Fork 的主要目的是为了修复和改进原项目中 Docker 化的实现。**但很可惜，由于原始实现与插件化的结构，很多问题无法完全解决。**

### 简易的 Quick-Start

#### 构建阶段

```bash
git clone https://github.com/star-whisper9/zhenxun_bot.git
cd zhenxun_bot
docker build -t zhenxun_bot .
```

#### 准备阶段

我们给出了一个基础的示例供您参考，找到 `dockerfiles/docker-compose.yml` 文件并根据需要进行修改。下面的代码可能不会持续更新，您应以 `dockerfiles/docker-compose.yml` 文件为准。

```yaml
services:
  zhenxun-bot:
    image: zhenxun-bot:self-0.0.7
    container_name: zhenxun-bot
    # ports:
    #   - "8080:8080"
    depends_on:
      - db
      - napcat
    environment:
      - http_proxy=http://172.0.0.1:10809
      - https_proxy=http://172.0.0.1:10809
    volumes:
      - ./.env.dev:/app/zhenxun/.env.dev:ro
      - ./zhenxun/data:/app/zhenxun/data
      - ./zhenxun/resources:/app/zhenxun/resources
      - ./zhenxun/plugins:/app/zhenxun/zhenxun/plugins
      - ./zhenxun/log:/app/zhenxun/log
      - ./zhenxun/python_site_packages:/usr/local/lib/python3.11/site-packages
      - ./zhenxun/root-home:/root
    restart:
      always
      #command: bash /app/zhenxun/dockerfiles/docker-requirement.sh && bash
    command: python /app/zhenxun/bot.py

  db:
    image: postgres:15
    container_name: zhenxun-db
    # ports:
    #   - "5432:5432"
    environment:
      POSTGRES_DB: zhenxun
      POSTGRES_USER: zhenxun
      POSTGRES_PASSWORD: zhenxun_bot
    volumes:
      - ./pg_data:/var/lib/postgresql/data
    restart: always

  napcat:
    image: mlikiowa/napcat-docker:latest
    container_name: napcat
    environment:
      - NAPCAT_UID=0
      - NAPCAT_GID=0
    # ports:
    #   - "6099:6099"
    #   - "3000:3000"
    #   - "3001:3001"
    volumes:
      - ./napcat/qq:/app/.config/QQ
      - ./napcat/config:/app/napcat/config
    restart: always
    mac_address: F4:1A:9C:E6:46:39

  nginx:
    image: nginx:alpine
    container_name: zhenxun-nginx
    depends_on:
      - zhenxun-bot
      - napcat
    ports:
      - "8080:8080"
      - "6099:6099"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
```

解析：

此 compose 定义了四个服务：

- `zhenxun-bot`: Bot 服务。
- `db`: 数据存储选用 PostgreSQL。
- `napcat`: NapCat 服务化。
- `nginx`: Nginx 反向代理暴露端口。

其中，我们建议您至少映射示例中定义了的目录，以确保 Bot 的正常运行。

#### 启动阶段

我们建议将 compose 部署目录和源码分离管理。此示例假设你使用了示例的 compose。

```bash
# 从您克隆的仓库中将 .env.dev 文件复制到部署目录并按照真寻官方文档修改
cp .env.dev ./<your_deploy_directory>/
# 从源码中复制 dockerfiles/docker-compose.yml dockerfiles/nginx.conf 到部署目录
cp dockerfiles/docker-compose.yml ./<your_deploy_directory>/
cp dockerfiles/nginx.conf ./<your_deploy_directory>/
# 首次启动
# 在 compose 中，bot 服务的 command 选用带有 `docker-requirement.sh` 的命令
docker compose up
# 看到所有依赖正确安装之后，Ctrl C 停止容器
# 修改 compose 中 bot 服务的 command 为 `python /app/zhenxun/bot.py`
docker compose up -d
```

#### 配置

与原版配置基本无异，自行寻找相关配置文件（持久化目录中）。

#### 插件安装

所有插件必须手动安装到您映射的 `./zhenxun/plugins` 目录中。并且，为每个插件准备好 `requirements.txt` 文件。

复制插件的文件之后，进入容器中执行 `pip install` 安装插件的依赖，随后重启容器。

#### 访问 WebUI

如果你使用的是示例 compose，你应可以从 `http://ip:8080` 访问 WebUI。从`http://ip:6099/webui` 访问 NapCat UI。

#### 更新

如果要更新 Bot 版本：

1. 拉取最新源码
2. 重新构建镜像
3. (可选) 删除原本的 pypi 包映射目录
4. 停止容器。按照首次启动的步骤，重装所有依赖（包括插件依赖，_真寻使用的很多依赖版本限定很低，很多插件会出问题_）
5. 重启容器
6. (可选) **这是一个重要的步骤**。我们建议你在更新时，删除 `zhenxun/data` `zhenxun/resources` 两个持久化目录，重建它们（记得先保存你的 `data/config.yaml`）并重新进行插件配置。因为已有的 yaml 配置和资源是不会被更新的，如果更新存在破坏性改动，可能会导致 Bot 无法正常工作。

### 已知问题

- **插件商店无法使用**: 由于原项目的插件商店使用 `poetry` 实现，而 Docker 环境可能存在兼容性问题，无论是原始 Docker 实现，还是我修改的版本，均选用 `pip` 进行依赖管理，因此插件商店无法正常工作。
- **依赖管理依靠手动操作**: 由于插件化的实现，依赖管理需要将 pypi 包目录持久化，这意味着无法在镜像中直接包含真寻的依赖（将会被卷覆写），因此真寻本体依赖需要手动安装（首次创建容器时），且插件依赖也需要手动安装。
- **卷映射问题**: 由于插件化的实现，我们基本不可能将所有使用到的目录都默认映射，因此需要手动为每个插件添加所需的卷映射。**并不是只映射真寻目录就够的！**

### 核心原则

- **功能无更改**：此 Fork **不会**对真寻 Bot 的任何核心功能进行修改。所有功能、插件和用法均与上游仓库保持一致。
- **手动同步**：我会尽力手动与 `HibiKier/zhenxun_bot` 源仓库保持同步。但请注意，由于是手动操作，版本更新可能存在一定的延迟。
- **专注 Docker**：所有代码级别的改动都将围绕 Docker 部署的优化和问题修复进行。

## 🔗 原始仓库

有关真寻 Bot 的完整功能介绍、详细文档、社区支持和贡献指南，请访问原始仓库：

➡️ **[HibiKier/zhenxun_bot](https://github.com/HibiKier/zhenxun_bot)**

<div align=center>
