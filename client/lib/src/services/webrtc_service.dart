import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final SignalingService signalingService;

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;

  WebRTCService(this.signalingService);

  Future<void> initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
    } catch (e) {
      if (kDebugMode) print('Error getting user media with video: $e');
      // Fallback for iOS Simulator or devices with no camera
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
      } catch (e2) {
        if (kDebugMode) print('Error getting user media audio only: $e2');
      }
    }

    if (_localStream != null) {
      onLocalStream?.call(_localStream!);
    }
  }

  Future<void> initPeerConnection(String roomId, String userId) async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(
      configuration,
      <String, dynamic>{},
    );

    // Add local tracks to peer connection
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signalingService.sendMessage({
        'type': 'webrtc_ice',
        'room_id': roomId,
        'sender_id': userId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];

        // Ensure remote audio tracks are explicitly enabled just in case
        for (var track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
        }

        onRemoteStream?.call(_remoteStream!);
      }
    };
  }

  Future<void> createOffer(String roomId, String userId) async {
    if (_peerConnection == null) return;

    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      signalingService.sendMessage({
        'type': 'webrtc_sdp',
        'room_id': roomId,
        'sender_id': userId,
        'sdp_type': offer.type,
        'sdp': offer.sdp,
      });
    } catch (e) {
      if (kDebugMode) print('Error creating offer: $e');
    }
  }

  Future<void> createAnswer(String roomId, String userId) async {
    if (_peerConnection == null) return;

    try {
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      signalingService.sendMessage({
        'type': 'webrtc_sdp',
        'room_id': roomId,
        'sender_id': userId,
        'sdp_type': answer.type,
        'sdp': answer.sdp,
      });
    } catch (e) {
      if (kDebugMode) print('Error creating answer: $e');
    }
  }

  Future<void> handleRemoteDescription(String type, String sdp) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, type),
      );
    } catch (e) {
      if (kDebugMode) print('Error setting remote description: $e');
    }
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) return;

    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      if (kDebugMode) print('Error adding ICE candidate: $e');
    }
  }

  void toggleMicrophone(bool isMuted) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }

      Helper.setSpeakerphoneOn(true);
    }
  }

  void toggleCamera(bool isVideoOff) {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !isVideoOff;
      }
    }
  }

  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
  }
}
