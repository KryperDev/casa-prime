import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/data/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final int initialTab;
  const EditProfileScreen({super.key, this.initialTab = 0});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  final _cloudinary = CloudinaryService();
  final _nameCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.fetchCurrentUser();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = u?.displayName ?? '';
      _photoUrl = u?.photoUrl;
      _loading = false;
    });
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    try {
      setState(() => _uploading = true);
      final url = fromCamera
          ? await _cloudinary.takePhoto()
          : await _cloudinary.pickFromGallery();
      if (url == null) return;
      if (!mounted) return;
      setState(() => _photoUrl = url);
      await _auth.updateProfile(photoUrl: url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(fromCamera: false);
              },
            ),
            if (_photoUrl != null)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _auth.updateProfile(photoUrl: '');
                  if (mounted) {
                    setState(() => _photoUrl = null);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome muito curto.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _auth.updateProfile(displayName: _nameCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.erro(context, ErrorTranslator.translate(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFF1E88E5),
                  backgroundImage: (_photoUrl != null &&
                          _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? const Icon(Icons.person,
                          size: 56, color: Colors.white)
                      : null,
                ),
                if (_uploading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: const Color(0xFF1E88E5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploading ? null : _showPhotoOptions,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Nome de exibição',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Salvar alterações'),
              onPressed: _saving ? null : _saveName,
            ),
          ),
        ],
      ),
    );
  }
}

