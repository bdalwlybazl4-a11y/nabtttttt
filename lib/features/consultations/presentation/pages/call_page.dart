import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatefulWidget {
  final String callID;
  final String doctorID;
  final String patientID;
  final bool isDoctor;
  final String userName;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.callID,
    required this.doctorID,
    required this.patientID,
    required this.isDoctor,
    required this.userName,
    this.isVideoCall = true,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late ZegoUIKitPrebuiltCallConfig _config;

  @override
  void initState() {
    super.initState();
    _setupCallConfig();
  }
  void _setupCallConfig() {
    _config = widget.isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    _config.turnOnCameraWhenJoining = widget.isVideoCall;
    _config.turnOnMicrophoneWhenJoining = true;
    _config.useSpeakerWhenJoining = true;

    _config.topMenuBarConfig.buttons = [
      ZegoMenuBarButtonName.switchCameraButton,
      ZegoMenuBarButtonName.toggleCameraButton,
    ];

    _config.bottomMenuBarConfig.buttons = [
      ZegoMenuBarButtonName.toggleMicrophoneButton,
      if (widget.isVideoCall) ZegoMenuBarButtonName.toggleCameraButton,
      ZegoMenuBarButtonName.hangUpButton,
      ZegoMenuBarButtonName.switchAudioOutputButton,
    ];
  }



  @override
  Widget build(BuildContext context) {

    final userID = widget.isDoctor ? widget.doctorID : widget.patientID;

    return WillPopScope(
      onWillPop: () async => false,
      child: ZegoUIKitPrebuiltCall(
        appID: 1335900570,
        appSign:
        '412035e8ee25f60dcc716b5ba608090d3d4f727320b08ccfc44e4f565867f1c3',
        userID: userID,
        userName: widget.userName,
        callID: widget.callID,
        config: _config,
      ),
    );
  }
}