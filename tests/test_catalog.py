"""Danh mục: frontmatter SKILL.md và catalog.json.
Chạy: python3 -I -m unittest discover -s tests -v"""
import os
import re
import shutil
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import gen_catalog as gc  # noqa: E402

SKILL = os.path.join(ROOT, 'catalog', 'uptime-kuma', 'SKILL.md')
with open(SKILL, encoding='utf-8') as _f:
    SKILL_TEXT = _f.read()


class TempCatalog:
    def __init__(self, apps):
        self.apps = apps

    def __enter__(self):
        self.dir = tempfile.mkdtemp()
        for slug, text in self.apps.items():
            os.makedirs(os.path.join(self.dir, slug))
            with open(os.path.join(self.dir, slug, 'SKILL.md'), 'w', encoding='utf-8') as f:
                f.write(text)
        return self.dir

    def __exit__(self, *a):
        shutil.rmtree(self.dir)


class CatalogTest(unittest.TestCase):
    def test_uptime_kuma_skill(self):
        app, body, _ = gc.load_skill(os.path.join(ROOT, 'catalog'), 'uptime-kuma')
        self.assertEqual(app['repo'], 'louislam/uptime-kuma')
        self.assertRegex(app['ref'], r'^[0-9a-f]{40}$')
        self.assertEqual((app['category'], app['port'], app['healthcheck']), ('monitoring', 3001, '/'))
        self.assertIsInstance(app['min_ram_mb'], int)
        for section in ('## OBJECTIVE', '## DONE WHEN', '/root/tino-app.txt'):
            self.assertIn(section, body)
        # tạo admin (bước 6) phải đứng trước khi mở HTTPS qua Caddy (bước 7)
        self.assertLess(body.index('### 6. Tạo tài khoản quản trị'), body.index('### 7. Mở HTTPS'))

    def test_committed_outputs_in_sync(self):
        # catalog.json và catalog/<slug>/install.sh
        out = gc.outputs()
        self.assertIn(gc.CATALOG_JSON, out)
        for path, text in out.items():
            with self.subTest(path=os.path.relpath(path, ROOT)), open(path, encoding='utf-8') as f:
                self.assertEqual(f.read(), text, 'lệch: chạy tools/gen_catalog.py')

    def test_module_copy(self):
        # --module: bản chép cho module HostBill trùng từng byte bản trong repo; app thừa bị báo, không tự xoá
        with tempfile.TemporaryDirectory() as mod:
            open(os.path.join(mod, gc.MODULE_MARK), 'w').close()
            self.assertEqual(gc.main(['--module', mod]), 0)
            slugs = [a['slug'] for a in gc.build_catalog(gc.CATALOG_DIR)['apps']]
            for slug in slugs:
                with open(os.path.join(mod, 'apps', slug, 'install.sh'), encoding='utf-8') as a, \
                        open(os.path.join(ROOT, 'catalog', slug, 'install.sh'), encoding='utf-8') as b:
                    self.assertEqual(a.read(), b.read(), slug)
            self.assertEqual(gc.main(['--module', mod, '--check']), 0)
            os.makedirs(os.path.join(mod, 'apps', 'da-bo'))
            self.assertEqual(gc.extra_module_apps(mod), ['da-bo'])
            self.assertEqual(gc.main(['--module', mod, '--check']), 1)
            self.assertTrue(os.path.isdir(os.path.join(mod, 'apps', 'da-bo')))
        with tempfile.TemporaryDirectory() as other:  # thư mục không phải module: không ghi gì
            self.assertEqual(gc.main(['--module', other]), 1)
            self.assertEqual(os.listdir(other), [])

    def test_every_app_uses_shared_lib(self):
        # mọi ứng dụng viết phần riêng app.sh; install.sh viết tay (không qua lib/install.sh) không còn được nhận
        for app in gc.build_catalog(gc.CATALOG_DIR)['apps']:
            with self.subTest(slug=app['slug']):
                self.assertTrue(os.path.isfile(os.path.join(gc.CATALOG_DIR, app['slug'], 'app.sh')))

    def test_build_script(self):
        app = {'slug': 'demo', 'title': "O'App", 'repo': 'o/a', 'ref': 'v1', 'port': 8080, 'healthcheck': '/',
               'min_cpu': 1, 'min_ram_mb': 1024, 'min_disk_gb': 10}
        lib = 'đầu @TITLE@ @SLUG@\n#@APP@\ncuối\n'
        with TempCatalog({'demo': SKILL_TEXT, 'base': SKILL_TEXT}) as d:
            def write(slug, text):
                with open(os.path.join(d, slug, 'app.sh'), 'w', encoding='utf-8') as f:
                    f.write(text)
            write('base', 'APP_VERSION=1\napp_files() {\n  :\n}\n')
            write('demo', '#@use base\nAPP_VERSION=2\n')
            out = gc.build_script(d, app, lib)
            self.assertTrue(out.startswith("đầu O'App demo\n") and out.endswith('cuối\n'))
            self.assertIn("  APP_TITLE='O'\\''App'\n", out)
            self.assertLess(out.index('APP_VERSION=1'), out.index('APP_VERSION=2'))  # app.sh đè được khuôn #@use
            write('demo', 'app_files() {\n  :\n}\n')
            with self.assertRaises(gc.CatalogError):
                gc.build_script(d, app, lib)  # thiếu APP_VERSION
            write('demo', '#@use demo\nAPP_VERSION=2\napp_files() {\n  :\n}\n')
            with self.assertRaises(gc.CatalogError):
                gc.build_script(d, app, lib)  # #@use chính nó
            write('demo', 'APP_VERSION=2\napp_files() {\n  :\n}\n')
            with self.assertRaises(gc.CatalogError):
                gc.build_script(d, app, 'không có chỗ chèn\n')

    def test_apps_sorted_and_fields(self):
        other = SKILL_TEXT.replace('title: Uptime Kuma', 'title: A App')
        with TempCatalog({'zeta': SKILL_TEXT, 'alpha': other}) as d:
            cat = gc.build_catalog(d)
        self.assertEqual([a['slug'] for a in cat['apps']], ['alpha', 'zeta'])
        self.assertEqual(list(cat['apps'][0]), ['slug', 'title', 'repo', 'ref', 'category', 'summary', 'min_cpu',
                                                'min_ram_mb', 'min_disk_gb', 'port', 'healthcheck', 'license'])
        self.assertEqual(cat['categories'], gc.CATEGORIES)
        self.assertTrue(gc.render(cat).endswith('}\n'))
        self.assertIn('Giám sát', gc.render(cat))  # ensure_ascii=False

    def test_every_metadata_field_is_required(self):
        fm, _ = gc.parse_frontmatter(SKILL_TEXT)
        keys = list(fm['metadata'])
        self.assertEqual(len(keys), 12)
        for key in keys:  # quét toàn bộ trường metadata của skill thật
            text = re.sub(rf'(?m)^  {key}:.*\n', '', SKILL_TEXT)
            with self.subTest(key=key), TempCatalog({'uptime-kuma': text}) as d:
                with self.assertRaises(gc.CatalogError):
                    gc.build_catalog(d)

    def test_bad_fields_fail_loudly(self):
        cases = {
            'nhóm lạ': ('category: monitoring', 'category: games'),
            'cổng không phải số': ('port: 3001', 'port: abc'),
            'cổng ngoài khoảng': ('port: 3001', 'port: 70000'),
            'name sai': ('name: install-app', 'name: uptime'),
            'os khác': ('os: ubuntu-24.04', 'os: debian-12'),
            'ref có khoảng trắng': ('ref: df601c58d9205562f34cfe5ef35264b341019d19', 'ref: "v 1"'),
            'healthcheck không bắt đầu bằng /': ('healthcheck: /', 'healthcheck: health'),
            'tab': ('  port: 3001', '\tport: 3001'),
            'khoá lặp': ('  port: 3001', '  port: 3001\n  port: 3002'),
            'thụt lề lạ': ('  port: 3001', '    port: 3001'),
            'chú thích trong giá trị trần': ('title: Uptime Kuma', 'title: Uptime # Kuma'),
            'thiếu frontmatter': ('---\nname', 'name'),
        }
        for name, (old, new) in cases.items():
            self.assertIn(old, SKILL_TEXT, name)
            with self.subTest(case=name), TempCatalog({'uptime-kuma': SKILL_TEXT.replace(old, new, 1)}) as d:
                with self.assertRaises(gc.CatalogError):
                    gc.build_catalog(d)

    def test_bad_slug_dir(self):
        with TempCatalog({'Uptime_Kuma': SKILL_TEXT}) as d:
            with self.assertRaises(gc.CatalogError):
                gc.build_catalog(d)

    def test_scalar_types(self):
        fm, body = gc.parse_frontmatter('---\na: "1"\nb: 2\nc: x: y\nm:\n  k: \'q\'\n---\nthân\n')
        self.assertEqual(fm, {'a': '1', 'b': 2, 'c': 'x: y', 'm': {'k': 'q'}})
        self.assertEqual(body, 'thân\n')


