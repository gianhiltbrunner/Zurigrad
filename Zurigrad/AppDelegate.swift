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
    static let URL : String = "https://www.stadt-zuerich.ch/ssd/de/index/sport/schwimmen/sommerbaeder/flussbad_unterer_letten.html"
    static let name : String = "Unterer Letten"
}

let menu = NSMenu()



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    let defaults = UserDefaults.standard
    lazy var currentLocationName : NSMenuItem = {
        return NSMenuItem(title: defaults.string(forKey: DefaultsKeys.name) ?? "Please choose location" , action: nil, keyEquivalent: "")
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
        
        
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(updateTemp), userInfo: nil, repeats: true).fire()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func updateIcon(temp: String) {
        if let button = self.statusItem.button {
            button.title = String(temp + "°")
        }
    }
    
    @objc func setLocation(_ sender: NSMenuItem) {
        
        let defaults = UserDefaults.standard
        
        defaults.set(sender.identifier!.rawValue, forKey: DefaultsKeys.URL)
        defaults.set(sender.title, forKey: DefaultsKeys.name)
        
        currentLocationName.title = sender.title
        
        updateTemp()
    }
    
    @objc func updateTemp (){
        let defaults = UserDefaults.standard
        if let URL = defaults.string(forKey: DefaultsKeys.URL) {
            
            AF.request(URL).responseString { response in
                
                switch response.result {
                case .success(let value):
                    do {
                        let doc: Document = try SwiftSoup.parse(value)
                        let linkText: String = try doc.getElementById("baederinfos_temperature_value")?.text().filter { "0"..."9" ~= $0 } ?? "Z"
                        
                        self.updateIcon(temp: linkText)
                        
                    } catch Exception.Error(_, let message) {
                        print(message)
                        self.updateIcon(temp: "Z°")
                    } catch {
                        print("error")
                        self.updateIcon(temp: "Z°")
                    }
                case .failure(let error):
                    print(error)
                    self.updateIcon(temp: "Z°")
                }
            }
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

