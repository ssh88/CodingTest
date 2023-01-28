import UIKit

/**
 Part A
 Write a framework to be used by a bowling alley.  The framework will provide a public interface to:* Input how many pins were knocked down, called each time a ball is thrown.* Retrieve the current score, to be called at any time.  Please follow what you consider to be best practices during development.  Bowling Rules A  A game of bowling consists of ten frames.  In each frame, the bowler will have two chances to knock down as many pins as possible with their bowling ball (maximum of ten).  Example frames:  Frame 1: Roll knocks down 9 pins, followed by 0Frame 2: Roll knocks down 2 pins, followed by 4Frame 3: Roll knocks down 5 pins, followed by 1Total score: 21
 
 Part B
 Bowling Rules B  If the bowler is able to knock down all 10 pins with the two balls of a frame, it is known as a Spare.  A player achieving a spare is awarded ten points, plus a bonus of whatever is scored with the next ball thrown.  Example frames:  Frame 1: Roll knocks down 7 pins, followed by 3Frame 2: Roll knocks down 4 pins, followed by 2  Score calculation:  Frame 1: 7 + 3 + bonus of 4 = 14Frame 2: 4 + 2 = 6  Total score: 20  N.B. The bonus is awarded to the preceding frame containing the spare
 */

/**
 NOTE: Hitting run on the last line of this playground willl run the test suite
 
 */

// MARK: Public Game Interface

protocol GameProvider {
    var score: Int { get }
    func pinsKnockedDown(_ pins: Int)
}

class Game: GameProvider {
    
    private let totalPins = 10
    private var frames = [Frame]()
    
    var score: Int {
        frames.map { $0.pinsKnocked + $0.bonus }.reduce(0, +)
    }
    
    private var currentFrame: Frame {
        if let frame = frames.last, !frame.completed {
            return frame
        } else {
            let frame = Frame()
            frames.append(frame)
            return frame
        }
    }
    
    private var previousFrame: Frame? {
        guard frames.count > 1 else { return nil }
        let frame = frames[frames.count - 2]
        return frame
    }
    
    // check if bonus should be applied to previous frame
    private func applyBonusIfNeeded(for currentFrame: Frame, with pins: Int) {
        guard
            let previousFrame,
            currentFrame.turns.count == 1
        else { return }
        
        let previousFrameScore = previousFrame.turns.map { $0.pins }.reduce(0, +)
        let applyBonus = (previousFrameScore == totalPins)
        if applyBonus {
            previousFrame.bonus += pins
        }
    }
    
    func pinsKnockedDown(_ pins: Int) {
        // update frame info
        let frame = currentFrame
        let turn = frame.currentTurn
        turn.pins = pins
        
        // next we apply bonus if needed
        applyBonusIfNeeded(for: frame, with: pins)
        
        // finally, skip to next frame if we hit a strike
        if pins == totalPins {
            let frame = Frame()
            frames.append(frame)
        }
    }
}

// MARK: - Models

class Frame {
    private(set) var turns = [Turn]()
    var bonus = 0
    
    var pinsKnocked: Int {
        turns.map { $0.pins }.reduce(0, +)
    }
    
    var completed: Bool {
        turns.count == 2
    }
    
    var currentTurn: Turn {
        let turn = Turn()
        turns.append(turn)
        return turn
    }
}

class Turn {
    var pins: Int = 0
}

// MARK: - Tests

import XCTest

// Setup
class TestObserver: NSObject, XCTestObservation {
    func testCase(_ testCase: XCTestCase,
                  didFailWithDescription description: String,
                  inFile filePath: String?,
                  atLine lineNumber: Int) {
        assertionFailure(description, line: UInt(lineNumber))
    }
}
let testObserver = TestObserver()
XCTestObservationCenter.shared.addTestObserver(testObserver)

class GameTests: XCTestCase {
    var sut: Game!

    override func setUp() {
        super.setUp()
        sut = Game()
    }

    override func tearDown()  {
        sut = nil
        super.tearDown()
    }
    
    /*
     Frame 1: Roll knocks down 9 pins, followed by 0
     Frame 2: Roll knocks down 2 pins, followed by 4
     Frame 3: Roll knocks down 5 pins, followed by 1
     Total score: 21
    */
    func testPinsKnockedDown_score_without_bonus() {
        sut.pinsKnockedDown(9)
        sut.pinsKnockedDown(0)
        
        sut.pinsKnockedDown(2)
        sut.pinsKnockedDown(4)
        
        sut.pinsKnockedDown(5)
        sut.pinsKnockedDown(1)
        
        let result = sut.score
        let expectation = 21
        
        XCTAssertEqual(result, expectation)
    }
    
    /*
     Frame 1: Roll knocks down 7 pins, followed by 3
     Frame 2: Roll knocks down 4 pins, followed by 2
     Score calculation:
        Frame 1: 7 + 3 + bonus of 4 = 14
        Frame 2: 4 + 2 = 6
     Total score: 20
     */
    func testPinsKnockedDown_score_with_spare_bonus() {
        sut.pinsKnockedDown(7)
        sut.pinsKnockedDown(3)
        
        sut.pinsKnockedDown(4)
        sut.pinsKnockedDown(2)
        
        let result = sut.score
        let expectation = 20
        
        XCTAssertEqual(result, expectation)
    }
    
    /*
     Tests when a strike happens in the first turn of a frame
     Frame 1: Stike, no second turn
     Frame 2: Roll knocks down 3 pins, followed by 4
     Score calculation:
        Frame 1: 10 + bonus of 3 = 13
        Frame 2: 3 + 4 = 7
     Total score: 20
     */
    func testPinsKnockedDown_score_with_strike_bonus() {
        // frame 1
        // strike, so will ski[ sceond turn
        sut.pinsKnockedDown(10)
        
        // frame 2
        sut.pinsKnockedDown(3)
        sut.pinsKnockedDown(4)
        
        //total 10 + 3 + 4 + bonus: 3
        
        let result = sut.score
        let expectation = 20
        
        XCTAssertEqual(result, expectation)
    }
}

class FrameTests: XCTestCase {
    var sut: Frame!

    override func setUp() {
        super.setUp()
        sut = Frame()
    }

    override func tearDown()  {
        sut = nil
        super.tearDown()
    }
    
    func testPinsKnocked() {
        let turn1 = sut.currentTurn
        turn1.pins = 5
        
        let turn2 = sut.currentTurn
        turn2.pins = 4
        
        let result = sut.pinsKnocked
        let expectation = 9
        
        XCTAssertEqual(result, expectation)
    }
    
    func testFrameCompleted() {
        let _ = sut.currentTurn
        XCTAssertFalse(sut.completed)
        
        let _ = sut.currentTurn
        XCTAssertTrue(sut.completed)
    }
}

GameTests.defaultTestSuite.run()
FrameTests.defaultTestSuite.run()
