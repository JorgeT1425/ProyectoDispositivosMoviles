import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarPerfilScreen extends StatefulWidget {
  static const name = 'editar_perfil_screen';

  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _programaController;
  late TextEditingController _semestreController;
  late TextEditingController _creditosController;
  XFile? imagenSeleccionada;
  bool _guardando = false;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: usuarioActual?['nombre'] ?? 'Santiago Bocanegra');
    _correoController = TextEditingController(text: usuarioActual?['correo'] ?? 'estudiante@universidad.edu.co');
    _programaController = TextEditingController(text: usuarioActual?['programa'] ?? 'Ingeniería de Sistemas');
    _semestreController = TextEditingController(text: (usuarioActual?['semestre_actual'] ?? '6').toString());
    _creditosController = TextEditingController(text: (usuarioActual?['creditos_programa'] ?? '160').toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _programaController.dispose();
    _semestreController.dispose();
    _creditosController.dispose();
    super.dispose();
  }

  // MÉTODO PARA SUBIR LA IMAGEN A SUPABASE STORAGE
  Future<String> _subirImagen() async {
    if (imagenSeleccionada == null) {
      throw Exception('No hay una imagen seleccionada.');
    }

    final String rutaLocal = imagenSeleccionada!.path;
    String extension = rutaLocal.split('.').last.toLowerCase();
    if (extension.isEmpty) {
      extension = 'jpg';
    }

    final String nombreArchivo =
        'perfil_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage
        .from('fotos-perfil')
        .upload(
          nombreArchivo,
          File(rutaLocal),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String urlPublica = supabase.storage
        .from('fotos-perfil')
        .getPublicUrl(nombreArchivo);

    return urlPublica;
  }

  Future<void> _guardarCambios() async {
    final int? idUsuario = usuarioActual?['id_usuario'];
    setState(() => _guardando = true);

    try {
      String? fotoUrl = usuarioActual?['foto_url'];

      // Si se seleccionó una nueva imagen, se sube a Supabase Storage
      if (imagenSeleccionada != null) {
        fotoUrl = await _subirImagen();
      }

      final Map<String, dynamic> datosActualizados = {
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'programa': _programaController.text.trim(),
        'semestre_actual': int.tryParse(_semestreController.text) ?? 1,
        'creditos_programa': int.tryParse(_creditosController.text) ?? 160,
        'foto_url': fotoUrl,
      };

      if (idUsuario != null) {
        await supabase.from('usuarios').update({
          'nombre': datosActualizados['nombre'],
          'correo': datosActualizados['correo'],
          'programa': datosActualizados['programa'],
          'semestre_actual': datosActualizados['semestre_actual'],
          'creditos_programa': datosActualizados['creditos_programa'],
          'foto_url': datosActualizados['foto_url'],
        }).eq('id_usuario', idUsuario);

        // Actualizamos la sesión en memoria para reflejarlo en toda la app
        if (usuarioActual != null) {
          usuarioActual!.addAll(datosActualizados);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> seleccionarImagen(ImageSource origen) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(
        source: origen,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (imagen == null || !mounted) {
        return;
      }

      setState(() {
        imagenSeleccionada = imagen;
        mensaje = 'Imagen seleccionada correctamente.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        mensaje = 'No fue posible seleccionar la imagen: $error';
      });
    }
  }

  ImageProvider? _obtenerImagen() {
    if (imagenSeleccionada != null) {
      return FileImage(File(imagenSeleccionada!.path));
    }
    final String? fotoUrl = usuarioActual?['foto_url'];
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? imagenProvider = _obtenerImagen();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFE8EEFA),
                backgroundImage: imagenProvider,
                child: imagenProvider == null
                    ? const Icon(Icons.person, size: 50, color: Color(0xFF3B54C8))
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFE8EEFA),
                      foregroundColor: const Color(0xFF3B54C8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Tomar foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFE8EEFA),
                      foregroundColor: const Color(0xFF3B54C8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _CustomTextField(
              label: 'Nombre completo',
              controller: _nombreController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            _CustomTextField(
              label: 'Correo institucional',
              controller: _correoController,
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            _CustomTextField(
              label: 'Programa académico',
              controller: _programaController,
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _CustomTextField(
                    label: 'Semestre actual',
                    controller: _semestreController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CustomTextField(
                    label: 'Créditos totales',
                    controller: _creditosController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C5389),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _guardando ? null : _guardarCambios,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  _guardando ? 'Guardando...' : 'Guardar cambios',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType keyboardType;

  const _CustomTextField({
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 22) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}