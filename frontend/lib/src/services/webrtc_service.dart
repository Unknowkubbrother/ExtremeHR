import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _hasRemoteDescription = false;

  final SignalingService signalingService;

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;

  WebRTCService(this.signalingService);

  Future<void> _configureAppleAudioSession() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await Helper.setAppleAudioIOMode(
        AppleAudioIOMode.localAndRemote,
        preferSpeakerOutput: true,
      );
      await Helper.ensureAudioSession();
    } catch (e) {
      if (kDebugMode) print('Error configuring iOS audio session: $e');
    }
  }

  void _enableSpeakerphone() {
    Helper.setSpeakerphoneOn(true);
  }

  Future<void> initLocalStream() async {
    await _configureAppleAudioSession();

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
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = true;
      }
      _enableSpeakerphone();
      onLocalStream?.call(_localStream!);
    }
  }

  Future<void> initPeerConnection(String roomId, String userId) async {
    await _disposePeerConnection();
    await _createPeerConnection(roomId, userId);
  }

  Future<void> restartPeerConnection(String roomId, String userId) async {
    await initPeerConnection(roomId, userId);
  }

  Future<void> _createPeerConnection(String roomId, String userId) async {
    _pendingIceCandidates.clear();
    _hasRemoteDescription = false;

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

        for (final track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
        }
        for (final track in _remoteStream!.getVideoTracks()) {
          track.enabled = true;
        }

        _enableSpeakerphone();
        onRemoteStream?.call(_remoteStream!);
      }
    };
  }

  Future<void> _disposePeerConnection() async {
    _pendingIceCandidates.clear();
    _hasRemoteDescription = false;

    final peerConnection = _peerConnection;
    final remoteStream = _remoteStream;
    _peerConnection = null;
    _remoteStream = null;

    if (peerConnection != null) {
      try {
        await peerConnection.close();
      } catch (e) {
        if (kDebugMode) print('Error closing peer connection: $e');
      }

      try {
        await peerConnection.dispose();
      } catch (e) {
        if (kDebugMode) print('Error disposing peer connection: $e');
      }
    }

    if (remoteStream != null) {
      for (final track in remoteStream.getTracks()) {
        try {
          track.stop();
        } catch (e) {
          if (kDebugMode) print('Error stopping remote track: $e');
        }
      }

      try {
        await remoteStream.dispose();
      } catch (e) {
        if (kDebugMode) print('Error disposing remote stream: $e');
      }
    }
  }

  Future<void> createOffer(
    String roomId,
    String userId, {
    bool iceRestart = false,
  }) async {
    if (_peerConnection == null) return;

    try {
      await _configureAppleAudioSession();
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
        'iceRestart': iceRestart,
      });
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
      await _configureAppleAudioSession();
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
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
      _hasRemoteDescription = true;
      await _flushPendingIceCandidates();
    } catch (e) {
      if (kDebugMode) print('Error setting remote description: $e');
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    if (_peerConnection == null || !_hasRemoteDescription) return;

    for (final candidate in List<RTCIceCandidate>.from(_pendingIceCandidates)) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        if (kDebugMode) print('Error flushing ICE candidate: $e');
      }
    }
    _pendingIceCandidates.clear();
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (!_hasRemoteDescription) {
        _pendingIceCandidates.add(candidate);
        return;
      }

      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      if (kDebugMode) print('Error adding ICE candidate: $e');
    }
  }

  void toggleMicrophone(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }

      _enableSpeakerphone();
    }
  }

  void toggleCamera(bool isVideoOff) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = !isVideoOff;
      }
    }
  }

  void dispose() {
    final localStream = _localStream;
    _localStream = null;
    if (localStream != null) {
      localStream.getTracks().forEach((track) => track.stop());
      unawaited(localStream.dispose());
    }
    unawaited(_disposePeerConnection());
  }
}
