//
//  ClueNode.swift
//  What's It
//
//  Created by Prabhunes on 8/11/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import Foundation

class ClueNode: GuessNode {

    var answer = ""

    init(name: String, answer: String) {
        self.answer = answer

        super.init(name: name)
    }
}
