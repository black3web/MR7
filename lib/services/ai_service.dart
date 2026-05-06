class AiService {
  static List<Map<String, dynamic>> seedanceModels = [{'name': 'Default'}];
  Future<String> geminiChat(a, [b, c]) async => '';
  Future<String> deepSeekChat(a, b, {model, c}) async => '';
  Future<String> generateImageNano(a, [b, c]) async => '';
  Future<String> nanoBananaPro({prompt, uid, model, aspectRatio, a, b}) async => '';
  Future<String> seedanceGenerate({prompt, model, uid, a, b}) async => '';
  Future<String> generateVideoKilwa(a, [b, c]) async => '';
  Future<String> veoGenerate({prompt, uid, model, aspectRatio, a, b}) async => '';
  Future<dynamic> getServiceStates() async => {};
  Future<void> toggleService([a, b, c]) async {}
  static Future<String> sendMessage([a, b, c]) async => '';
}
