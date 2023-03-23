import Quick
import Nimble
@testable import RAnalytics
import UIKit

final class UIViewControllerExtensionsSpec: QuickSpec {
    override func spec() {
        describe("UIViewController extensions") {
            describe("isTrackableAsPageVisit") {
                context("When view controller type is UINavigationController") {
                    it("should return false") {
                        expect(UINavigationController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UISplitViewController") {
                    it("should return false") {
                        expect(UISplitViewController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UIPageViewController") {
                    it("should return false") {
                        expect(UIPageViewController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UITabBarController") {
                    it("should return false") {
                        expect(UITabBarController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UIAlertController") {
                    it("should return false") {
                        expect(UIAlertController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                func verifyPageTracking(for viewController: UIViewController) {
                    context("When view type is UIAlertView") {
                        it("should return false") {
                            viewController.view = UIAlertView()
                            expect(viewController.isTrackableAsPageVisit).to(beFalse())
                        }
                    }

                    context("When view type is UIActionSheet") {
                        it("should return false") {
                            viewController.view = UIActionSheet()
                            expect(viewController.isTrackableAsPageVisit).to(beFalse())
                        }
                    }

                    context("When view type is UIView") {
                        context("When view controller is not added to window") {
                            it("should return true") {
                                viewController.view = UIView()

                                expect(viewController.view.window).to(beNil())
                                expect(viewController.isTrackableAsPageVisit).to(beTrue())
                            }
                        }

                        context("When rootViewController is set") {
                            it("should return true") {
                                viewController.view = UIView()

                                let window = UIWindow()
                                window.rootViewController = viewController
                                window.makeKeyAndVisible()

                                expect(viewController.view.window).toNot(beNil())
                                expect(viewController.isTrackableAsPageVisit).to(beTrue())
                            }
                        }
                    }

                    context("When view is nil") {
                        it("should return true") {
                            viewController.view = nil
                            expect(viewController.isTrackableAsPageVisit).to(beTrue())
                        }
                    }
                }

                context("When view controller type is UIViewController") {
                    verifyPageTracking(for: UIViewController())
                }

                context("When view controller type is UITableViewController") {
                    verifyPageTracking(for: UITableViewController())
                }
            }
        }
    }
}
