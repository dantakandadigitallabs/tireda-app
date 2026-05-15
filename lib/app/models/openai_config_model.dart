class OpenAiConfigModel {
  String? apiKey;
  String? model;
  bool? enabled;
  String? prompt;

  OpenAiConfigModel({this.apiKey, this.model, this.enabled, this.prompt});

  OpenAiConfigModel.fromJson(Map<String, dynamic> json) {
    apiKey = json['apiKey'] ?? '';
    model = json['model'] ?? 'gpt-4o-mini';
    enabled = json['enabled'] ?? false;
    prompt = json['prompt'] ?? '';
  }

  bool get isUsable => (enabled ?? false) && (apiKey?.isNotEmpty ?? false);
}
