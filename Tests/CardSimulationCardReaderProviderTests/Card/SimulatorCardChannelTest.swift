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

import CardReaderProviderApi
@testable import CardSimulationCardReaderProvider
import Foundation
import GemCommonsKit
import Nimble
import XCTest

final class SimulatorCardChannelTest: XCTestCase {

    class MockSimulatorCard: CardType {
        var atr: ATR = Data.empty
        var `protocol`: CardProtocol = .t1

        func openBasicChannel() throws -> CardChannelType {
            throw CardError.illegalState("openBasicChannel() has not been implemented")
        }

        func openLogicChannel() throws -> CardChannelType {
            throw CardError.illegalState("openLogicChannel() has not been implemented")
        }

        func disconnect(reset: Bool) throws {}
    }

    class MockStreaming: InputStreaming, OutputStreaming {
        var closedInputStream = false
        var closedOutputStream = false

        var bytesWritten = [Data]()
        /// When bytes have written, unlock responses
        var availableBytes = [Data?]()
        var lastReadMessage: Int = 0

        var hasBytesAvailable: Bool {
            let writtenCount = bytesWritten.count
            guard !closedInputStream,
                  writtenCount > 0,
                  availableBytes.count >= writtenCount,
                  lastReadMessage < writtenCount,
                  availableBytes[writtenCount - 1] != nil else {
                return false
            }
            return true
        }

        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            guard hasBytesAvailable, let bytes = availableBytes[bytesWritten.count - 1] else {
                return 0
            }
            let count = Swift.min(bytes.count, len)

            bytes.withUnsafeBytes {
                buffer.assign(from: $0, count: count)
            }
            lastReadMessage += 1
            return count
        }

        var hasSpaceAvailable: Bool { return !closedOutputStream }

        func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
            let data = Data(bytes: buffer, count: len)
            bytesWritten.append(data)
            return data.count
        }

        func closeInputStream() {
            closedInputStream = true
        }

        func closeOutputStream() {
            closedOutputStream = true
        }
    }

    struct MockCommand: CommandType {
        private(set) var data: Data?
        // swiftlint:disable identifier_name
        private(set) var ne: Int?
        private(set) var nc: Int = 0
        private(set) var cla: UInt8 = 0
        private(set) var ins: UInt8 = 0
        private(set) var p1: UInt8 = 0
        private(set) var p2: UInt8 = 0
        // swiftlint:enable identifier_name
        private(set) var bytes: Data

        init(bytes: Data) {
            self.bytes = bytes
        }
    }

    func testTransmit() {
        let stream = MockStreaming()
        guard let responseData = try? Data(bytes: [0x90, 0x00]).berTlvEncoded() else {
            Nimble.fail("Failed to berTlv Encode responseData")
            return
        }
        stream.availableBytes.append(responseData)
        let cardChannel = SimulatorCardChannel(card: MockSimulatorCard(), input: stream, output: stream)

        let commandData = Data(bytes: [0x1, 0x2, 0x3, 0x4])
        let command: CommandType = MockCommand(bytes: commandData)
        do {
            let response = try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0)
            // Verify response has been decoded
            expect(response.sw).to(equal(APDU.Response.OK.sw))
            // Verify command has been ber TLV encoded and written to output stream
            let berTlvData = try commandData.berTlvEncoded()
            expect(berTlvData).to(equal(stream.bytesWritten[0]))
            // Close channel
            try cardChannel.close()
            expect(stream.closedInputStream).to(beTrue())
            expect(stream.closedOutputStream).to(beTrue())
        } catch let error {
            Nimble.fail("Transmit failed: [\(error)]")
        }
    }

    static var allTests = [
        ("testTransmit", testTransmit)
    ]
}
