// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionAnswerKey _$QuestionAnswerKeyFromJson(Map<String, dynamic> json) =>
    QuestionAnswerKey(
      json['question'] as String,
      answerKey: json['answerKey'] as String?,
    );

Map<String, dynamic> _$QuestionAnswerKeyToJson(QuestionAnswerKey instance) =>
    <String, dynamic>{
      'question': instance.question,
      'answerKey': instance.answerKey,
    };
