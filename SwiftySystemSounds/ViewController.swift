//
//  ViewController.swift
//  AudioToolboxSystemSounds
//
//  Created by Klaas on 12.07.17.
//  Copyright © 2017 Park Bench. All rights reserved.
//

import UIKit
import AudioToolbox

extension FileManager {
	func isDirectory(url:URL) -> Bool? {
		var isDir: ObjCBool = ObjCBool(false)
		if fileExists(atPath: url.path, isDirectory: &isDir) {
			return isDir.boolValue
		} else {
			return nil
		}
	}
}

struct SystemSoundInfo {
	let url:URL
	let name:String
	let size:Int
}

class ViewController: UITableViewController {
	
	var infos:[SystemSoundInfo] = []
	
	// MARK: - 🔴🔴🔴🔴🔴 init 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	init() {
		super.init(style: .plain)
		
		self.title = "System Sounds"
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(ViewController.persist(sender:)))
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - 🔴🔴🔴🔴🔴 UIViewController 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let fm = FileManager.default
		let baseUrl = URL(fileURLWithPath: "/System/Library/Audio/UISounds")
		let enu = fm.enumerator(at: baseUrl, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles], errorHandler: nil)!
		
		while let fileUrl = enu.nextObject() as? URL {
			if fm.isDirectory(url: fileUrl) == false {
				let name = fileUrl.path.substring(from: fileUrl.path.index(fileUrl.path.startIndex, offsetBy: 31))
				
				do {
					//					let size = try! Data(contentsOf: fileUrl).count
					let size = try fileUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
					infos.append(SystemSoundInfo(url: fileUrl, name:name, size: size))
				} catch {
					print("🔴 Error: \(error.localizedDescription)")
				}
			}
		}
		
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
	}
	
	// MARK: - 🔴🔴🔴🔴🔴 UITableViewDelegate 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let ssi = infos[indexPath.item]
		
		var soundID:SystemSoundID = 0
		AudioServicesCreateSystemSoundID(ssi.url as CFURL, &soundID)
		AudioServicesPlaySystemSound(soundID)
	}
	
	// MARK: - 🔴🔴🔴🔴🔴 UITableViewDataSource 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return infos.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		let ssi = infos[indexPath.item]
		
		let formatter = ByteCountFormatter()
		formatter.allowedUnits = ByteCountFormatter.Units.useKB
		formatter.countStyle = ByteCountFormatter.CountStyle.file
		
		let formatedSize = formatter.string(fromByteCount: Int64(ssi.size))
		
		cell.textLabel?.text = "\(ssi.name) (\(formatedSize))"
		return cell
	}
	
	// MARK: - 🔴🔴🔴🔴🔴 methods 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	func persist() {
		let destBaseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
		
		for ssi in infos {
			let data = try! Data(contentsOf: ssi.url)
			let destFileUrl = destBaseUrl.appendingPathComponent(ssi.name)
			
			let dirUrl = destFileUrl.deletingLastPathComponent()
			try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories:true, attributes:nil)
			
			try! data.write(to: destFileUrl)
		}
	}
	
	// MARK: - 🔴🔴🔴🔴🔴 targets 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
	
	func persist(sender:UIBarButtonItem) {
		persist()
		
		let ac = UIAlertController(title: "Saved to Documents dir", message: "Use Xcode -> Window -> Devices (⇧⌘2) -> Installed Apps -> Download container... to copy the files to your computer", preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(ac, animated: true, completion: nil)
		
	}
}

