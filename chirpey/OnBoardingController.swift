//
//  OnBoardingController.swift
//  microjam
//
//  Created by Henrik Brustad on 24/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class OnBoardingController: UIPageViewController {
    
    let orderedControllers: [UIViewController] = {
        let first = UserNameController()
        first.view.backgroundColor = .red
        
        let second = UserNameController()
        second.view.backgroundColor = .blue
        
        return [first, second]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        setViewControllers([orderedControllers.first!], direction: .forward, animated: false, completion: nil)
    }
    
}

extension OnBoardingController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let index = orderedControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = index + 1
        
        guard nextIndex < orderedControllers.count else {
            return nil
        }
        
        return orderedControllers[nextIndex]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let index = orderedControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = index - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return orderedControllers[previousIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first, let firstViewControllerIndex = orderedControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}
