#!/usr/bin/env python3
"""Package an existing signed app with a first-open guide; never changes security settings."""
import argparse,pathlib,shutil,subprocess,tempfile,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--app',type=pathlib.Path,default=ROOT/'dist'/'静读.app');p.add_argument('--output',type=pathlib.Path,default=ROOT/'dist');args=p.parse_args()
app=args.app.resolve();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
if not (app/'Contents/MacOS/QuietReader').is_file():raise SystemExit('Build the Mac app first')
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
helpers=ROOT/'packaging/macos'
with tempfile.TemporaryDirectory(prefix='quiet-reader-package-') as tmp:
 folder=pathlib.Path(tmp)/'静读-开始使用';folder.mkdir()
 shutil.copytree(app,folder/'静读.app')
 for f in helpers.iterdir():
  if f.is_file():shutil.copy(f,folder/f.name)
 archive=out/'QuietReader-3.0.0-macOS-arm64-guided.zip'
 subprocess.run(['ditto','-c','-k','--sequesterRsrc','--keepParent',str(folder),str(archive)],check=True)
with zipfile.ZipFile(out/'QuietReader-Mac-First-Open.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
 for f in helpers.iterdir():
  if f.is_file():z.write(f,'静读-首次打开引导/'+f.name)
print(archive)
print(out/'QuietReader-Mac-First-Open.zip')
