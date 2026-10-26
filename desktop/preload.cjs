'use strict';
const {contextBridge,ipcRenderer}=require('electron');
const allowed=new Set(['getAll','get','put','delete','export','fullscreen','setTitle','quitReady']);
contextBridge.exposeInMainWorld('readerBridge',Object.freeze({
  request(op,args={}){
    if(!allowed.has(op))return Promise.reject(new Error('Unsupported operation'));
    return ipcRenderer.invoke('quiet-reader',op,args);
  }
}));
