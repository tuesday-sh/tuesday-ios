import Foundation
import zlib

public enum GzipDecoderError: Error, LocalizedError, Equatable {
    case emptyInput
    case initFailed(Int32)
    case inflateFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Cannot decompress empty gzip data."
        case .initFailed(let code):
            return "zlib inflateInit2 failed with status \(code)."
        case .inflateFailed(let code):
            return "zlib inflate failed with status \(code)."
        }
    }
}

/// Decompresses RFC 1952 gzip (or zlib) streams cleanly into memory using Darwin `libz`.
public enum GzipDecoder {
    private static let chunkSize = 65_536

    public static func decompress(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            throw GzipDecoderError.emptyInput
        }

        var stream = z_stream()
        // MAX_WBITS (15) + 32 enables automatic gzip/zlib header detection.
        let initStatus = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw GzipDecoderError.initFailed(initStatus)
        }
        defer {
            inflateEnd(&stream)
        }

        var output = Data(capacity: max(data.count * 3, chunkSize))
        var status: Int32 = Z_OK

        try data.withUnsafeBytes { (rawInputBuffer: UnsafeRawBufferPointer) in
            guard let baseAddress = rawInputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                throw GzipDecoderError.emptyInput
            }
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: baseAddress)
            stream.avail_in = uInt(data.count)

            var tempBuffer = [UInt8](repeating: 0, count: chunkSize)

            repeat {
                let producedCount: Int = tempBuffer.withUnsafeMutableBufferPointer { bufferPtr in
                    stream.next_out = bufferPtr.baseAddress
                    stream.avail_out = uInt(chunkSize)
                    status = zlib.inflate(&stream, Z_NO_FLUSH)
                    return chunkSize - Int(stream.avail_out)
                }

                if producedCount > 0 {
                    output.append(tempBuffer, count: producedCount)
                }
            } while status == Z_OK
        }

        guard status == Z_STREAM_END else {
            throw GzipDecoderError.inflateFailed(status)
        }

        return output
    }
}
