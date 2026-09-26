import Foundation
import MultipeerConnectivity
import Observation

/// Runs on the Duo: finds a nearby probe, invites it, and exposes its latest vector.
@Observable
final class HostPeerService: NSObject {
  enum Status: Equatable {
    case idle, searching, connected(String)
  }

  private(set) var status = Status.idle
  private(set) var latestPacket: ProbePacket?

  /// The probe vector while connected and tracking; nil otherwise.
  var latestVector: SIMD3<Double>? {
    guard case .connected = status, let latestPacket, latestPacket.quality != .unavailable else { return nil }
    return latestPacket.vector
  }

  @ObservationIgnored private let peer = MCPeerID(displayName: "Basis Duo")
  @ObservationIgnored private lazy var session: MCSession = {
    let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
    session.delegate = self
    return session
  }()
  @ObservationIgnored private lazy var browser: MCNearbyServiceBrowser = {
    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: PeerConfiguration.serviceType)
    browser.delegate = self
    return browser
  }()

  func start() {
    guard status == .idle else { return }
    status = .searching
    browser.startBrowsingForPeers()
  }

  func stop() {
    browser.stopBrowsingForPeers()
    session.disconnect()
    status = .idle
    latestPacket = nil
  }
}

extension HostPeerService: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
  }

  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    DispatchQueue.main.async { self.status = .idle }
  }
}

extension HostPeerService: MCSessionDelegate {
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    DispatchQueue.main.async {
      switch state {
      case .connected: self.status = .connected(peerID.displayName)
      case .notConnected:
        if case .connected(let name) = self.status, name == peerID.displayName {
          self.status = .searching
          self.latestPacket = nil
        }
      default: break
      }
    }
  }

  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let packet = try? JSONDecoder().decode(ProbePacket.self, from: data) else { return }
    DispatchQueue.main.async {
      if packet.timestamp >= (self.latestPacket?.timestamp ?? 0) {
        self.latestPacket = packet
      }
    }
  }

  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