class InstallScriptTest(unittest.TestCase):
    """catalog/<slug>/install.sh: HostBill ghi lên VPS qua guest agent và chạy bằng root."""

    def scripts(self):
        d = os.path.join(ROOT, 'catalog')
        out = [os.path.join(d, s, 'install.sh') for s in sorted(os.listdir(d)) if os.path.isfile(os.path.join(d, s, 'install.sh'))]
        self.assertTrue(out, 'chưa ứng dụng nào có install.sh')
        return out

    def test_static(self):
        import subprocess
        sc = shutil.which('shellcheck')
        for path in self.scripts():
            with self.subTest(path=os.path.relpath(path, ROOT)):
                with open(path, encoding='utf-8') as f:
                    text = f.read()
                self.assertEqual(subprocess.run(['bash', '-n', path]).returncode, 0, 'bash -n')
                if sc:
                    r = subprocess.run([sc, '-S', 'warning', path], capture_output=True, text=True)
                    self.assertEqual(r.returncode, 0, r.stdout)
                self.assertIn('set -euo pipefail', text)
                self.assertIn("trap 'exit 1' ERR", text, 'không có trap thì lệnh nào thoát 3 cũng bị coi là VPS không đáp ứng')
                self.assertIn('##STEP', text)
                self.assertIn('exit 3', text, 'cần đường dừng hẳn (VPS không đáp ứng) để worker không gọi AI vô ích')
                self.assertNotRegex(text, r'(?m)^\s*set -[a-z]*x', 'set -x in mật khẩu ra log')
                # cổng publish của compose phải gắn 127.0.0.1 (lib còn kiểm lúc chạy bằng docker ps)
                for n, line in enumerate(text.splitlines(), 1):
                    if re.match(r'''^\s*-\s*["']?(\$\{?\w+\}?|\d+|0\.0\.0\.0):\S*\d["']?\s*$''', line):
                        self.fail(f'dòng {n} publish cổng không gắn 127.0.0.1: {line.strip()}')
                # mật khẩu chỉ được ghi vào tệp: dòng printf/echo nhắc tới password phải chuyển hướng vào tệp
                for n, line in enumerate(text.splitlines(), 1):
                    if re.search(r'\b(printf|echo)\b', line) and re.search(r'(?i)password|\bPW\b|KUMA_PW', line):
                        self.assertRegex(line, r'>\s*"?\$', f'dòng {n} có thể in mật khẩu: {line.strip()}')


if __name__ == '__main__':
    unittest.main()
