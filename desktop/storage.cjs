'use strict';
const path=require('node:path');
function dataFile(root,store,key){
  if(!['books','prefs'].includes(store)||typeof key!=='string'||!/^[a-zA-Z0-9-]{1,100}$/.test(key))throw Error('Invalid storage key');
  return path.join(root,store,key+'.json');
}
function validatePayload(value){if(value===undefined||Buffer.byteLength(JSON.stringify(value))>96*1024*1024)throw Error('Invalid storage payload')}
function allowedTitle(title){if(!['静读','工作台'].includes(title))throw Error('Invalid title');return title}
module.exports={dataFile,validatePayload,allowedTitle};
