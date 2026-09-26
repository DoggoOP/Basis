import Foundation
import MultipeerConnectivity
import Observation
import UIKit

/// Runs on the probe iPhone: advertises itself and streams packets to the Duo.
@Observable
final class ProbePeerService: NSObject {
  private(set) var connectedHost: String?

  @ObservationIgnored private let peer = MCPeerID(displayName: UIDevice.current.name)
  @ObservationIgnored private lazy var session: MCSession = {
    let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
    session.delegate = self
    return session
  }()
  @ObservationIgnored private lazy var advertiser: MCNearbyServiceAdvertiser = {
    let advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: PeerConfiguration.serviceType)
    advertiser.delegate = self
    return advertiser
  }()
  @ObservationIgnored private var lastSent: TimeInterval = 0

  func start() { advertiser.startAdvertisingPeer() }

  func stop() {
    advertiser.stopAdvertisingPeer()
    session.disconnect()
    connectedHost = nil
  }

  /// Sends at most ~30 packets per second, unreliably: a dropped sample is replaced by the next.
  func send(_ packet: ProbePacket) {
    guard !session.connectedPeers.isEmpty,
          packet.timestamp - lastSent >= PeerConfiguration.packetInterval,
          let data = try? JSONEncoder().encode(packet)
    else { return }
    lastSent = packet.timestamp
    try? session.send(data, toPeers: session.connectedPeers, with: .unreliable)
  }
}

extension ProbePeerService: MCNearbyServiceAdvertiserDelegate {
  func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    invitationHandler(true, session)
  }
}

extension ProbePeerService: MCSessionDelegate {
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    DispatchQueue.main.async {
      switch state {
      case .connected: self.connectedHost = peerID.displayName
      case .notConnected: if self.connectedHost == peerID.displayName { self.connectedHost = nil }
      default: break
      }
    }
  }

  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
