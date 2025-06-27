import 'package:flutter/services.dart';
import 'package:flutter_face_api/flutter_face_api.dart';

class FaceAuthenticatorService{
  final faceSdk = FaceSDK.instance;

  Future<bool> initialize() async {
    var license = await loadAssetIfExists("assets/regula.license");
    InitConfig? config;
    if (license != null) config = InitConfig(license);

    var (success, error) = await faceSdk.initialize(config: config);

    if (!success) {
      print("${error!.code}: ${error.message}");
    }
    return success;
  }

  Future<ByteData?> loadAssetIfExists(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  Future<bool> matchFaces({
    required Uint8List imageBytesCurrent,
    required Uint8List imageBytesTest,
  }) async {
    final imageCurrent = MatchFacesImage(imageBytesCurrent, ImageType.PRINTED);
    final imageTest = MatchFacesImage(imageBytesTest, ImageType.PRINTED);

    final request = MatchFacesRequest([imageCurrent, imageTest]);
    final response = await faceSdk.matchFaces(request);

    final split = await faceSdk.splitComparedFaces(response.results, 0.75);
    final match = split.matchedFaces;


    if (match.isNotEmpty) {
      final similarityStatus = "${(match[0].similarity * 100).toStringAsFixed(2)}%";
      print(similarityStatus);
      return match[0].similarity >= 0.9;
    }
    return false;
  }

}