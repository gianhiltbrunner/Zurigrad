//
//  AppDelegate.swift
//  Zurigrad
//
//  Created by Gian Hiltbrunner on 15.07.20.
//  Copyright © 2020 Gian Hiltbrunner. All rights reserved.
//

import Cocoa
import SwiftUI
import LaunchAtLogin
import Alamofire
import SwiftSoup

struct Location: Decodable {
    let URL: String
    let name: String
    let type: String
}

struct DefaultsKeys {
    static let URL : String = "url"
    static let name : String = "name"
}

let menu = NSMenu()



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    let defaults = UserDefaults.standard
    lazy var currentLocationName : NSMenuItem = {
        return NSMenuItem(
            title: defaults.string(forKey: DefaultsKeys.name) ?? "Please choose location" ,
            action: defaults.string(forKey: DefaultsKeys.URL) != nil ? #selector(showDetails(_:)) : nil,
            keyEquivalent: ""
        )
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if let button = statusItem.button {
            button.title = "Z°"
        }
        
        do {
            if let bundlePath = Bundle.main.path(forResource: "locations",
                                                 ofType: "json"),
               let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                let Locations: [Location] = try! JSONDecoder().decode([Location].self, from: jsonData)
                
                constructMenu(locations: Locations)
            }
        } catch {
            print(error)
        }
        
        
        Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(updateTemp), userInfo: nil, repeats: true).fire()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func updateIcon(display: String, temperature: Bool = true) {
        if let button = self.statusItem.button {
            button.title = String(display + (temperature ? "°" : "") )
        }
    }
    
    @objc func showDetails(_ sender: NSMenuItem) {
        let locationsWebsite = defaults.string(forKey: DefaultsKeys.URL)
        if locationsWebsite != nil {
        // Open the website on the specifc location
            NSWorkspace.shared.open(URL(string: locationsWebsite!)!)
        }
    }
    
    @objc func setLocation(_ sender: NSMenuItem) {
        
        let defaults = UserDefaults.standard
        
        defaults.set(sender.identifier!.rawValue, forKey: DefaultsKeys.URL)
        defaults.set(sender.title, forKey: DefaultsKeys.name)
        
        currentLocationName.action = #selector(showDetails(_:))
        
        currentLocationName.title = sender.title
        
        updateTemp()
    }
    
    @objc func updateTemp (){
        self.updateIcon(display: "↻", temperature: false)
        let defaults = UserDefaults.standard
        if let URL = defaults.string(forKey: DefaultsKeys.URL) {
            
            AF.request(URL).responseString { response in
                
                switch response.result {
                case .success(let value):
                    do {
                        let doc: Document = try SwiftSoup.parse(value)
                        let linkText: String = try doc.getElementById("baederinfos_temperature_value")?.text().filter { "0"..."9" ~= $0 } ?? "Z"
                        
                        self.updateIcon(display: linkText)
                        
                    } catch Exception.Error(_, let message) {
                        print(message)
                        self.updateIcon(display: "Z°", temperature: false)
                    } catch {
                        print("error")
                        self.updateIcon(display: "Z°", temperature: false)
                    }
                case .failure(let error):
                    print(error)
                    self.updateIcon(display: "Z°", temperature: false)
                }
            }
        }
        else {
            self.updateIcon(display: "Z°", temperature: false)
        }
        
        
    }
    
    func constructMenu(locations: [Location]) {
        LaunchAtLogin.isEnabled = true
        
        menu.addItem(currentLocationName)
        
        let location_menu = NSMenu(title: "Location")
        
        for loc in locations{
            let mi = NSMenuItem(title: loc.name + " (" + loc.type + ")", action: #selector(setLocation(_:)), keyEquivalent: "")
            mi.identifier = NSUserInterfaceItemIdentifier(rawValue: loc.URL)
            location_menu.addItem(mi)
        }
        
        let locationDropdown = NSMenuItem(title: "Set Location", action: nil, keyEquivalent: "")
        menu.setSubmenu(location_menu, for: locationDropdown)
        
        menu.addItem(locationDropdown)
        menu.addItem(NSMenuItem(title: "Quit Zürigrad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
}

