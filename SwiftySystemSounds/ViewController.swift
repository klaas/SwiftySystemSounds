//
//  ViewController.swift
//  AudioToolboxSystemSounds
//
//  Created by Klaas on 12.07.17.
//  Copyright © 2017 Park Bench. All rights reserved.
//

import UIKit
import AudioToolbox

struct SystemSoundInfo {
	let url: URL
	let name: String
	let size: Int
}

class SystemSoundsManager {
	var infos: [SystemSoundInfo] = []

	init() {
		self.infos = gatherSystemSounds()
	}

	private func gatherSystemSounds() -> [SystemSoundInfo] {
		let fm = FileManager.default
		let baseUrl = URL(fileURLWithPath: "/System/Library/Audio/UISounds")
		let enu = fm.enumerator(at: baseUrl, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles], errorHandler: nil)!

		while let fileUrl = enu.nextObject() as? URL {
			do {
				let rv = try fileUrl.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
				if !rv.isDirectory! {
					let name = String(fileUrl.path.dropFirst(31))

					let size = rv.fileSize ?? 0
					infos.append(SystemSoundInfo(url: fileUrl, name: name, size: size))
				}
			} catch {
				print("🔴 Error: \(error.localizedDescription)")
			}
		}

		return infos.sorted { $0.name < $1.name }
	}

	/// Used to create the list of system sounds in README.md
	private func printAll() {
		print("| Name | Size |")
		print("| --- | --- |")

		let formatter = ByteCountFormatter()
		formatter.allowedUnits = ByteCountFormatter.Units.useKB
		formatter.countStyle = ByteCountFormatter.CountStyle.file

		for ssi in infos {
			let formattedSize = formatter.string(fromByteCount: Int64(ssi.size))
			print("| \(ssi.name) | \(formattedSize) |")
		}
	}
}

class ViewController: UITableViewController {
	let ssm = SystemSoundsManager()
	var filteredInfos: [SystemSoundInfo] = []

	let searchController = UISearchController(searchResultsController: nil)

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

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

		searchController.searchResultsUpdater = self
		searchController.hidesNavigationBarDuringPresentation = false
		tableView.tableHeaderView = searchController.searchBar
		filteredInfos = ssm.infos
	}

	// MARK: - 🔴🔴🔴🔴🔴 UITableViewDelegate 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		let ssi = filteredInfos[indexPath.item]

		var soundID: SystemSoundID = 0
		AudioServicesCreateSystemSoundID(ssi.url as CFURL, &soundID)

		print("Playing soundID \(soundID)")
		
		AudioServicesPlaySystemSound(soundID)
	}

	// MARK: - 🔴🔴🔴🔴🔴 UITableViewDataSource 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredInfos.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		let ssi = filteredInfos[indexPath.item]

		let formatter = ByteCountFormatter()
		formatter.allowedUnits = ByteCountFormatter.Units.useKB
		formatter.countStyle = ByteCountFormatter.CountStyle.file

		let formattedSize = formatter.string(fromByteCount: Int64(ssi.size))

		cell.textLabel?.text = "\(ssi.name) (\(formattedSize))"
		return cell
	}

	// MARK: - 🔴🔴🔴🔴🔴 methods 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴

	func persist() {
		let destBaseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!

		for ssi in filteredInfos {
			let data = try! Data(contentsOf: ssi.url)
			let destFileUrl = destBaseUrl.appendingPathComponent(ssi.name)

			let dirUrl = destFileUrl.deletingLastPathComponent()
			try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: nil)

			try! data.write(to: destFileUrl)
		}
	}

	// MARK: - 🔴🔴🔴🔴🔴 targets 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴

	@objc func persist(sender: UIBarButtonItem) {
		persist()

		let ac = UIAlertController(title: "Saved to Documents dir", message: "Use Xcode -> Window -> Devices (⇧⌘2) -> Installed Apps -> Download container... to copy the files to your computer", preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(ac, animated: true, completion: nil)
	}
}

// MARK: - Search Results Delegate

extension ViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		if let searchText = searchController.searchBar.text, !searchText.isEmpty {
			filteredInfos = ssm.infos.filter { info in
				return info.name.lowercased().contains(searchText.lowercased())
			}
		} else {
			filteredInfos = ssm.infos
		}

		tableView.reloadData()
	}
}
