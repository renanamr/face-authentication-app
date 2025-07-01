import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionCameraPage extends StatefulWidget {
  @override
  _FaceDetectionCameraPageState createState() =>
      _FaceDetectionCameraPageState();
}

class _FaceDetectionCameraPageState extends State<FaceDetectionCameraPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isDetecting = false;
  bool _isTakingPhoto = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final camera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {});

    _cameraController.startImageStream((CameraImage image) {
      if (!_isDetecting && !_isTakingPhoto) {
        _isDetecting = true;
        _processCameraImage(image);
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
      Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController.description;

      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final planeData = image.planes.map(
            (plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: inputImageData,
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        // Log dos ângulos
        print(
            "headEulerAngleY: ${face.headEulerAngleY}, headEulerAngleZ: ${face.headEulerAngleZ}");

        // Critério mais permissivo
        final bool isFacingForward =
            (face.headEulerAngleY ?? 0).abs() < 25 &&
                (face.headEulerAngleZ ?? 0).abs() < 25;

        if (isFacingForward) {
          _isTakingPhoto = true;
          await _capturePhoto();
        }
      }
    } catch (e) {
      print('Erro ao processar imagem: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _capturePhoto() async {
    try {
      await _cameraController.stopImageStream();
      final XFile file = await _cameraController.takePicture();

      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      print('Erro ao capturar foto: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_cameraController)),
          Positioned(
            top: 40,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Posicione seu rosto de frente",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
