import berniesanders
import Quick
import Nimble
import UIKit

class IssuesFakeTheme : FakeTheme {
    override func issuesFeedTitleFont() -> UIFont {
        return UIFont.boldSystemFontOfSize(20)
    }
    
    override func issuesFeedTitleColor() -> UIColor {
        return UIColor.magentaColor()
    }
    
    override func tabBarTextColor() -> UIColor {
        return UIColor.purpleColor()
    }
    
    override func tabBarFont() -> UIFont {
        return UIFont.systemFontOfSize(123)
    }
}

class FakeIssueRepository : berniesanders.IssueRepository {
    var lastCompletionBlock: ((Array<Issue>) -> Void)?
    var lastErrorBlock: ((NSError) -> Void)?
    var fetchIssuesCalled: Bool = false
    
    init() {
    }
    
    func fetchIssues(completion: (Array<Issue>) -> Void, error: (NSError) -> Void) {
        self.fetchIssuesCalled = true
        self.lastCompletionBlock = completion
        self.lastErrorBlock = error
    }
}

class FakeIssueControllerProvider : berniesanders.IssueControllerProvider {
    let controller = IssueController(issue: Issue(title: "a title", body: "body", imageURL: NSURL()), imageRepository: FakeImageRepository(), theme: FakeTheme())
    var lastIssue: Issue?
    
    func provideInstanceWithIssue(issue: Issue) -> IssueController {
        self.lastIssue = issue;
        return self.controller
    }
}


class IssuesTableViewControllerSpec: QuickSpec {
    var subject: IssuesTableViewController!
    var issueRepository: FakeIssueRepository! = FakeIssueRepository()
    var issueControllerProvider = FakeIssueControllerProvider()
    
    override func spec() {
        beforeEach {
            self.subject = IssuesTableViewController(
                issueRepository: self.issueRepository,
                issueControllerProvider: self.issueControllerProvider,
                theme: IssuesFakeTheme()
            )
        }
        
        it("has the correct tab bar title") {
            expect(self.subject.title).to(equal("Issues"))
        }
        
        it("has the correct navigation item title") {
            expect(self.subject.navigationItem.title).to(equal("ISSUES"))
        }
        
        it("styles its tab bar item from the theme") {
            let normalAttributes = self.subject.tabBarItem.titleTextAttributesForState(UIControlState.Normal)
            
            let normalTextColor = normalAttributes[NSForegroundColorAttributeName] as! UIColor
            let normalFont = normalAttributes[NSFontAttributeName] as! UIFont
            
            expect(normalTextColor).to(equal(UIColor.purpleColor()))
            expect(normalFont).to(equal(UIFont.systemFontOfSize(123)))
            
            let selectedAttributes = self.subject.tabBarItem.titleTextAttributesForState(UIControlState.Selected)
            
            let selectedTextColor = selectedAttributes[NSForegroundColorAttributeName] as! UIColor
            let selectedFont = selectedAttributes[NSFontAttributeName] as! UIFont
            
            expect(selectedTextColor).to(equal(UIColor.purpleColor()))
            expect(selectedFont).to(equal(UIFont.systemFontOfSize(123)))
        }
        
        describe("when the controller appears") {
            beforeEach {
                self.subject.view.layoutIfNeeded()
                self.subject.viewWillAppear(false)
            }
            
            it("has an empty table") {
                expect(self.subject.tableView.numberOfSections()).to(equal(1))
                expect(self.subject.tableView.numberOfRowsInSection(0)).to(equal(0))
            }
            
            it("asks the issue repository for some news") {
                expect(self.issueRepository.fetchIssuesCalled).to(beTrue())
            }
            
            
            describe("when the issue repository returns some issues") {
                beforeEach {
                    var issueA = Issue(title: "Big Money in Little DC", body: "body", imageURL: NSURL())
                    var issueB = Issue(title: "Long Live The NHS", body: "body", imageURL: NSURL())
                    
                    self.issueRepository.lastCompletionBlock!([issueA, issueB])
                }
                
                it("shows the issues in the table") {
                    expect(self.subject.tableView.numberOfRowsInSection(0)).to(equal(2))
                    
                    var cellA = self.subject.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! IssueTableViewCell
                    expect(cellA.titleLabel.text).to(equal("Big Money in Little DC"))
                    
                    var cellB = self.subject.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! IssueTableViewCell
                    expect(cellB.titleLabel.text).to(equal("Long Live The NHS"))
                }
                
                it("styles the items in the table") {
                    var cell = self.subject.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! IssueTableViewCell
                    
                    expect(cell.titleLabel.textColor).to(equal(UIColor.magentaColor()))
                    expect(cell.titleLabel.font).to(equal(UIFont.boldSystemFontOfSize(20)))                 
                }
            }
        }
        
        describe("Tapping on an issue") {
            let expectedIssue = Issue(title: "expected", body: "body", imageURL: NSURL())
            
            beforeEach {
                self.subject.view.layoutIfNeeded()
                self.subject.viewWillAppear(false)
                var otherIssue = Issue(title: "unexpected", body: "body", imageURL: NSURL())
                
                var issues = [otherIssue, expectedIssue]
                
                self.issueRepository.lastCompletionBlock!(issues)
            }
            
            it("should push a correctly configured issue controller onto the nav stack") {
                let tableView = self.subject.tableView
                tableView.delegate!.tableView!(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
                
                expect(self.issueControllerProvider.lastIssue).to(beIdenticalTo(expectedIssue))
                
                // TODO: bring in PCK so we can test the line below
//                expect(self.subject.navigationController!.topViewController).to(beIdenticalTo(self.issueControllerProvider.controller))
            }
        }

    }
}