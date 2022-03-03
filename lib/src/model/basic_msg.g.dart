// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BasicMsg _$$_BasicMsgFromJson(Map<String, dynamic> json) => _$_BasicMsg(
      msg: json['msg'] as String?,
      timestamp: (json['timestamp'] as num?)?.toDouble(),
      msgLen: json['msg_len'] as int?,
    );

Map<String, dynamic> _$$_BasicMsgToJson(_$_BasicMsg instance) =>
    <String, dynamic>{
      'msg': instance.msg,
      'timestamp': instance.timestamp,
      'msg_len': instance.msgLen,
    };
