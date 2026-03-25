import Foundation
import Network

struct PhoneSpotterPairingPayload: Equatable, Sendable {
    let deviceName: String
    let phoneNumber: String
    let platform: PhonePlatform
    let integrationMode: IntegrationMode
}

final class PhoneSpotterPairingServer: @unchecked Sendable {
    enum Event: Sendable {
        case ready(url: String)
        case paired(PhoneSpotterPairingPayload)
        case failed(String)
    }

    private let pairingCode: String
    private let queue = DispatchQueue(label: "PhoneSpotterPairingServer")
    private let onEvent: @Sendable (Event) -> Void
    private var listener: NWListener?

    init(pairingCode: String, onEvent: @escaping @Sendable (Event) -> Void) {
        self.pairingCode = pairingCode
        self.onEvent = onEvent
    }

    func start() {
        stop()

        do {
            let listener = try NWListener(using: .tcp, on: .any)
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    let port = listener.port?.rawValue ?? 0
                    guard let ip = Self.localIPAddress() else {
                        self.onEvent(.failed("Could not determine this Mac's local IP for pairing."))
                        return
                    }
                    self.onEvent(.ready(url: "http://\(ip):\(port)/pair/\(self.pairingCode)"))
                case .failed(let error):
                    self.onEvent(.failed("Pairing server failed: \(error.localizedDescription)"))
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection: connection)
            }
            self.listener = listener
            listener.start(queue: queue)
        } catch {
            onEvent(.failed("Could not start the pairing server: \(error.localizedDescription)"))
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self else { return }
            if let error {
                self.respond(connection: connection, body: "Connection error: \(error.localizedDescription)", status: "500 Internal Server Error")
                return
            }

            guard let data, let request = String(data: data, encoding: .utf8) else {
                self.respond(connection: connection, body: "Bad request", status: "400 Bad Request")
                return
            }

            let firstLine = request.components(separatedBy: "\r\n").first ?? ""
            let parts = firstLine.split(separator: " ")
            guard parts.count >= 2 else {
                self.respond(connection: connection, body: "Bad request", status: "400 Bad Request")
                return
            }

            let method = String(parts[0])
            let path = String(parts[1])

            guard path == "/pair/\(self.pairingCode)" else {
                self.respond(connection: connection, body: "Pairing link not found.", status: "404 Not Found")
                return
            }

            if method == "GET" {
                self.respond(connection: connection, body: self.pairingPage(), contentType: "text/html; charset=utf-8")
                return
            }

            if method == "POST" {
                let body = request.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
                guard let payload = self.parsePayload(from: body) else {
                    self.respond(connection: connection, body: self.failurePage("The phone details were incomplete. Try scanning the QR code again."), contentType: "text/html; charset=utf-8")
                    return
                }

                self.onEvent(.paired(payload))
                self.respond(connection: connection, body: self.successPage(for: payload.deviceName), contentType: "text/html; charset=utf-8")
                return
            }

            self.respond(connection: connection, body: "Unsupported method.", status: "405 Method Not Allowed")
        }
    }

    private func respond(connection: NWConnection, body: String, status: String = "200 OK", contentType: String = "text/plain; charset=utf-8") {
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func parsePayload(from body: String) -> PhoneSpotterPairingPayload? {
        let fields = body
            .split(separator: "&")
            .reduce(into: [String: String]()) { partial, item in
                let pieces = item.split(separator: "=", maxSplits: 1).map(String.init)
                guard let key = pieces.first else { return }
                let value = pieces.count > 1 ? pieces[1] : ""
                partial[key] = Self.decodeFormValue(value)
            }

        let rawName = fields["device_name"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawNumber = fields["phone_number"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawPlatform = fields["platform"] ?? PhonePlatform.iphone.rawValue
        let rawMode = fields["integration_mode"] ?? IntegrationMode.nativeApp.rawValue

        guard !rawName.isEmpty, !rawNumber.isEmpty else { return nil }
        let platform = PhonePlatform(rawValue: rawPlatform) ?? .iphone
        let mode = IntegrationMode(rawValue: rawMode) ?? (platform == .iphone ? .nativeApp : .webPortal)

        return PhoneSpotterPairingPayload(
            deviceName: rawName,
            phoneNumber: rawNumber,
            platform: platform,
            integrationMode: mode
        )
    }

    private func pairingPage() -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Pair With Phone Spotter</title>
          <style>
            :root { color-scheme: dark; }
            body {
              margin: 0;
              min-height: 100vh;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
              background: linear-gradient(180deg, #0a1118, #101b27);
              color: #f4f7fb;
              display: grid;
              place-items: center;
              padding: 20px;
            }
            .card {
              width: min(100%, 420px);
              background: rgba(17, 28, 40, 0.92);
              border: 1px solid rgba(255,255,255,0.08);
              border-radius: 24px;
              padding: 24px;
              box-shadow: 0 24px 60px rgba(0,0,0,0.35);
            }
            h1 { margin: 0 0 10px; font-size: 28px; }
            p { color: #a8b4c3; line-height: 1.5; }
            label { display: block; font-size: 13px; margin: 14px 0 6px; color: #c7d2dd; }
            input, select, button {
              width: 100%;
              border-radius: 14px;
              border: 1px solid rgba(255,255,255,0.10);
              background: rgba(255,255,255,0.05);
              color: white;
              padding: 14px 15px;
              font-size: 16px;
              box-sizing: border-box;
            }
            button {
              margin-top: 18px;
              border: none;
              background: linear-gradient(135deg, #2c8fff, #27c7d9);
              font-weight: 700;
            }
          </style>
        </head>
        <body>
          <form class="card" method="post" action="/pair/\(pairingCode)">
            <h1>Pair Your Phone</h1>
            <p>Send your phone details to Phone Spotter on this Mac so it can act as your control hub.</p>
            <label>Phone name</label>
            <input name="device_name" placeholder="Arnav's iPhone" required>
            <label>Phone number</label>
            <input name="phone_number" placeholder="+65 8749 1252" required>
            <label>Platform</label>
            <select name="platform">
              <option value="iphone">iPhone</option>
              <option value="android">Android</option>
            </select>
            <label>Integration mode</label>
            <select name="integration_mode">
              <option value="nativeApp">Native App</option>
              <option value="webPortal">Web Portal</option>
              <option value="guidedCompanion">Companion Ready</option>
            </select>
            <button type="submit">Pair With This Mac</button>
          </form>
        </body>
        </html>
        """
    }

    private func successPage(for deviceName: String) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Paired</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #0c1520; color: white; display: grid; place-items: center; min-height: 100vh; margin: 0; padding: 20px; }
            .card { max-width: 420px; background: rgba(16, 28, 40, 0.94); border: 1px solid rgba(255,255,255,0.08); border-radius: 24px; padding: 28px; text-align: center; }
            h1 { margin: 0 0 8px; }
            p { color: #a8b4c3; line-height: 1.5; }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>\(Self.escapeHTML(deviceName)) paired</h1>
            <p>You can go back to your Mac now. Phone Spotter has your phone profile and can use it for call, locate, and provider actions.</p>
          </div>
        </body>
        </html>
        """
    }

    private func failurePage(_ message: String) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Pairing Error</title></head>
        <body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#101820;color:white;display:grid;place-items:center;min-height:100vh;margin:0;padding:20px;">
          <div style="max-width:420px;background:rgba(24,31,41,0.96);border:1px solid rgba(255,255,255,0.08);border-radius:20px;padding:24px;">
            <h1 style="margin-top:0;">Pairing failed</h1>
            <p style="color:#b6c2cf;line-height:1.5;">\(Self.escapeHTML(message))</p>
          </div>
        </body>
        </html>
        """
    }

    private static func decodeFormValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding ?? value
    }

    private static func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func localIPAddress() -> String? {
        var address: String?
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPointer) == 0, let first = ifaddrPointer else {
            return nil
        }

        defer { freeifaddrs(ifaddrPointer) }

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard let interfaceAddress = interface.ifa_addr else { continue }
            let family = interfaceAddress.pointee.sa_family
            guard family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name != "lo0" else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interfaceAddress,
                socklen_t(interfaceAddress.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            let candidate = String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            if candidate.hasPrefix("192.168.") || candidate.hasPrefix("10.") || candidate.hasPrefix("172.") {
                address = candidate
                break
            }
            if address == nil {
                address = candidate
            }
        }

        return address
    }
}
