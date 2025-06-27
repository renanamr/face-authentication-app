import 'dart:typed_data';
import 'package:face_authentication_app/src/services/face_authenticator_service.dart';
import 'package:face_authentication_app/src/services/image_picker_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: FaceAuthScreen(),
  ));
}

class FaceAuthScreen extends StatefulWidget {
  const FaceAuthScreen({super.key});

  @override
  State<FaceAuthScreen> createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  final _imagePickerService = ImagePickerService();
  final _faceAuthenticatorService = FaceAuthenticatorService();

  final List<Uint8List> _registeredImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceSdk();
  }

  Future<void> _initializeFaceSdk() async {
    setState(() => _isLoading = true);
    await _faceAuthenticatorService.initialize();
    setState(() => _isLoading = false);
  }

  Future<void> _registerImage() async {
    setState(() => _isLoading = true);
    final imageBytes = await _imagePickerService.pickImageBytes();
    setState(() => _isLoading = false);

    if (imageBytes != null) {
      setState(() {
        _registeredImages.add(imageBytes);
      });
      _showDialog("Cadastro", "Imagem cadastrada com sucesso!");
    } else {
      _showDialog("Cadastro", "Nenhuma imagem foi capturada.");
    }
  }

  Future<void> _verifyImage() async {
    if (_registeredImages.isEmpty) {
      _showDialog("Verificação", "Nenhuma imagem cadastrada para comparação.");
      return;
    }

    setState(() => _isLoading = true);
    final testImage = await _imagePickerService.pickImageBytes();
    setState(() => _isLoading = false);

    if (testImage == null) {
      _showDialog("Verificação", "Nenhuma imagem foi capturada.");
      return;
    }

    bool foundMatch = false;

    setState(() => _isLoading = true);
    for (final registeredImage in _registeredImages) {
      final isMatch = await _faceAuthenticatorService.matchFaces(
        imageBytesCurrent: registeredImage,
        imageBytesTest: testImage,
      );

      if (isMatch) {
        foundMatch = true;
        break;
      }
    }
    setState(() => _isLoading = false);

    if (foundMatch) {
      _showDialog("Resultado", "Usuário reconhecido com sucesso!");
    } else {
      _showDialog("Resultado", "Usuário não reconhecido.");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reconhecimento Facial"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registerImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Cadastrar Imagem"),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifyImage,
                  icon: const Icon(Icons.verified_user),
                  label: const Text("Verificar Usuário"),
                ),
                const SizedBox(height: 24),
                Text("Imagens cadastradas: ${_registeredImages.length}"),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}