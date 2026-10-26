'use strict';
const {app,BrowserWindow,Menu,ipcMain,dialog}=require('electron');
const fs=require('node:fs/promises');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {dataFile,validatePayload,allowedTitle}=require('./storage.cjs');
app.setName('QuietReader');
app.setPath('userData',path.join(app.getPath('appData'),'QuietReader'));
let win,allowClose=false,closing=false,flushTimer;
const entry=path.join(__dirname,'../src/index.html');
const entryURL=pathToFileURL(entry).href;
const root=app.getPath('userData');
async function get(store,key){const file=dataFile(root,store,key);try{return JSON.parse(await fs.readFile(file,'utf8'))}catch(err){if(err.code==='ENOENT')return null;throw err}}
async function put(store,key,value){validatePayload(value);const file=dataFile(root,store,key);await fs.mkdir(path.dirname(file),{recursive:true});const temp=file+'.tmp';await fs.writeFile(temp,JSON.stringify(value),'utf8');await fs.rename(temp,file);return true}
function finishClose(){allowClose=true;clearTimeout(flushTimer);setImmediate(()=>{if(win&&!win.isDestroyed())win.close()})}
ipcMain.handle('quiet-reader',async(event,op,args={})=>{
  if(!win||event.sender!==win.webContents||event.senderFrame!==win.webContents.mainFrame||event.senderFrame.url!==entryURL)throw Error('Untrusted sender');
  if(!args||typeof args!=='object'||Array.isArray(args))throw Error('Invalid request');
  switch(op){
    case 'get':return get(args.store,args.key);
    case 'getAll':{
      const dir=path.dirname(dataFile(root,args.store,'placeholder'));
      await fs.mkdir(dir,{recursive:true});const files=(await fs.readdir(dir)).filter(f=>/^[a-zA-Z0-9-]{1,100}\.json$/.test(f));
      const values=[];for(const file of files){try{values.push(JSON.parse(await fs.readFile(path.join(dir,file),'utf8')))}catch{/* Keep intact unreadable files for recovery. */}}return values;
    }
    case 'put':return put(args.store,args.key,args.value);
    case 'delete':await fs.rm(dataFile(root,args.store,args.key),{force:true});return true;
    case 'fullscreen':win.setFullScreen(!win.isFullScreen());return true;
    case 'setTitle':win.setTitle(allowedTitle(args.title));return true;
    case 'export':{
      if(typeof args.text!=='string'||Buffer.byteLength(args.text)>128*1024*1024)throw Error('Invalid backup');
      const result=await dialog.showSaveDialog(win,{title:'备份静读书架',defaultPath:'静读书架备份.json',filters:[{name:'静读书架备份',extensions:['json']}]});
      if(result.canceled||!result.filePath)return false;await fs.writeFile(result.filePath,args.text,'utf8');return true;
    }
    case 'quitReady':if(closing)finishClose();return true;
    default:throw Error('Unsupported operation');
  }
});
function run(js){if(win&&!win.isDestroyed())win.webContents.executeJavaScript(js).catch(()=>{})}
app.whenReady().then(()=>{
  win=new BrowserWindow({width:1320,height:880,minWidth:720,minHeight:540,title:'静读',backgroundColor:'#162a25',icon:path.join(__dirname,'../src/assets/icon.png'),autoHideMenuBar:process.platform!=='darwin',webPreferences:{preload:path.join(__dirname,'preload.cjs'),contextIsolation:true,nodeIntegration:false,sandbox:true,webSecurity:true}});
  win.webContents.setWindowOpenHandler(()=>({action:'deny'}));
  win.webContents.on('will-navigate',(e,url)=>{if(url!==entryURL)e.preventDefault()});
  win.webContents.on('will-attach-webview',e=>e.preventDefault());
  win.webContents.session.setPermissionRequestHandler((_contents,_permission,cb)=>cb(false));
  win.webContents.session.webRequest.onBeforeRequest((details,cb)=>cb({cancel:!['file:','data:','blob:','devtools:'].some(p=>details.url.startsWith(p))}));
  win.on('blur',()=>run('window.onNativeBlur?.()'));
  win.on('close',event=>{if(allowClose)return;event.preventDefault();if(closing)return;closing=true;run('window.flushAndQuit?.()');flushTimer=setTimeout(finishClose,3000)});
  const menus=[{label:'文件',submenu:[{label:'导入小说',accelerator:'CmdOrCtrl+O',click:()=>run("document.getElementById('fileInput').click()")},{label:'书架',accelerator:'CmdOrCtrl+B',click:()=>run('showLibrary()')},{type:'separator'},{role:'quit',label:'退出'}]},{label:'编辑',submenu:[{role:'undo',label:'撤销'},{role:'cut',label:'剪切'},{role:'copy',label:'复制'},{role:'paste',label:'粘贴'},{role:'selectAll',label:'全选'}]},{label:'显示',submenu:[{label:'切换全屏',accelerator:process.platform==='darwin'?'Ctrl+Cmd+F':'F11',click:()=>win.setFullScreen(!win.isFullScreen())},{label:'主题套装',click:()=>run("document.getElementById('skinDialog').showModal()")},{label:'隐藏 / 恢复正文',accelerator:'CmdOrCtrl+Shift+X',click:()=>run("if(settings.skin==='stealth')setCovered(!covered)")}]}];
  if(process.platform==='darwin')menus.unshift({label:'静读',submenu:[{role:'about',label:'关于静读'},{type:'separator'},{role:'hide',label:'隐藏静读'},{role:'quit',label:'退出静读'}]});
  Menu.setApplicationMenu(Menu.buildFromTemplate(menus));win.loadFile(entry);
});
app.on('window-all-closed',()=>app.quit());
