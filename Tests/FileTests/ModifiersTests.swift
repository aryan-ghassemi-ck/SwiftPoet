//
//  ModifiersTests.swift
//  SwiftPoetTests
//
//  Created by Nikita Korchagin on 11/12/2018.
//  Copyright © 2018 Gilt Groupe. All rights reserved.
//

import XCTest
import SwiftPoet

class ModifiersTests: XCTestCase {

    func testPublicStaticMethodModifiers() {
        let method = MethodSpec.builder(for: "test")
            .add(modifier: .Static)
            .add(returnType: TypeName.StringType)
            .add(modifier: .Public)
            .build()

        let result =
            "public static func test() -> String {\n}"

        XCTAssertEqual(result, method.toString())
    }

    func testOverrideMethodModifiers() {
        let method = MethodSpec.builder(for: "test")
            .add(modifier: .Static)
            .add(modifier: .Public)
            .add(returnType: TypeName.StringType)
            .add(modifier: .Override)
            .build()

        let result =
        "public override static func test() -> String {\n}"

        XCTAssertEqual(result, method.toString())
    }

    func testInitMethodModifiers() {
        let method = MethodSpec.builder(for: "init")
            .add(modifier: .Required)
            .add(modifier: .Public)
            .add(modifier: .Convenience)
            .build()

        let result =
        "public required convenience init() {\n}"

        XCTAssertEqual(result, method.toString())
    }


}
