//
//  AppDelegate.swift
//  Zurigrad
//
//  Created by Gian Hiltbrunner on 15.07.20.
//  Copyright © 2020 Gian Hiltbrunner. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.title = "Z°"
        }
        
        constructMenu()
        
        Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(updateTemp), userInfo: nil, repeats: true).fire()//3600
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func updateIcon(temp: String) {
        if let button = self.statusItem.button {
            button.title = String(temp.prefix(4) + "°")
        }
    }
    
    @objc func updateTemp (){
        
        let currTime = String(Int64((Date().timeIntervalSince1970 * 1000.0).rounded()))
        
        let url = URL(string: "http://meteolakes.ch/api/coordinates/683418/246684/zurich/temperature/" + currTime + "/" + currTime + "/0")!
        
        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                     print(error.localizedDescription)
                     self.updateIcon(temp: "Z")
                     return
                 }
                 guard let data = data else {
                     print("Empty Data!")
                     self.updateIcon(temp: "Z")
                     return
                 }

                let text = String(decoding: data, as: UTF8.self)
                let temp = text.components(separatedBy: "\n")[1].components(separatedBy: ",")[1]
                
                self.updateIcon(temp: temp)
            }
        }.resume()

    }
    
    func constructMenu() {
      let menu = NSMenu()

      menu.addItem(NSMenuItem(title: "Quit Zürigrad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

      statusItem.menu = menu
    }
}

