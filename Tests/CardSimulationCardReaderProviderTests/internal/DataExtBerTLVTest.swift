//
//  Copyright (c) 2019 gematik - Gesellschaft für Telematikanwendungen der Gesundheitskarte mbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import GemCommonsKit
import Nimble

@testable import CardSimulationCardReaderProvider
import XCTest

final class DataExtBerTLVTest: XCTestCase {

    func testBerTLV_encode() {
        let apdu = Data(bytes: [0x00, 0xA4, 0x02, 0x0C, 0x02, 0x2F, 0x01])
        let expected = Data(bytes: [0x80, 0x07, 0x00, 0xA4, 0x02, 0x0C, 0x02, 0x2F, 0x01])

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_7f() {
        let size = 0x7f
        let header = Data(bytes: [0x80, UInt8(size)])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_80() {
        let size = 0x80
        let header = Data(bytes: [0x80, 0x81, UInt8(size)])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_ff() {
        let size = 0xff
        let header = Data(bytes: [0x80, 0x81, UInt8(size)])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_100() {
        let size = 0x100
        let header = Data(bytes: [0x80, 0x82, 0x1, 0x0])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_ffff() {
        let size = 0xffff
        let header = Data(bytes: [0x80, 0x82, 0xff, 0xff])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_10000() {
        let size = 0x10000
        let header = Data(bytes: [0x80, 0x83, 0x1, 0x0, 0x0])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_ffffff() {
        let size = 0xffffff
        let header = Data(bytes: [0x80, 0x83, 0xff, 0xff, 0xff])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_1000000() {
        let size = 0x1000000
        let header = Data(bytes: [0x80, 0x84, 0x1, 0x0, 0x0, 0x0])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_encode_1020415() {
        let size = 0x1020415
        let header = Data(bytes: [0x80, 0x84, 0x1, 0x2, 0x4, 0x15])
        let apdu = Data(bytes: [UInt8](repeating: 0x11, count: size))
        let expected = header + apdu

        expect {
            try apdu.berTlvEncoded()
        }.to(equal(expected))
    }

    func testBerTLV_decode() {
        let berTlvAPDU = Data(bytes: [0x80, 0x07, 0x00, 0xA4, 0x02, 0x0C, 0x02, 0x2F, 0x01])
        let expected = Data(bytes: [0x00, 0xA4, 0x02, 0x0C, 0x02, 0x2F, 0x01])

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(expected))
    }

    func testBerTLV_decode_7f() {
        let apdu = [UInt8](repeating: 0x11, count: 0x7f)
        let berTlvAPDU = Data(bytes: ([0x80, 0x7f] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_80() {
        let apdu = [UInt8](repeating: 0x11, count: 0x80)
        let berTlvAPDU = Data(bytes: ([0x80, 0x81, 0x80] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_ff() {
        let apdu = [UInt8](repeating: 0x11, count: 0xff)
        let berTlvAPDU = Data(bytes: ([0x80, 0x81, 0xff] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_100() {
        let apdu = [UInt8](repeating: 0x11, count: 0x100)
        let berTlvAPDU = Data(bytes: ([0x80, 0x82, 0x1, 0x0] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_ffff() {
        let apdu = [UInt8](repeating: 0x11, count: 0xffff)
        let berTlvAPDU = Data(bytes: ([0x80, 0x82, 0xff, 0xff] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_10000() {
        let apdu = [UInt8](repeating: 0x11, count: 0x10000)
        let berTlvAPDU = Data(bytes: ([0x80, 0x83, 0x1, 0x0, 0x0] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_ffffff() {
        let apdu = [UInt8](repeating: 0x11, count: 0xffffff)
        let berTlvAPDU = Data(bytes: ([0x80, 0x83, 0xff, 0xff, 0xff] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_1000000() {
        let apdu = [UInt8](repeating: 0x11, count: 0x1000000)
        let berTlvAPDU = Data(bytes: ([0x80, 0x84, 0x1, 0x0, 0x0, 0x0] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    func testBerTLV_decode_1020415() {
        let apdu = [UInt8](repeating: 0x11, count: 0x1020415)
        let berTlvAPDU = Data(bytes: ([0x80, 0x84, 0x1, 0x2, 0x4, 0x15] + apdu))

        expect {
            try berTlvAPDU.berTlvDecoded()
        }.to(equal(Data(bytes: apdu)))
    }

    static var allTests = [
        ("testBerTLV_encode", testBerTLV_encode),
        ("testBerTLV_encode_7f", testBerTLV_encode_7f),
        ("testBerTLV_encode_80", testBerTLV_encode_80),
        ("testBerTLV_encode_ff", testBerTLV_encode_ff),
        ("testBerTLV_encode_100", testBerTLV_encode_100),
        ("testBerTLV_encode_ffff", testBerTLV_encode_ffff),
        ("testBerTLV_encode_10000", testBerTLV_encode_10000),
        ("testBerTLV_encode_ffffff", testBerTLV_encode_ffffff),
        ("testBerTLV_encode_1000000", testBerTLV_encode_1000000),
        ("testBerTLV_encode_1020415", testBerTLV_encode_1020415),
        ("testBerTLV_decode_7f", testBerTLV_decode_7f),
        ("testBerTLV_decode_80", testBerTLV_decode_80),
        ("testBerTLV_decode_ff", testBerTLV_decode_ff),
        ("testBerTLV_decode_100", testBerTLV_decode_100),
        ("testBerTLV_decode_ffff", testBerTLV_decode_ffff),
        ("testBerTLV_decode_10000", testBerTLV_decode_10000),
        ("testBerTLV_decode_ffffff", testBerTLV_decode_ffffff),
        ("testBerTLV_decode_1000000", testBerTLV_decode_1000000),
        ("testBerTLV_decode_1020415", testBerTLV_decode_1020415)
    ]
}
