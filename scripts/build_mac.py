#!/usr/bin/env python3
"""Build the native Apple Silicon app using Apple's local SDK, no pip dependencies."""
import argparse, pathlib, plistlib, shutil, subprocess, tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--output',type=pathlib.Path,default=ROOT/'dist'/'静读.app');args=p.parse_args()
output=args.output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='quiet-reader-build-') as temp:
    stage=pathlib.Path(temp)/'静读.app';contents=stage/'Contents';(contents/'MacOS').mkdir(parents=True)
    shutil.copytree(ROOT/'src',contents/'Resources',ignore=shutil.ignore_patterns('body.html'))
    shutil.copy(ROOT/'src/assets/AppIcon.icns',contents/'Resources/AppIcon.icns')
    meta={'CFBundleName':'静读','CFBundleDisplayName':'静读','CFBundleIdentifier':'local.quietreader.desktop','CFBundleExecutable':'QuietReader','CFBundlePackageType':'APPL','CFBundleShortVersionString':'3.0.0','CFBundleVersion':'3','CFBundleIconFile':'AppIcon','LSMinimumSystemVersion':'13.0','NSHighResolutionCapable':True,'NSPrincipalClass':'NSApplication','LSApplicationCategoryType':'public.app-category.books','CFBundleDevelopmentRegion':'zh_CN','CFBundleLocalizations':['zh_CN','en']}
    (contents/'Info.plist').write_bytes(plistlib.dumps(meta))
    subprocess.run(['xcrun','swiftc',str(ROOT/'macos/App.swift'),'-o',str(contents/'MacOS/QuietReader'),'-framework','Cocoa','-framework','WebKit','-module-cache-path',str(pathlib.Path(temp)/'modules')],check=True)
    subprocess.run(['codesign','--force','--deep','--sign','-',str(stage)],check=True)
    if output.exists():shutil.rmtree(output)
    shutil.copytree(stage,output)
subprocess.run(['codesign','--verify','--deep','--strict',str(output)],check=True)
print(output)
