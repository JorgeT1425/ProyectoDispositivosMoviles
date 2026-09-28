import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';

class Login extends StatefulWidget {
  static const String name = 'login';

  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController semestreController = TextEditingController();
  final TextEditingController creditosController = TextEditingController();
  final TextEditingController programaController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  bool esModoLogin = true;
  bool ocultarPassword = true;
  bool guardando = false;

  XFile? imagenSeleccionada;
  String mensaje = '';

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    semestreController.dispose();
    creditosController.dispose();
    programaController.dispose();
    super.dispose();
  }

  Future<void> seleccionarImagen(ImageSource origen) async {
    try {
      final XFile? imagen = await imagePicker.pickImage(
        source: origen,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (imagen == null || !mounted) return;

      setState(() {
        imagenSeleccionada = imagen;
        mensaje = '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        mensaje = 'Error al seleccionar imagen: $error';
      });
    }
  }

  Future<String> subirImagen() async {
    if (imagenSeleccionada == null) throw Exception('No hay imagen');

    final String rutaLocal = imagenSeleccionada!.path;
    String extension = rutaLocal.split('.').last.toLowerCase();
    if (extension.isEmpty) extension = 'jpg';

    final String nombreArchivo =
        'usuario_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from('fotos-perfil').upload(
          nombreArchivo,
          File(rutaLocal),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return supabase.storage.from('fotos-perfil').getPublicUrl(nombreArchivo);
  }

  Future<void> procesarFormulario() async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return;

    if (esModoLogin) {
      await ejecutarLogin();
    } else {
      await ejecutarRegistro();
    }
  }

  Future<void> ejecutarLogin() async {
    setState(() {
      guardando = true;
      mensaje = '';
    });

    try {
      final usuario = await supabase
          .from('usuarios')
          .select('id_usuario, nombre, correo, programa, semestre_actual, creditos_programa, foto_url')
          .eq('correo', correoController.text.trim())
          .eq('contrasena', passwordController.text.trim())
          .maybeSingle();

      if (usuario == null) {
        if (!mounted) return;
        setState(() {
          mensaje = 'Correo o contraseña incorrectos.';
        });
        return;
      }

      usuarioActual = usuario;

      if (!mounted) return;

      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        mensaje = 'Error al iniciar sesión: $error';
      });
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  Future<void> ejecutarRegistro() async {
    setState(() {
      guardando = true;
      mensaje = '';
    });

    try {
      final duplicado = await supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('correo', correoController.text.trim())
          .maybeSingle();

      if (duplicado != null) {
        if (!mounted) return;
        setState(() => mensaje = 'El correo ya se encuentra registrado.');
        return;
      }

      String? fotoUrl;
      if (imagenSeleccionada != null) {
        fotoUrl = await subirImagen();
      }

      await supabase.from('usuarios').insert({
        'nombre': nombreController.text.trim(),
        'correo': correoController.text.trim(),
        'contrasena': passwordController.text.trim(),
        'programa': programaController.text.trim(),
        'semestre_actual': int.tryParse(semestreController.text) ?? 1,
        'creditos_programa': int.tryParse(creditosController.text) ?? 160,
        'foto_url': fotoUrl,
      });

      if (!mounted) return;

      final String correoRegistrado = correoController.text.trim();

      nombreController.clear();
      programaController.clear();
      passwordController.clear();
      semestreController.clear();
      creditosController.clear();

      setState(() {
        esModoLogin = true;
        imagenSeleccionada = null;
        correoController.text = correoRegistrado;
        mensaje = '¡Cuenta creada con éxito! Ingresa tu contraseña para entrar.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => mensaje = 'Error al registrar: $error');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color azulHeader = Color(0xFF4C5FD7);
    const Color azulBoton = Color(0xFF4252B5);
    const Color azulBotonOscuro = Color(0xFF4C5493);
    const Color grisFondo = Color(0xFFF7F8FA);
    const Color grisCampos = Color(0xFFF3F4F8);

    return Scaffold(
      backgroundColor: grisFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // --- TARJETA SUPERIOR AZUL ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: azulHeader,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TrayectoriaU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organiza tus semestres, calcula tus promedios y conoce el avance real de tu carrera.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Promedios',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Por créditos',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.show_chart, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Progreso',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Toda la carrera',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- CARD BLANCA DEL FORMULARIO ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esModoLogin ? 'Iniciar sesión' : 'Crear cuenta',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esModoLogin
                            ? 'Usa la cuenta de demostración para entrar.'
                            : 'Registra tus datos para comenzar.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // --- PESTAÑAS (SWITCH LOGIN / REGISTRARSE) ---
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: grisCampos,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => esModoLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: esModoLogin ? azulBoton : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login,
                                        size: 18,
                                        color: esModoLogin ? Colors.white : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          color: esModoLogin ? Colors.white : Colors.grey.shade700,
                                          fontWeight: esModoLogin ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => esModoLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !esModoLogin ? azulBoton : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt,
                                        size: 18,
                                        color: !esModoLogin ? Colors.white : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Registrarse',
                                        style: TextStyle(
                                          color: !esModoLogin ? Colors.white : Colors.grey.shade700,
                                          fontWeight: !esModoLogin ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CAMPOS DE REGISTRO
                      if (!esModoLogin) ...[
                        // Campo: Nombre completo
                        TextFormField(
                          controller: nombreController,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa tu nombre' : null,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F4F8),
                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade700, size: 20),
                            hintText: 'Nombre completo',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Campo: Programa académico
                        TextFormField(
                          controller: programaController,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa tu programa académico' : null,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F4F8),
                            prefixIcon: Icon(Icons.school_outlined, color: Colors.grey.shade700, size: 20),
                            labelText: 'Programa académico',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            hintText: 'Ingeniería de Sistemas',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Campos: Semestre y Créditos en Fila
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: semestreController,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingresa el semestre';
                                  }
                                  if (int.tryParse(val) == null) {
                                    return 'Solo números';
                                  }
                                  return null;
                                },
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F8),
                                  prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade700, size: 20),
                                  labelText: 'Semestre',
                                  labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  hintText: 'Semestre...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: creditosController,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Ingresa los créditos';
                                  }
                                  if (int.tryParse(val) == null) {
                                    return 'Solo números';
                                  }
                                  return null;
                                },
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F8),
                                  prefixIcon: Icon(Icons.workspace_premium_outlined, color: Colors.grey.shade700, size: 20),
                                  labelText: 'Créditos totales',
                                  labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  hintText: 'Créditos t...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // --- CAMPOS COMUNES ---
                      // Campo: Correo
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => val == null || !val.contains('@') ? 'Correo no válido' : null,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF3F4F8),
                          prefixIcon: Icon(Icons.alternate_email, color: Colors.grey.shade700, size: 20),
                          labelText: 'Correo institucional',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          hintText: 'estudiante@universidad.edu.co',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo: Contraseña
                      TextFormField(
                        controller: passwordController,
                        obscureText: ocultarPassword,
                        validator: (val) => val == null || val.length < 4 ? 'Mínimo 4 caracteres' : null,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF3F4F8),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade700, size: 20),
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          hintText: '••••••',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      // --- SECCIÓN FOTO DE PERFIL (SOLO REGISTRO) ---
                      if (!esModoLogin) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Foto de perfil',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFE8EAFA),
                            backgroundImage: imagenSeleccionada != null
                                ? FileImage(File(imagenSeleccionada!.path))
                                : null,
                            child: imagenSeleccionada == null
                                ? const Icon(Icons.person, size: 45, color: Color(0xFF4C5FD7))
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFECEEFA),
                                  foregroundColor: const Color(0xFF4C5FD7),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => seleccionarImagen(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                label: const Text('Tomar foto', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFECEEFA),
                                  foregroundColor: const Color(0xFF4C5FD7),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => seleccionarImagen(ImageSource.gallery),
                                icon: const Icon(Icons.image_outlined, size: 18),
                                label: const Text('Galería', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'En DartPad se usa una fotografía de demostración.',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // --- BOTÓN PRINCIPAL ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulBotonOscuro,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          onPressed: guardando ? null : procesarFormulario,
                          child: guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      esModoLogin ? Icons.arrow_forward : Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      esModoLogin ? 'Entrar ahora' : 'Crear cuenta',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      if (mensaje.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}