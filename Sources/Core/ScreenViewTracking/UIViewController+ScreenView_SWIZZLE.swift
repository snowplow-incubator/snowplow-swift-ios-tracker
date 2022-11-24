//
//  UIViewController+SPScreenView_SWIZZLE.swift
//  Snowplow
//
//  Copyright (c) 2013-2022 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Michael Hadam
//  License: Apache License Version 2.0
//

#if !os(macOS)

import ObjectiveC
import UIKit

extension UIViewController {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIViewController.swizzleViewWillAppear()
        return true
    }
    
    class func swizzleViewWillAppear() {
        if self != UIViewController.self {
            return
        }
        
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(sp_viewDidAppear(_:))
        
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        var didAddMethod = false
        if let swizzledMethod = swizzledMethod {
            didAddMethod = class_addMethod(
                self,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod))
        }
        
        if didAddMethod {
            if let originalMethod = originalMethod {
                class_replaceMethod(
                    self,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod))
            }
        } else {
            if let originalMethod = originalMethod,
               let swizzledMethod = swizzledMethod {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }

    // MARK: - Method Swizzling

    @objc func sp_viewDidAppear(_ animated: Bool) {
        sp_viewDidAppear(animated)

        let bundle = Bundle(for: UIViewController.self)
        if !bundle.bundlePath.hasPrefix(Bundle.main.bundlePath) {
            // Ignore view controllers that don't start with the main bundle path
            return
        }

        // Construct userInfo
        var userInfo: [AnyHashable : Any] = [:]
        userInfo["viewControllerClassName"] = NSStringFromClass(UIViewController.self)
        if let controller = _SP_top() {
            userInfo["topViewControllerClassName"] = NSStringFromClass(type(of: controller).self)
        }
        // `name` is set to snowplowId class instance variable if it exists (hence no @"id" in userInfo)
        userInfo["name"] = _SP_getName()
        userInfo["type"] = NSNumber(value: _SP_getTopViewControllerType().rawValue)

        // Send notification to tracker
        NotificationCenter.default.post(
            name: NSNotification.Name("SPScreenViewDidAppear"),
            object: self,
            userInfo: userInfo)
    }

    func _SP_validate(_ string: String) -> Bool {
        return string.count > 0
    }

    func _SP_getSnowplowId() -> String? {
        let propertyName = "snowplowId"
        let selector = NSSelectorFromString(propertyName)
        let propertyExists = responds(to: selector)
        if propertyExists {
            if let value = self.value(forKey: propertyName) as? String {
                return value
            }
        }
        return nil
    }

    func _SP_getName() -> String {
        if let viewControllerName = _SP_getName(self) {
            return viewControllerName
        }
        if let controller = _SP_top(),
           let topViewControllerName = _SP_getName(controller) {
            return topViewControllerName
        }

        return "Unknown"
    }

    func _SP_getName(_ viewController: UIViewController) -> String? {
        // check if there's an instance variable snowplowId
        if let viewControllerSnowplowId = viewController._SP_getSnowplowId() {
            if _SP_validate(viewControllerSnowplowId) {
                return viewControllerSnowplowId
            }
        }

        // otherwise return the class name
        let viewControllerClassName = NSStringFromClass(type(of: viewController).self)
        if _SP_validate(viewControllerClassName) {
            return viewControllerClassName
        }

        return nil
    }

    func _SP_getType(_ viewController: UIViewController) -> ScreenType {
        if viewController is UINavigationController {
            return .navigation
        }
        if viewController is UITabBarController {
            return .tabBar
        }
        if viewController.presentedViewController != nil {
            return .modal
        }
        if viewController is UIPageViewController {
            return .pageView
        }
        if viewController is UISplitViewController {
            return .splitView
        }
        // TODO: this was taken over from Obj-C, how would it ever occur?
        if viewController is UIPopoverPresentationController {
            return .popoverPresentation
        }
        return .default
    }

    func _SP_getTopViewControllerType() -> ScreenType {
        if let controller = _SP_top() {
            return _SP_getType(controller)
        }
        return .default
    }

    func _SP_top() -> UIViewController? {
        if let keyWindow = view.window,
           let rootViewController = keyWindow.rootViewController {
            return self._SP_topViewController(rootViewController)
        }
        return nil
    }

    func _SP_topViewController(_ rootViewController: UIViewController) -> UIViewController {
        if let navigationController = rootViewController as? UINavigationController,
           let last = navigationController.viewControllers.last {
            return _SP_topViewController(last)
        }

        if let tabBarController = rootViewController as? UITabBarController,
           let controller = tabBarController.selectedViewController {
            return _SP_topViewController(controller)
        }

        if let presentedViewController = rootViewController.presentedViewController {
            return _SP_topViewController(presentedViewController)
        }

        return rootViewController
    }
}

#endif
