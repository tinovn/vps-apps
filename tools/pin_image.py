#!/usr/bin/env python3
"""In image kèm digest (index đa kiến trúc) để ghim trong app.sh: name:tag → name:tag@sha256:…

Chạy:  python3 -I services/vps-app-installer/tools/pin_image.py wordpress:6.8.3-php8.3-apache ghcr.io/owner/app:1.2.3
Hỗ trợ Docker Hub, ghcr.io, quay.io (đọc ẩn danh). Thoát 1 nếu image nào không có.
"""
import json
import sys
import urllib.parse
import urllib.request

ACCEPT = ', '.join([
    'application/vnd.oci.image.index.v1+json',
    'application/vnd.docker.distribution.manifest.list.v2+json',
    'application/vnd.docker.distribution.manifest.v2+json',
    'application/vnd.oci.image.manifest.v1+json',
])


def split(ref):
    name, _, tag = ref.rpartition(':') if ':' in ref.split('/')[-1] else (ref, '', 'latest')
    first = name.split('/')[0]
    if '.' in first or ':' in first:
        registry, repo = first, name[len(first) + 1:]
    else:
        registry, repo = 'registry-1.docker.io', name if '/' in name else 'library/' + name
    return registry, repo, tag


def token(registry, repo):
    if registry == 'registry-1.docker.io':
        url = 'https://auth.docker.io/token?' + urllib.parse.urlencode({'service': 'registry.docker.io', 'scope': f'repository:{repo}:pull'})
    elif registry == 'ghcr.io':
        url = 'https://ghcr.io/token?' + urllib.parse.urlencode({'scope': f'repository:{repo}:pull'})
    else:
        return None
    with urllib.request.urlopen(url, timeout=20) as r:
        return json.load(r)['token']


def digest(ref):
    registry, repo, tag = split(ref)
    req = urllib.request.Request(f'https://{registry}/v2/{repo}/manifests/{tag}', method='HEAD', headers={'Accept': ACCEPT})
    t = token(registry, repo)
    if t:
        req.add_header('Authorization', 'Bearer ' + t)
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.headers['Docker-Content-Digest']


def main(argv):
    rc = 0
    for ref in argv:
        try:
            print(f'{ref}@{digest(ref)}')
        except Exception as e:  # noqa: BLE001 — báo từng image, chạy tiếp
            print(f'LỖI {ref}: {e}', file=sys.stderr)
            rc = 1
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
