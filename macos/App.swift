import Cocoa
import WebKit
import UniformTypeIdentifiers

final class ReaderApp: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var web: WKWebView!
    var quitting = false
    let dataRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QuietReader", isDirectory: true)
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "关于静读", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出静读", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let fileItem = NSMenuItem(); menu.addItem(fileItem); let fileMenu = NSMenu(title: "文件"); fileItem.submenu = fileMenu
        fileMenu.addItem(withTitle: "导入小说…", action: #selector(importNovel), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "我的书架", action: #selector(openLibrary), keyEquivalent: "b")
        let editItem = NSMenuItem(); menu.addItem(editItem); let edit = NSMenu(title:"编辑"); editItem.submenu=edit
        edit.addItem(withTitle:"撤销",action:Selector(("undo:")),keyEquivalent:"z")
        edit.addItem(withTitle:"剪切",action:#selector(NSText.cut(_:)),keyEquivalent:"x")
        edit.addItem(withTitle:"复制",action:#selector(NSText.copy(_:)),keyEquivalent:"c")
        edit.addItem(withTitle:"粘贴",action:#selector(NSText.paste(_:)),keyEquivalent:"v")
        edit.addItem(withTitle:"全选",action:#selector(NSText.selectAll(_:)),keyEquivalent:"a")
        let viewItem = NSMenuItem(); menu.addItem(viewItem); let viewMenu=NSMenu(title:"显示");viewItem.submenu=viewMenu
        let full=viewMenu.addItem(withTitle:"切换全屏",action:#selector(fullscreen),keyEquivalent:"f");full.keyEquivalentModifierMask=[.control,.command]
        NSApp.mainMenu=menu
        let cfg=WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        cfg.userContentController.add(self,name:"nativeBridge")
        web=WKWebView(frame:.zero,configuration:cfg)
        web.uiDelegate=self;web.navigationDelegate=self
        web.setValue(false,forKey:"drawsBackground")
        window=NSWindow(contentRect:NSRect(x:0,y:0,width:1320,height:880),styleMask:[.titled,.closable,.miniaturizable,.resizable,.fullSizeContentView],backing:.buffered,defer:false)
        window.title="静读";window.titleVisibility = .hidden;window.titlebarAppearsTransparent=true
        window.backgroundColor=NSColor(calibratedRed:0.09,green:0.17,blue:0.13,alpha:1)
        window.minSize=NSSize(width:720,height:540)
        window.contentView=web;window.delegate=self
        window.collectionBehavior=[.fullScreenPrimary]
        window.setFrameAutosaveName("QuietReaderWindow")
        window.center();window.makeKeyAndOrderFront(nil)
        if let url=Bundle.main.url(forResource:"index",withExtension:"html"){web.loadFileURL(url,allowingReadAccessTo:url.deletingLastPathComponent())}
        NSApp.activate(ignoringOtherApps:true)
    }
    @objc func about(){NSApp.orderFrontStandardAboutPanel(options:[.applicationName:"静读",.applicationVersion:"3.0",.credits:NSAttributedString(string:"全屏背景，自在阅读。\n小说、书签和进度只保存在你的 Mac。")])}
    @objc func importNovel(){web.evaluateJavaScript("document.getElementById('fileInput').click()")}
    @objc func openLibrary(){web.evaluateJavaScript("showLibrary()")}
    @objc func fullscreen(){window.toggleFullScreen(nil)}
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{true}
    func applicationShouldTerminate(_ sender:NSApplication)->NSApplication.TerminateReply {
        if quitting{return .terminateNow}
        quitting=true
        web.evaluateJavaScript("window.flushAndQuit ? window.flushAndQuit() : null")
        DispatchQueue.main.asyncAfter(deadline:.now()+2){NSApp.reply(toApplicationShouldTerminate:true)}
        return .terminateLater
    }
    func windowWillClose(_ notification:Notification){web.evaluateJavaScript("if(current){current.ratio=scrollRatio();persistBook()}")}
    func windowDidResignKey(_ notification:Notification){web.evaluateJavaScript("window.onNativeBlur?.();if(current){current.ratio=scrollRatio();persistBook()}")}
    func safeURL(store:String,key:String)throws->URL {
        guard ["books","prefs"].contains(store),key.range(of:"^[a-zA-Z0-9-]{1,100}$",options:.regularExpression) != nil else {throw NSError(domain:"QuietReader",code:1,userInfo:[NSLocalizedDescriptionKey:"无效的数据标识"])}
        let dir=dataRoot.appendingPathComponent(store,isDirectory:true)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        return dir.appendingPathComponent(key+".json")
    }
    func reply(_ id:Int,_ result:Any=NSNull(),_ error:String?=nil){
        let data=try! JSONSerialization.data(withJSONObject:[id,result,error as Any? ?? NSNull()],options:[.fragmentsAllowed])
        let json=String(data:data,encoding:.utf8)!
        web.evaluateJavaScript("window.nativeResult(...\(json));")
    }
    func userContentController(_ userContentController:WKUserContentController,didReceive message:WKScriptMessage){
        guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
              let msg=message.body as? [String:Any],let id=msg["id"] as? Int,let op=msg["op"] as? String else{return}
        let args=msg["args"] as? [String:Any] ?? [:]
        do {
            switch op {
            case "getAll":
                let store=args["store"] as? String ?? ""
                let dir=try safeURL(store:store,key:"placeholder").deletingLastPathComponent()
                let urls=try FileManager.default.contentsOfDirectory(at:dir,includingPropertiesForKeys:nil).filter{$0.pathExtension=="json"}
                let values=urls.compactMap{try? JSONSerialization.jsonObject(with:Data(contentsOf:$0),options:.fragmentsAllowed)}
                reply(id,values)
            case "get":
                let url=try safeURL(store:args["store"] as? String ?? "",key:args["key"] as? String ?? "")
                if FileManager.default.fileExists(atPath:url.path){reply(id,try JSONSerialization.jsonObject(with:Data(contentsOf:url),options:.fragmentsAllowed))}else{reply(id)}
            case "put":
                let url=try safeURL(store:args["store"] as? String ?? "",key:args["key"] as? String ?? "")
                let bytes=try JSONSerialization.data(withJSONObject:args["value"] ?? NSNull(),options:[.fragmentsAllowed])
                try bytes.write(to:url,options:.atomic);reply(id,true)
            case "delete":
                let url=try safeURL(store:args["store"] as? String ?? "",key:args["key"] as? String ?? "")
                if FileManager.default.fileExists(atPath:url.path){try FileManager.default.removeItem(at:url)};reply(id,true)
            case "fullscreen": fullscreen();reply(id,true)
            case "setTitle":
                guard let title=args["title"] as? String,["静读","工作台"].contains(title) else{throw NSError(domain:"QuietReader",code:3)}
                window.title=title;reply(id,true)
            case "quitReady":reply(id,true);if quitting{NSApp.reply(toApplicationShouldTerminate:true)}
            case "export":
                guard let text=args["text"] as? String else{throw NSError(domain:"QuietReader",code:2)}
                let panel=NSSavePanel();panel.title="备份静读书架";panel.nameFieldStringValue="静读书架备份.json";panel.allowedContentTypes=[.json]
                panel.beginSheetModal(for:window){result in
                    if result == .OK,let url=panel.url {do{try text.write(to:url,atomically:true,encoding:.utf8);self.reply(id,true)}catch{self.reply(id,NSNull(),error.localizedDescription)}}else{self.reply(id,false)}
                }
            default:reply(id,NSNull(),"不支持的操作")
            }
        }catch{reply(id,NSNull(),error.localizedDescription)}
    }
    func webView(_ webView:WKWebView,runOpenPanelWith parameters:WKOpenPanelParameters,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping ([URL]?)->Void){
        let panel=NSOpenPanel();panel.canChooseFiles=true;panel.canChooseDirectories=false;panel.allowsMultipleSelection=parameters.allowsMultipleSelection;panel.title="选择小说、背景图片或书架备份"
        panel.beginSheetModal(for:window){result in completionHandler(result == .OK ? panel.urls:nil)}
    }
    func webView(_ webView:WKWebView,runJavaScriptConfirmPanelWithMessage message:String,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping (Bool)->Void){
        let alert=NSAlert();alert.messageText=message;alert.addButton(withTitle:"确定");alert.addButton(withTitle:"取消");alert.beginSheetModal(for:window){completionHandler($0 == .alertFirstButtonReturn)}
    }
    func webView(_ webView:WKWebView,runJavaScriptAlertPanelWithMessage message:String,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping ()->Void){let alert=NSAlert();alert.messageText=message;alert.beginSheetModal(for:window){_ in completionHandler()}}
    func webView(_ webView:WKWebView,decidePolicyFor navigationAction:WKNavigationAction,decisionHandler:@escaping (WKNavigationActionPolicy)->Void){
        guard let url=navigationAction.request.url else{decisionHandler(.cancel);return}
        let resources=Bundle.main.resourceURL!.standardizedFileURL.path+"/"
        decisionHandler(url.isFileURL && url.standardizedFileURL.path.hasPrefix(resources) ? .allow:.cancel)
    }
}
let app=NSApplication.shared
let delegate=ReaderApp();app.delegate=delegate;app.run()
