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
import Foundation
import GemCommonsKit

public class SimulatorCardChannel: CardChannelType {
    public enum SimulatorError: Swift.Error, Equatable {
        case outputStreamUnavailable
        case noResponse
        case invalidResponse
        case asn1coding(Swift.Error)
        case commandSizeTooLarge(maxSize: Int, length: Int)
        case responseSizeTooLarge(maxSize: Int, length: Int)

        public var connectionError: CardError {
            return CardError.connectionError(self)
        }

        public var illegalState: CardError {
            return CardError.illegalState(self)
        }

        public static func == (lhs: SimulatorError, rhs: SimulatorError) -> Bool {
            switch (lhs, rhs) {
            case (.outputStreamUnavailable, .outputStreamUnavailable): return true
            case (.noResponse, .noResponse): return true
            case (.asn1coding, .asn1coding): return true
            case (.commandSizeTooLarge(let lhsMax, let lhsSize), .commandSizeTooLarge(let rhsMax, let rhsSize)):
                return lhsMax == rhsMax && lhsSize == rhsSize
            case (.responseSizeTooLarge(let lhsMax, let lhsSize), .responseSizeTooLarge(let rhsMax, let rhsSize)):
                return lhsMax == rhsMax && lhsSize == rhsSize
            default:
                return false
            }
        }
    }

    public private(set) var card: CardType
    public private(set) var channelNumber: Int = 0
    public private(set) var extendedLengthSupported: Bool
    public private(set) var maxMessageLength: Int
    public private(set) var maxResponseLength: Int
    let inputStream: InputStreaming
    let outputStream: OutputStreaming

    init(card: CardType,
         input: InputStreaming,
         output: OutputStreaming,
         messageLength: Int,
         responseLength: Int,
         extendedLengthSupport: Bool = true
    ) {
        self.card = card
        inputStream = input
        outputStream = output
        maxMessageLength = messageLength
        maxResponseLength = responseLength
        extendedLengthSupported = extendedLengthSupport
    }

    /// Transmit a command and return the response
    /// - Parameters:
    ///     - command: the command gets berTlv encoded and send to the Kartensimulation
    /// - throws:
    ///     - SimulatorError.outputStreamUnavailable.illegalState when the stream has no space available to write
    /// - Returns: the berTlv decoded response APDU
    public func transmit(command: CommandType, writeTimeout: TimeInterval, readTimeout: TimeInterval) throws
                    -> ResponseType {
        guard outputStream.hasSpaceAvailable else {
            throw SimulatorError.outputStreamUnavailable.illegalState
        }
        guard command.bytes.count <= maxMessageLength else {
            throw SimulatorError.commandSizeTooLarge(maxSize: maxMessageLength, length: command.bytes.count)
                    .illegalState
        }
        let message = try command.bytes.berTlvEncoded()
        DLog("SEND:     \(message.map { String(format: "%02hhX", $0) }.joined())") // hexString
        _ = message.withUnsafeBytes {
            return outputStream.write($0, maxLength: message.count)
        }

        var buffer = [UInt8](repeating: 0x0, count: maxResponseLength)
        var responseData = Data()
        let timeoutTime = (readTimeout == 0) ? Date.distantFuture : Date(timeIntervalSinceNow: readTimeout)
        repeat {
            guard inputStream.hasBytesAvailable else {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
                continue
            }
            let readBytes = inputStream.read(&buffer, maxLength: maxResponseLength)
            guard readBytes != -1 else {
                throw SimulatorError.noResponse.connectionError
            }
            buffer.withContiguousStorageIfAvailable { bytes in
                // swiftlint:disable:next force_unwrapping
                responseData.append(bytes.baseAddress!, count: readBytes)
            }
        } while inputStream.hasBytesAvailable || (responseData.isEmpty && Date() < timeoutTime)

        guard !responseData.isEmpty else {
            ALog("Error when reading the response from the CardSimulator connection" +
                    " or there were no bytes available to be read.")
            throw SimulatorError.noResponse.connectionError
        }

        guard responseData.count <= maxResponseLength else {
            throw SimulatorError.responseSizeTooLarge(maxSize: maxResponseLength, length: responseData.count)
                    .illegalState
        }

        DLog("RESPONSE: \(responseData.map { String(format: "%02hhX", $0) }.joined())") // hexString
        return try APDU.Response(apdu: responseData.berTlvDecoded())
    }

    public func close() throws {
        inputStream.closeInputStream()
        outputStream.closeOutputStream()
    }
}
