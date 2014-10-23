//
//  FibonacciWord.swift
//  FibWordClock
//
//  Created by Jesse Levine on 8/22/14.
//  Copyright (c) 2014 jesselevine. All rights reserved.
//

import UIKit

/**
* A nested fractal representation of the Fibonacci Word (BABBABABBABBA... see http://en.wikipedia.org/wiki/Fibonacci_word ).

Each FibonacciWord instance has a letter property whose value is either B or A. Additionally, a FibonacciWord has 1 or 2 sub-words: .letterBSubword is a FibonnaciWord whose letter value is .B, and letterASubword is an optional-type FibonacciWord whose letter value is .A. You can drill down arbitrarily far, and the leaf node objects' letter values, when placed in sequential order, will always form an arbirarily long potion of the Fibonacci Word starting from its beginning.

|- - - - - - - -B- - - - - - - -| <-- rootWord has letter value .B
|- - - - -B- - - - -|- - -A- - -| <-- rootWord.subWords has count 2
|- - -B- - -|- -A- -|- - -B- - -| <-- for sub in rootWord.subWords { sub.subwords }
|- -B- -|-A-|- -B- -|- -B- -|-A-|
|-B-|-A-|-B-|-B-|-A-|-B-|-A-|-B-|

*/

class FibonacciWord {
    
    enum FibonacciLetter: Int {
        case A = 1
        case B = 0
    }
    
    var letter: FibonacciLetter
    var superword: FibonacciWord?
    var depth: Int = 0
    
    init(letter: FibonacciLetter, superword: FibonacciWord?) {
        self.letter = letter
        self.superword = superword
        if let uwSuperword = self.superword {
            indexPath = uwSuperword.indexPath
            let myIndex: Int = (self.letter == .B) ? 0 : 1
            indexPath.append(myIndex)
            self.depth = uwSuperword.depth + 1
        }
    }
    
    class func rootWord() -> FibonacciWord {
        return FibonacciWord(letter: .B, superword: nil)
    }
    
    lazy var letterBSubword: FibonacciWord = {
        let bSub = FibonacciWord(letter: .B, superword: self)
        return bSub
    }()
    
    lazy var letterASubword: FibonacciWord? = {
        var aSub: FibonacciWord?
        if self.letter == FibonacciLetter.B {
            aSub = FibonacciWord(letter: .A, superword: self)
        }
        return aSub
    }()
    
    lazy var subwords: [FibonacciWord] = {
        var subs = [self.letterBSubword]
        if let aSub = self.letterASubword { subs.append(aSub) }
        return subs
    }()
    
    /**
    * The sequence of indexes required to traverse the tree and arrive at self, starting from the root word. Beginning at rootWord (self.superword.superword.superword....rootWord), drill down into rootWord.subwords[indexPath[0]].subWords[indexPath[1]].subWords[indexPath[2]]... until the last entry in indexPath. The returned result == self.
    
        For example, if self.indexPath == [0, 0, 1, 0, 1], 
        then
        self == rootWord.subWords[0].subWords[0].subWords[1].subwords[0].subwords[1]
    
        Note that because no instance of FibonacciWord will ever have more than 2 subwords, the only possible values for a given entry in indexPath are 0 or 1.
    */
    let indexPath = [Int]()
    
    
    lazy var indexPathAsString: String = {
        return (self.indexPath as NSArray).componentsJoinedByString("")
    }()

    func subwordAtIndexPath(var indexPath: [Int]) -> FibonacciWord? {
        var subword: FibonacciWord? = self
        if let firstIndex = indexPath.first? {
            indexPath.removeAtIndex(0)
            subword = self[firstIndex]?.subwordAtIndexPath(indexPath)
        }
        return subword
    }
    
    
    /**
    * For convenience, an override of the subscript index syntax allows the following:
    
    let fibWord = FibonacciWord.rootWord()
    let firstSubword = fibWord[0] // <--- equivalent to fibWord.subwords[0] or fibWord.letterBSubword
    let secondSubword = fibWord[1] // <--- equivalent to fibWord.subwords[1] or fibword.letterASubword
    let someDeepSubword = fibWord[0][1][0][1]....[1] <--- may or may not exist. Some words wont have a subword at index 1.
    let anotherDeepSubword = fibWord[2] <--- definitely does not exist. Will return nil.
    
    */
    subscript(index: Int) -> FibonacciWord? {
        var subword: FibonacciWord?
        if index == 0 { subword = letterBSubword }
        else if index == 1 { subword = letterASubword }
        return subword
    }
    
    func letters(#depth: Int) -> [FibonacciLetter] {
        var letters = [FibonacciLetter]()
        if depth == 0 { letters = [self.letter] }
        else {
            letters = letterBSubword.letters(depth: depth - 1)
            if let uwA = letterASubword {
                letters += uwA.letters(depth: depth - 1)
            }
        }
        return letters
    }
    
    func subwords(#depth: Int) -> [FibonacciWord] {
        var words = [FibonacciWord]()
        if depth == 0 { words = [self] }
        else {
            words = letterBSubword.subwords(depth: depth - 1)
            if let uwA = letterASubword {
                words += uwA.subwords(depth: depth - 1)
            }
        }
        return words
    }
    
    lazy var next: FibonacciWord? = {
        var next: FibonacciWord?
        if let uwSuperword = self.superword {
            if self.letter == .B {
                if let uwA = uwSuperword.letterASubword {
                    next = uwA
                }
            }
            if next == nil {
                if let nextSuper = uwSuperword.next {
                    next = nextSuper.letterBSubword
                }
            }
        }
        return next
    }()
    
    lazy var previous: FibonacciWord? = {
        var prev: FibonacciWord?
        if let uwSuperword = self.superword {
            if self.letter == .A {
                prev = uwSuperword.letterBSubword
            }
            else {
                if let prevSuper = uwSuperword.previous {
                    if let prevA = prevSuper.letterASubword {
                        prev = prevA
                    }
                    else {
                        prev = prevSuper.letterBSubword
                    }
                }
            }
        }
        return prev
    }()
    
}



