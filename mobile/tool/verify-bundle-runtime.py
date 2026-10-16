"""Verify compact Play bundle preserves runtime bytes and production ad IDs."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path

raw_path, compact_path = map(Path, sys.argv[1:3])
ad_ids = (
    b'ca-app-pub-9061518700917881/4239172993',
    b'ca-app-pub-9061518700917881/1696855854',
    b'ca-app-pub-9061518700917881/4798496062',
)
with zipfile.ZipFile(raw_path) as raw, zipfile.ZipFile(compact_path) as compact:
    runtime = lambda archive: {
        name for name in archive.namelist()
        if not name.endswith('/') and not name.startswith(('META-INF/', 'BUNDLE-METADATA/'))
    }
    names = runtime(raw)
    assert names == runtime(compact), 'Runtime entries differ'
    for name in sorted(names):
        assert hashlib.sha256(raw.read(name)).digest() == hashlib.sha256(compact.read(name)).digest(), name
    libraries = sorted(name for name in names if name.endswith('/libapp.so'))
    assert len(libraries) == 3, libraries
    for name in libraries:
        data = compact.read(name)
        for ad_id in ad_ids:
            assert ad_id in data, f'Missing production ad ID in {name}'
    report = {
        'runtime_entries_identical': len(names),
        'production_ad_ids_verified_in': libraries,
        'bytes': compact_path.stat().st_size,
        'sha256': hashlib.file_digest(compact_path.open('rb'), 'sha256').hexdigest(),
    }
    print(json.dumps(report, indent=2))
