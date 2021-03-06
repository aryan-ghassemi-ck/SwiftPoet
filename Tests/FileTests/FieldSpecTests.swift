//
//  FieldSpecTests.swift
//  SwiftPoet
//
//  Created by Kyle Dorman on 8/1/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

import XCTest
import SwiftPoet

class FieldSpecTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testComputedIntProperty() {
        /*
         var hashValue: Int {
         return x.hashValue ^ y.hashValue &* 16777619
         }
         */
        let field = FieldSpec.builder(for: "hashValue", type: TypeName.IntegerType, construct: .mutableParam)
            .add(initializer: CodeBlock.builder()
                .add(literal: "return x.hashValue ^ y.hashValue &* 16777619")
                .build())
            // adding the parent is done automatically when a field is added to an enum, struct, and class.
            .add(parentType: .`enum`)
            .build()

        let result = """
var hashValue: Int {
    return x.hashValue ^ y.hashValue &* 16777619
}
"""

        XCTAssertEqual(result, field.toString())
    }

    func testConstantProperty() {
        /*
        let urlString: String = "https://www.gilt.com"
         */
        let field = FieldSpec.builder(for: "urlString", type: TypeName.StringType, construct: .field)
                .add(initializer: CodeBlock.builder()
                        .add(literal: "\"https://www.gilt.com\"")
                        .build())
                .add(parentType: .`class`)
                .build()

        let result = """
let urlString: String = "https://www.gilt.com"
"""

        XCTAssertEqual(result, field.toString())
    }

    func testComputedLongProperty() {
        /*
         var hashValue: Int64 {
         return x.hashValue ^ y.hashValue &* 16777619
         }
         */
        let field = FieldSpec.builder(for: "hashValue", type: TypeName.LongType, construct: .mutableParam)
            .add(initializer: CodeBlock.builder()
                .add(literal: "return x.hashValue ^ y.hashValue &* 16777619")
                .build())
            // adding the parent is done automatically when a field is added to an enum, struct, and class.
            .add(parentType: .`enum`)
            .build()

        let result = """
var hashValue: Int64 {
    return x.hashValue ^ y.hashValue &* 16777619
}
"""

        XCTAssertEqual(result, field.toString())
    }
}

