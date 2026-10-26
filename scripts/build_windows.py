#!/usr/bin/env python3
"""Package the exact official Windows runtime after verifying its published SHA256."""
import argparse, hashlib, json, pathlib, shutil, urllib.request, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
VERSION=json.loads((ROOT/'package.json').read_text())['devDependencies']['electron']
p=argparse.ArgumentParser();p.add_argument('--runtime',type=pathlib.Path);p.add_argument('--checksums',type=pathlib.Path);p.add_argument('--output',type=pathlib.Path,default=ROOT/'dist');args=p.parse_args()
name=f'electron-v{VERSION}-win32-x64.zip';cache=ROOT/'.cache';cache.mkdir(exist_ok=True)
runtime=args.runtime or cache/name;sums=args.checksums or cache/f'electron-{VERSION}-SHASUMS256.txt'
base=f'https://github.com/electron/electron/releases/download/v{VERSION}/'
for target,url in [(runtime,base+name),(sums,base+'SHASUMS256.txt')]:
    if not target.exists():
        print('Downloading',url);urllib.request.urlretrieve(url,target)
expected=next(line.split()[0] for line in sums.read_text().splitlines() if line.split()[-1].lstrip('*')==name)
actual=hashlib.file_digest(runtime.open('rb'),'sha256').hexdigest()
if actual!=expected:raise SystemExit('Runtime SHA256 mismatch; packaging stopped')
out=args.output.resolve();out.mkdir(parents=True,exist_ok=True);folder=out/'QuietReader-3.0.0-Windows-x64'
if folder.exists():shutil.rmtree(folder)
folder.mkdir()
with zipfile.ZipFile(runtime) as archive:
    for item in archive.infolist():
        dest=(folder/item.filename).resolve()
        if not dest.is_relative_to(folder):raise SystemExit('Unsafe archive entry')
    archive.extractall(folder)
(folder/'electron.exe').rename(folder/'QuietReader.exe')
app=folder/'resources/app';app.mkdir(parents=True)
for name in ['src','desktop']:shutil.copytree(ROOT/name,app/name,ignore=shutil.ignore_patterns('body.html'))
for name in ['package.json','LICENSE']:shutil.copy(ROOT/name,app/name)
shutil.copy(ROOT/'docs/USER_GUIDE.md',folder/'使用说明.md')
(folder/'README-先读我.txt').write_text('静读 3.0 · Windows x64 便携版\n\n请完整解压后双击 QuietReader.exe，不要只复制 EXE。\n四套主题位于顶部主题按钮。F11 全屏。Ctrl+Shift+X 在摸鱼版隐藏或恢复正文。\n数据存于 %APPDATA%\\QuietReader。支持 Windows 10/11 x64。\n本包未进行 Windows 实机测试，也没有发布者代码签名；请在测试环境验证后再用于长期阅读。\nElectron 官方运行库已通过 SHA256 校验。\n',encoding='utf-8')
(folder/'Create Desktop Shortcut.cmd').write_text('@echo off\nset "QUIET_READER_DIR=%~dp0"\npowershell.exe -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath(\'Desktop\'),\'Quiet Reader.lnk\')); $s.TargetPath=[IO.Path]::Combine($env:QUIET_READER_DIR,\'QuietReader.exe\'); $s.WorkingDirectory=$env:QUIET_READER_DIR; $s.Save()"\nif errorlevel 1 (echo Could not create shortcut. & pause & exit /b 1)\necho Desktop shortcut created.\npause\n',encoding='ascii')
exe=(folder/'QuietReader.exe').read_bytes()
if not exe.startswith(b'MZ'):raise SystemExit('Missing valid Windows executable')
pe=int.from_bytes(exe[0x3c:0x40],'little')
if exe[pe:pe+4]!=b'PE\0\0' or int.from_bytes(exe[pe+4:pe+6],'little')!=0x8664:raise SystemExit('Not an x64 Windows PE')
zip_path=pathlib.Path(shutil.make_archive(str(folder),'zip',root_dir=out,base_dir=folder.name))
print('Runtime and x64 PE validated. Windows execution remains untested on this host.')
print(zip_path)
