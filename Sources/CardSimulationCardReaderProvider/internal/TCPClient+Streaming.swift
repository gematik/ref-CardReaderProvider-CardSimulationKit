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
import SwiftSocket

extension TCPClient: InputStreaming, OutputStreaming {
    var hasBytesAvailable: Bool {
        guard let availableBytes = bytesAvailable() else {
            return false
        }
        return availableBytes > 0
    }

    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard let availableBytes = bytesAvailable() else {
            return 0
        }
        do {
            let bufferSize = min(Int(availableBytes), len)
            let bytes = try self.read(bufferSize)
            buffer.assign(from: bytes, count: bytes.count)
            return bytes.count
        } catch let error {
            ALog("Read error: [\(error)]")
            return -1
        }
    }

    var hasSpaceAvailable: Bool {
        return self.fd != nil
    }

    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let data = Data(bytes: buffer, count: len)
        switch self.send(data: data) {
        case .failure: return -1
        case .success: return data.count
        }
    }

    func closeOutputStream() {
        self.close()
    }

    func closeInputStream() {
        self.close()
    }
}
