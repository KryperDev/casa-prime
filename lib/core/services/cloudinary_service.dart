import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

/// Serviço de upload de imagens para o Cloudinary (unsigned preset).
class CloudinaryService {
  // ============================================================
  //  CONFIGURAÇÃO - preenchido com os dados do Casa Prime
  // ============================================================
  static const String cloudName = 'zibsgh8j';
  static const String uploadPreset = 'casa_prime_avatars';
  static const String folder = 'casa_prime/avatars';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  /// Abre a galeria e retorna a URL do Cloudinary, ou null se o usuário cancelar.
  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file == null) return null;
    return _upload(file);
  }

  /// Abre a câmera e retorna a URL do Cloudinary, ou null se cancelar.
  Future<String?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file == null) return null;
    return _upload(file);
  }

  Future<String> _upload(XFile file) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: folder,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }

  /// Verifica se o arquivo é uma imagem válida antes de subir.
  bool isImage(XFile? file) {
    if (file == null) return false;
    final lower = file.path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  // Utilidade para checar se arquivo existe
  bool fileExists(String path) => File(path).existsSync();
}
