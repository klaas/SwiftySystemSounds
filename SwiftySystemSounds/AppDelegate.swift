//
//  AppDelegate.swift
//  SwiftySystemSounds
//
//  Created by Klaas on 12.07.17.
//  Copyright © 2017 Park Bench. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		let vc = ViewController()
		let nc = UINavigationController(rootViewController: vc)
		window = UIWindow(frame: UIScreen.main.bounds)
		window!.rootViewController = nc
		window!.makeKeyAndVisible()
		
		return true
	}
}

