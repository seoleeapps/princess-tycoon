"""런타임 코드가 직접 참조하는 에셋을 export 제외 필터가 지우지 않는지 검사한다."""
import configparser
import fnmatch
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]/'godot'
config=configparser.ConfigParser(interpolation=None)
config.read(ROOT/'export_presets.cfg',encoding='utf-8')
paths=set()
for script in (ROOT/'src').rglob('*.gd'):
    paths.update(re.findall(r'res://assets/[^"\s]+\.(?:png|json|ttf|otf|tres)',script.read_text()))
failures=[]
presets=0
for section in config.sections():
    if not re.fullmatch(r'preset\.\d+',section):continue
    presets+=1
    filters=config.get(section,'exclude_filter',fallback='""').strip('"').split(',')
    for resource in paths:
        relative=resource.removeprefix('res://')
        if not (ROOT/relative).is_file():
            failures.append(f'{section}: missing source {resource}')
        elif any(fnmatch.fnmatchcase(relative.lower(),pattern.strip().lower()) for pattern in filters if pattern.strip()):
            failures.append(f'{section}: excludes runtime resource {resource}')
for failure in failures:print('[FAIL]',failure)
print(f'Export resource references: {len(paths)} assets, {presets} presets, {len(failures)} failures')
raise SystemExit(1 if failures else 0)
