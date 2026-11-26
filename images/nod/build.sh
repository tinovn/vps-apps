#!/usr/bin/env bash
# Build 3 image của Nod (https://github.com/n8n-io/nod, Apache-2.0) từ tag chính thức, đẩy ghcr.io/tinovn/nod-*.
# n8n không phát hành image Docker; compose self-host của họ tự build 3 image này. Ta build bằng chính Dockerfile của họ,
# chỉ thêm LICENSE + NOTICE (Apache-2.0 §4) và nhãn OCI. In "image:tag@digest" để ghim trong catalog/nod/app.sh.
#
# Chạy:  images/nod/build.sh nod-v0.9.7     (cần docker buildx, đã docker login ghcr.io; REGISTRY đổi được)
set -euo pipefail
ref=${1:?cần tag Nod, vd. nod-v0.9.7}
[[ $ref =~ ^nod-v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "tag không hợp lệ: $ref" >&2; exit 2; }
ver=${ref#nod-v}
reg=${REGISTRY:-ghcr.io/tinovn}
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT

git clone -q --depth 1 --branch "$ref" https://github.com/n8n-io/nod.git "$src"
rev=$(git -C "$src" rev-parse HEAD)
# .dockerignore của họ là danh sách cho phép: mở thêm LICENSE, NOTICE rồi chép vào tầng cuối của cả 3 image.
printf '!LICENSE\n!NOTICE\n' >> "$src/.dockerignore"
for f in deployment/self-host/Dockerfile Dockerfile.browser Dockerfile.workspace; do
  printf '\nCOPY LICENSE NOTICE /usr/share/doc/nod/\n' >> "$src/$f"
done

build() { # build <tên image> <Dockerfile>
  docker buildx build --platform linux/amd64 --provenance=false --pull \
    --label org.opencontainers.image.source=https://github.com/tinovn/vps-apps \
    --label org.opencontainers.image.url=https://github.com/n8n-io/nod \
    --label org.opencontainers.image.revision="$rev" \
    --label org.opencontainers.image.version="$ver" \
    --label org.opencontainers.image.licenses=Apache-2.0 \
    -f "$src/$2" -t "$reg/$1:$ver" --push "$src"
}
build nod-server deployment/self-host/Dockerfile
build nod-browser Dockerfile.browser
build nod-workspace Dockerfile.workspace

echo "Nod $ver, commit $rev:"
for n in nod-server nod-browser nod-workspace; do
  echo "$reg/$n:$ver@$(docker buildx imagetools inspect "$reg/$n:$ver" --format '{{json .Manifest}}' | jq -r .digest)"
done
