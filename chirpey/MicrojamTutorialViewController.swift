//
//  UserNameChooserViewController.swift
//  microjam
//
//  Username choosing screen displayed on first launch.
//
//  Created by Charles Martin on 28/2/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialViewController: UIPageViewController {
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [
           
            UIStoryboard(name:"MicrojamTutorialViewController", bundle: nil).instantiateViewController(withIdentifier: "UserNameChooser"),
                UIStoryboard(name:"MicrojamTutorialViewController", bundle: nil).instantiateViewController(withIdentifier: "AvatarChooser"),
                 UIStoryboard(name:"MicrojamTutorialViewController", bundle: nil).instantiateViewController(withIdentifier: "JamTester")
        ]
    }()

    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> MicrojamTutorialViewController? {
        print("TutorialVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"MicrojamTutorialViewController", bundle: nil)
        print("TutorialVC: Opened storyboard.")
        return storyboard.instantiateInitialViewController() as? MicrojamTutorialViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self // UIPageViewController datasource
        print("TutorialVC: Attempting to present first VC.")
        // Display first VC
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
            print("TutorialVC: Presented first VC.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}

extension MicrojamTutorialViewController: UIPageViewControllerDelegate {
    
}

extension MicrojamTutorialViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else { return nil }
        guard orderedViewControllers.count > previousIndex else { return nil }
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else { return nil }
        guard orderedViewControllersCount > nextIndex else { return nil }
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        return firstViewControllerIndex
    }
}
