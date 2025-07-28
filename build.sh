#!/bin/bash

# 检查是否提供版本号参数
if [ -z "$1" ]; then
    echo "使用方法: $0 <版本号>"
    echo "示例: $0 0.0.5"
    exit 1
fi

VERSION=$1

# 平台选择
PLATFORMS=("linux/amd64" "linux/arm64")
PS3="请选择要构建的目标平台: "
select PLATFORM in "${PLATFORMS[@]}"; do
    if [[ -n "$PLATFORM" ]]; then
        echo "已选择平台: $PLATFORM"
        break
    else
        echo "无效选择，请重新输入。"
    fi
done

# 根据版本和平台生成名称
IMAGE_NAME="zhenxun-bot:self-${VERSION}"
ARCHIVE_NAME="zhenxun-bot-self-${VERSION}-${PLATFORM//\//-}.tar"

echo "开始构建镜像: ${IMAGE_NAME} for ${PLATFORM}"

# 构建 Docker 镜像
if docker buildx build --platform "${PLATFORM}" -t "${IMAGE_NAME}" --load .; then
    echo "镜像构建成功: ${IMAGE_NAME}"
else
    echo "镜像构建失败"
    exit 1
fi

# 导出镜像
echo "开始导出镜像: ${ARCHIVE_NAME}"
if docker save -o "${ARCHIVE_NAME}" "${IMAGE_NAME}"; then
    echo "镜像导出成功: ${ARCHIVE_NAME}"
    echo "文件大小: $(du -h ${ARCHIVE_NAME} | cut -f1)"
else
    echo "镜像导出失败"
    exit 1
fi

echo "构建完成！"