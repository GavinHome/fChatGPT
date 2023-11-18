import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../common/env.dart';

abstract class AbstractChart<T, P> {
  Future<P> fetchAnswer(T param);
}

class OpenAiChartRequest {
  final String id;
  final String question;
  OpenAiChartRequest({required this.id, required this.question});
}

class OpenAiChartResponse {
  final String id;
  final String answer;

  OpenAiChartResponse({required this.id, required this.answer});

  factory OpenAiChartResponse.fromJson(Map<String, dynamic> json) {
    return OpenAiChartResponse(
      id: json['id'],
      answer: json['answer'],
    );
  }
}

class OpenAiChart
    extends AbstractChart<OpenAiChartRequest, OpenAiChartResponse> {
  final bool isMock = false;

  @override
  Future<OpenAiChartResponse> fetchAnswer(OpenAiChartRequest param) {
    return _fetchAnswer(param);
  }

  Future<OpenAiChartResponse> _fetchAnswer(OpenAiChartRequest param) async {
    if (isMock) {
      await Future.delayed(const Duration(seconds: 5));
      return compute(
          (message) => OpenAiChartResponse(
              id: param.id,
              answer:
                  "我是一个语言模型，所以我的特长是自然语言处理，我可以回答你的问题，并为你提供有关各种主题的信息。我的知识非常广泛，所以我可以回答各种各样的问题，请尽情提问吧！"),
          '');
    }

    final String chatCompletionsApi = await EnvManager.env("OpenAIChartApi");
    final response = await http.post(
      Uri.parse(chatCompletionsApi),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id': param.id,
        'question': param.question,
      }),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, then parse the JSON.
      return compute(parseAnswer, response.body);
    } else {
      // If the server did not return a 200 OK response, then throw an exception.
      throw Exception('Failed to load albums');
    }
  }

  OpenAiChartResponse parseAnswer(String responseBody) {
    final parsed = Map<String, dynamic>.from(jsonDecode(responseBody));
    return OpenAiChartResponse.fromJson(parsed);
  }
}
