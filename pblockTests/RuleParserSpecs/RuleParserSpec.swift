import Quick
import Nimble
@testable import pblock

class RuleParserSpec : QuickSpec {
  override func spec() {
    describe("initialization") {
      it("should set the ruleText content") {
        let parser = RuleParser("sample text")
        expect(parser.ruleText).to(equal("sample text"))
      }
    }
  }
}