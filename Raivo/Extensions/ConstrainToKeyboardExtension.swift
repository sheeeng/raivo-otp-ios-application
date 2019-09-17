//
// Raivo OTP
//
// Copyright (c) 2019 Tijme Gommers. All rights reserved. Raivo OTP
// is provided 'as-is', without any express or implied warranty.
//
// Modification, duplication or distribution of this software (in 
// source and binary forms) for any purpose is strictly prohibited.
//
// https://github.com/tijme/raivo/blob/master/LICENSE.md
// 

import Foundation
import UIKit

extension UIViewController {
    
    struct KeyboardStates {
        static var visible: [String: Bool] = [:]
    }
    
    internal func attachKeyboardConstraint(_ sender: UIViewController) {
        let identifier = id(sender)
        
        NotificationHelper.shared.listen(to: UIResponder.keyboardWillShowNotification, distinctBy: id(self)) { notification in
            self.keyboardWillShow(notification: notification, identifier: identifier)
        }
        
        NotificationHelper.shared.listen(to: UIResponder.keyboardWillHideNotification, distinctBy: id(self)) { notification in
            self.keyboardWillHide(notification: notification, identifier: identifier)
        }
    }
    
    internal func detachKeyboardConstraint(_ sender: UIViewController) {
        NotificationHelper.shared.discard(UIResponder.keyboardWillShowNotification, byDistinctName: id(self))
        NotificationHelper.shared.discard(UIResponder.keyboardWillHideNotification, byDistinctName: id(self))

        keyboardWillHide(notification: nil, identifier: id(sender))
    }
    
    @objc private func keyboardWillShow(notification: Notification, identifier: String) {
        let currentlyVisible = KeyboardStates.visible[identifier] ?? false
        KeyboardStates.visible[identifier] = true
        
        guard currentlyVisible != true else {
            // Notification is same as previous one
            return
        }
        
        guard let userInfo = notification.userInfo else {
           return
        }
        
        guard var height = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
            return
        }
        
        guard let keyboardDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            return
        }
        
        guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) else {
            return
        }
        
        if #available(iOS 11.0, *) {
            height -= view.safeAreaInsets.bottom
        }
        
        additionalSafeAreaInsets.bottom = height
        
        ui {
            UIView.animate(
                withDuration: keyboardDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: keyboardAnimationCurve.uintValue),
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification?, identifier: String) {
        let currentlyVisible = KeyboardStates.visible[identifier] ?? false
        KeyboardStates.visible[identifier] = false

        guard currentlyVisible != false else {
            // Notification is same as previous one
            return
        }
        
        let keyboardDuration = (notification?.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.6
        
        var options: UIView.AnimationOptions = []
        
        if let keyboardAnimationCurve = (notification?.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) {
            options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve.uintValue)
        }
        
        additionalSafeAreaInsets.bottom = CGFloat(0)
        
        ui {
            UIView.animate(
                withDuration: keyboardDuration,
                delay: 0,
                options: options,
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        }
    }
    
}
