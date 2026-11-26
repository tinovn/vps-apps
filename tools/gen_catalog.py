#!/usr/bin/env python3
"""Sinh catalog.json từ frontmatter của catalog/<slug>/SKILL.md, và catalog/<slug>/install.sh = lib/install.sh với
catalog/<slug>/app.sh chèn vào chỗ #@APP@ (kèm biến APP_* lấy từ metadata). Với --module, ghi thêm bản chép cho module
HostBill tino_vps_apps: <module>/vps_apps.json và <module>/apps/<slug>/install.sh.

Chạy:  python3 -I tools/gen_catalog.py                    (ghi)
       python3 -I tools/gen_catalog.py --check            (thoát 1 nếu tệp nào lệch)
       python3 -I tools/gen_catalog.py --module <thư mục includes/modules/Other/tino_vps_apps> [--check]

Trong app.sh, dòng "#@use <slug>" được thay bằng app.sh của ứng dụng đó (vd. woocommerce dùng lại wordpress).

Không dùng PyYAML: frontmatter chỉ được dùng tập con YAML dưới đây, ngoài tập này là lỗi:
  khoá: giá trị            (cấp 0)
  metadata:                (cấp 0, mở mapping con)
    khoá: giá trị          (đúng 2 dấu cách)
Giá trị: chuỗi trần, chuỗi trong "..." hoặc '...', số nguyên.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CATALOG_DIR = os.path.join(ROOT, 'catalog')
CATALOG_JSON = os.path.join(ROOT, 'catalog.json')
LIB = os.path.join(ROOT, 'lib', 'install.sh')
MODULE_MARK = 'class.tino_vps_apps.php'  # --module chỉ nhận thư mục có tệp này: không ghi nhầm chỗ khác

# Tập nhóm đóng. Thêm nhóm = sửa ở đây (và trang danh mục), không nhận nhóm lạ từ SKILL.md.
CATEGORIES = {
    'ai': 'AI & Agent',
    'automation': 'Tự động hoá',
    'web': 'Website & bán hàng',
    'team': 'Làm việc nhóm',
    'dev': 'Lập trình & DevOps',
    'data': 'Dữ liệu & backend',
    'media': 'Ảnh, nhạc & phim',
    'monitoring': 'Giám sát',
}

SLUG_RE = re.compile(r'^[a-z0-9][a-z0-9-]{0,63}$')
KEY_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_-]*$')
INT_RE = re.compile(r'^-?[0-9]+$')


class CatalogError(ValueError):
    pass


def _scalar(raw, where):
    v = raw.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in '"\'':
        return v[1:-1]
    if ' #' in v or v.startswith(('[', '{', '|', '>', '&', '*', '!')):
        raise CatalogError(f'{where}: giá trị "{v}" nằm ngoài tập YAML được hỗ trợ, hãy đặt trong "..."')
    if INT_RE.match(v):
        return int(v)
    return v


def parse_frontmatter(text, where='SKILL.md'):
    """Trả (frontmatter dict, thân skill)."""
    if not text.startswith('---\n'):
        raise CatalogError(f'{where}: thiếu dòng --- mở frontmatter')
    end = text.find('\n---\n', 3)
    if end < 0:
        raise CatalogError(f'{where}: thiếu dòng --- đóng frontmatter')
    data, cur = {}, None
    for n, line in enumerate(text[4:end].split('\n'), 2):
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if '\t' in line:
            raise CatalogError(f'{where} dòng {n}: không dùng tab')
        indent = len(line) - len(line.lstrip(' '))
        key, sep, val = line.strip().partition(':')
        if not sep or not KEY_RE.match(key):
            raise CatalogError(f'{where} dòng {n}: cần dạng "khoá: giá trị"')
        if indent == 0:
            if key in data:
                raise CatalogError(f'{where} dòng {n}: khoá {key} lặp lại')
            if val.strip() == '':
                data[key] = cur = {}
            else:
                data[key] = _scalar(val, f'{where} dòng {n}')
                cur = None
        elif indent == 2 and cur is not None:
            if key in cur:
                raise CatalogError(f'{where} dòng {n}: khoá {key} lặp lại')
            cur[key] = _scalar(val, f'{where} dòng {n}')
        else:
            raise CatalogError(f'{where} dòng {n}: thụt lề {indent} không hợp lệ')
    return data, text[end + 5:]


def _need_str(meta, key, where, pattern=None, max_len=255):
    v = meta.get(key)
    if not isinstance(v, str) or not v.strip():
        raise CatalogError(f'{where}: metadata.{key} phải là chuỗi khác rỗng')
    if len(v) > max_len or (pattern and not re.match(pattern, v)):
        raise CatalogError(f'{where}: metadata.{key} = {v!r} không hợp lệ')
    return v


def _need_int(meta, key, where, lo, hi):
    v = meta.get(key)
    if not isinstance(v, int) or isinstance(v, bool) or not lo <= v <= hi:
        raise CatalogError(f'{where}: metadata.{key} phải là số nguyên trong [{lo}, {hi}]')
    return v


def validate(slug, fm, where):
    """Kiểm frontmatter, trả dòng app cho catalog.json."""
    if not SLUG_RE.match(slug):
        raise CatalogError(f'{where}: tên thư mục "{slug}" không phải slug hợp lệ')
    if fm.get('name') != 'install-app':
        raise CatalogError(f'{where}: name phải là install-app')
    if not isinstance(fm.get('description'), str) or not fm['description'].strip():
        raise CatalogError(f'{where}: thiếu description')
    meta = fm.get('metadata')
    if not isinstance(meta, dict):
        raise CatalogError(f'{where}: thiếu khối metadata')
    category = _need_str(meta, 'category', where)
    if category not in CATEGORIES:
        raise CatalogError(f'{where}: nhóm "{category}" không có trong tập {sorted(CATEGORIES)}')
    if meta.get('os') != 'ubuntu-24.04':
        raise CatalogError(f'{where}: metadata.os chỉ nhận ubuntu-24.04')
    return {
        'slug': slug,
        'title': _need_str(meta, 'title', where),
        'repo': _need_str(meta, 'repo', where, r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'),
        # app_ref của bảng job là VARCHAR(64); ref là tag hoặc SHA, không có khoảng trắng
        'ref': _need_str(meta, 'ref', where, r'^[A-Za-z0-9._/-]+$', 64),
        'category': category,
        'summary': _need_str(meta, 'summary_vi', where, max_len=300),
        'min_cpu': _need_int(meta, 'min_cpu', where, 1, 64),
        'min_ram_mb': _need_int(meta, 'min_ram_mb', where, 256, 262144),
        'min_disk_gb': _need_int(meta, 'min_disk_gb', where, 1, 4096),
        'port': _need_int(meta, 'port', where, 1, 65535),
        'healthcheck': _need_str(meta, 'healthcheck', where, r'^/[A-Za-z0-9._~/?=&%-]*$'),
        'license': _need_str(meta, 'license', where, max_len=64),
    }


def load_skill(catalog_dir, slug):
    """Đọc và kiểm catalog/<slug>/SKILL.md. Trả (app, thân skill, toàn văn)."""
    path = os.path.join(catalog_dir, slug, 'SKILL.md')
    with open(path, encoding='utf-8') as f:
        text = f.read()
    fm, body = parse_frontmatter(text, path)
    return validate(slug, fm, path), body, text


def build_catalog(catalog_dir):
    apps = []
    for slug in sorted(os.listdir(catalog_dir)):
        if os.path.isdir(os.path.join(catalog_dir, slug)):
            apps.append(load_skill(catalog_dir, slug)[0])
    if not apps:
        raise CatalogError(f'{catalog_dir}: không có ứng dụng nào')
    return {'categories': CATEGORIES, 'apps': apps}


def render(catalog):
    return json.dumps(catalog, ensure_ascii=False, indent=2) + '\n'


def _sh(v):
    return "'" + str(v).replace("'", "'\\''") + "'"


def build_script(catalog_dir, app, lib_text, seen=()):
    """install.sh của một ứng dụng (None nếu chưa có app.sh: install.sh viết tay)."""
    path = os.path.join(catalog_dir, app['slug'], 'app.sh')
    if not os.path.isfile(path):
        return None
    with open(path, encoding='utf-8') as f:
        body = f.read()

    def use(m):
        other = m.group(1)
        if other in seen or other == app['slug']:
            raise CatalogError(f'{path}: #@use {other} lặp vòng')
        with open(os.path.join(catalog_dir, other, 'app.sh'), encoding='utf-8') as f:
            return re.sub(r'(?m)^#@use ([a-z0-9-]+)$', use, f.read())
    body = re.sub(r'(?m)^#@use ([a-z0-9-]+)$', use, body)
    if not re.search(r'(?m)^app_files\(\) \{', body) or not re.search(r'(?m)^APP_VERSION=', body):
        raise CatalogError(f'{path}: phải đặt APP_VERSION= và định nghĩa app_files() {{')
    head = ''.join(f'  {k}={_sh(app[v])}\n' for k, v in (
        ('APP_SLUG', 'slug'), ('APP_TITLE', 'title'), ('APP_REPO', 'repo'), ('APP_REF', 'ref'), ('APP_PORT', 'port'),
        ('APP_HEALTH', 'healthcheck'), ('MIN_CPU', 'min_cpu'), ('MIN_RAM_MB', 'min_ram_mb'), ('MIN_DISK_GB', 'min_disk_gb')))
    if lib_text.count('#@APP@\n') != 1:
        raise CatalogError(f'{LIB}: cần đúng một dòng #@APP@')
    text = lib_text.replace('@TITLE@', app['title']).replace('@SLUG@', app['slug'])
    head = f'# shellcheck disable=SC2034  # metadata của danh mục; không phải ứng dụng nào cũng dùng hết\n{{\n{head}}}\n'
    return text.replace('#@APP@\n', f'# --- phần riêng: catalog/{app["slug"]}/app.sh ---\n{head}{body.rstrip()}\n# --- hết phần riêng ---\n')


def outputs(catalog_dir=None, module_dir=None):
    """{đường dẫn: nội dung} của mọi tệp sinh ra; có module_dir thì thêm bản chép cho module HostBill."""
    catalog_dir = catalog_dir or CATALOG_DIR
    cat = build_catalog(catalog_dir)
    with open(LIB, encoding='utf-8') as f:
        lib_text = f.read()
    out = {CATALOG_JSON: render(cat)}
    if module_dir:
        out[os.path.join(module_dir, 'vps_apps.json')] = render(cat)
    for app in cat['apps']:
        script = build_script(catalog_dir, app, lib_text)
        if script is None:
            with open(os.path.join(catalog_dir, app['slug'], 'install.sh'), encoding='utf-8') as f:
                script = f.read()
        else:
            out[os.path.join(catalog_dir, app['slug'], 'install.sh')] = script
        if module_dir:
            out[os.path.join(module_dir, 'apps', app['slug'], 'install.sh')] = script
    return out


def extra_module_apps(module_dir, catalog_dir=None):
    """apps/<slug> của module không còn trong danh mục: bỏ app thì script trong module cũng phải đi (không tự xoá)."""
    apps = os.path.join(module_dir, 'apps')
    if not os.path.isdir(apps):
        return []
    slugs = {a['slug'] for a in build_catalog(catalog_dir or CATALOG_DIR)['apps']}
    return sorted(set(os.listdir(apps)) - slugs - {'.DS_Store'})


def _read(path):
    try:
        with open(path, encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return None


def main(argv):
    ap = argparse.ArgumentParser(description='Sinh catalog.json, install.sh và (tuỳ chọn) bản chép cho module HostBill.')
    ap.add_argument('--check', action='store_true', help='chỉ kiểm, thoát 1 nếu tệp nào lệch')
    ap.add_argument('--module', metavar='DIR', help='thư mục module tino_vps_apps (có ' + MODULE_MARK + ')')
    args = ap.parse_args(argv)
    module_dir = os.path.abspath(args.module) if args.module else None
    if module_dir and not os.path.isfile(os.path.join(module_dir, MODULE_MARK)):
        print(f'LỖI: {module_dir} không có {MODULE_MARK}, không phải thư mục module tino_vps_apps', file=sys.stderr)
        return 1
    try:
        out = outputs(module_dir=module_dir)
        extra = extra_module_apps(module_dir) if module_dir else []
    except (CatalogError, OSError) as e:
        print(f'LỖI: {e}', file=sys.stderr)
        return 1
    stale = [p for p, text in out.items() if _read(p) != text]
    for slug in extra:
        print(f'THỪA: {os.path.join(module_dir, "apps", slug)} (app đã bỏ khỏi danh mục, xoá tay)', file=sys.stderr)
    if args.check:
        for p in stale:
            print(f'LỆCH: {os.path.relpath(p)}', file=sys.stderr)
        print('khớp' if not (stale or extra) else 'chạy lại gen_catalog.py', file=sys.stderr)
        return 1 if stale or extra else 0
    for p in stale:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8') as f:
            f.write(out[p])
        print(f'Đã ghi {os.path.relpath(p)}')
    print(f'{len(out)} tệp, ghi {len(stale)}')
    return 1 if extra else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
