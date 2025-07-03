import 'dart:io';

import 'package:face_authentication_app/src/alerts/alert_core.dart';
import 'package:face_authentication_app/src/entities/user_face.dart';
import 'package:face_authentication_app/src/pages/face_detection_camera_page.dart';
import 'package:face_authentication_app/src/pages/image_registration_sheet.dart';
import 'package:face_authentication_app/src/services/face_authenticator_service.dart';
import 'package:face_authentication_app/src/services/image_picker_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _imagePickerService = ImagePickerService();
  final _faceAuthenticatorService = FaceAuthenticatorService();

  final List<UserFace> _registeredUsers = [];
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
      await ImageRegistrationSheet.show(
        context: context,
        imageBytes: imageBytes,
        onConfirm: (name, bytes) {
          setState(() {
            _registeredUsers.add(UserFace(name: name, image: bytes));
          });
          alertMessage("Cadastro", "Imagem cadastrada com sucesso!", context);
        },
      );
    } else {
      alertMessage("Cadastro", "Nenhuma imagem foi capturada.", context);
    }
  }

  Future<void> _verifyImage() async {
    if (_registeredUsers.isEmpty) {
      alertMessage(
          "Verificação", 
          "Nenhuma imagem cadastrada para comparação.", 
          context
      );
      return;
    }

    setState(() => _isLoading = true);
    final resultPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceDetectionCameraPage(),
      ),
    );

    if (resultPath == null || resultPath is! String) {
      alertMessage("Verificação", "Nenhuma imagem foi capturada.", context);
      return;
    }

    String? foundMatchName;

    setState(() => _isLoading = true);
    final testImage = await File(resultPath).readAsBytes();

    for (final registeredUser in _registeredUsers) {
      final isMatch = await _faceAuthenticatorService.matchFaces(
        imageBytesCurrent: registeredUser.image,
        imageBytesTest: testImage,
      );

      if (isMatch) {
        foundMatchName = registeredUser.name;
        break;
      }
    }
    setState(() => _isLoading = false);

    if (foundMatchName != null) {
      alertMessage("Sucesso!", "Bem vindo $foundMatchName", context);
    } else {
      alertMessage("Resultado", "Usuário não reconhecido.", context);
    }
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
                
                Text("Imagens cadastradas: ${_registeredUsers.length}"),
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