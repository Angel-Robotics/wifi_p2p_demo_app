import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'basic_msg.freezed.dart';

part 'basic_msg.g.dart';

@freezed
class BasicMsg with _$BasicMsg {
  factory BasicMsg({
    @JsonKey(name: "msg") String? msg,
    @JsonKey(name: "timestamp") double? timestamp,
    @JsonKey(name: "msg_len") int? msgLen,
  }) = _BasicMsg;

  factory BasicMsg.fromJson(Map<String, dynamic> json) => _$BasicMsgFromJson(json);
}
