//
//  Utils.swift
//
//  Created by  Dmitry Ondrin on 25/04/2020.
//  Copyright © 2020  Dmitry Ondrin. All rights reserved.
//

import UIKit

//MARK:- UIViewController extension

extension UIViewController {
    class func viewControllerWithStoryboard<T: UIViewController>(identifier: String?) -> T {
        let className = self.getClassName()
        let sb = UIStoryboard(name: className, bundle: nil)
        let result: UIViewController
        if let id = identifier {
            result = sb.instantiateViewController(withIdentifier: id)
        } else {
            result = sb.instantiateInitialViewController()!
        }
        
        return result as! T
    }
    
    class func initialViewControllerFromStoryboard<T: UIViewController>() -> T {
        return self.viewControllerWithStoryboard(identifier: nil)
    }
}

//MARK:- UIView extension

extension UIView {
    class func getNib() -> UINib {
        let className = String(describing: self)
        return UINib(nibName: className, bundle: nil)
    }
    
    class func viewFromNib() -> UIView {
        return self.getNib().instantiate(withOwner: nil, options: nil).first! as! UIView
    }
    
    /// Add subview with setting it's autoresizing to mimic the container
    /// - Parameter subview: child view to add
    func addAutoresizingSubview(_ subview: UIView) {
        subview.removeFromSuperview()
        subview.frame = self.bounds
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(subview)
    }
}

//MARK:- NSObject extension

extension NSObject {
    public class func getClassName() -> String {
        return String(describing: self)
    }
}

//MARK:- String extension

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
