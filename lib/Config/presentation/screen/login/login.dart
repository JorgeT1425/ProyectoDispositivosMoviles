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
  final TextEditingController semestreController = TextEditingController(text: '1');
  final TextEditingController creditosController = TextEditingController(text: '160');

  final ImagePicker imagePicker = ImagePicker();

  bool esModoLogin = true;
  bool ocultarPassword = true;
  bool guardando = false;

  String programaSeleccionado = 'Ingeniería de Sistemas';
  XFile? imagenSeleccionada;
  String mensaje = '';

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    semestreController.dispose();
    creditosController.dispose();
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
      final respuesta = await supabase
          .from('usuarios')
          .select()
          .eq('correo', correoController.text.trim())
          .eq('contrasena', passwordController.text.trim())
          .maybeSingle();

      if (!mounted) return;

      if (respuesta == null) {
        setState(() => mensaje = 'Correo o contraseña incorrectos.');
      } else {
        usuarioActual = respuesta;
        context.go('/home');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => mensaje = 'Error al iniciar sesión: $error');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> ejecutarRegistro() async {
  setState(() {
    guardando = true;
    mensaje = '';
  });

  try {
    // 1. Verificar si el correo ya existe en Supabase
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

    // 2. Subir imagen si la seleccionó
    String? fotoUrl;
    if (imagenSeleccionada != null) {
      fotoUrl = await subirImagen();
    }

    // 3. Insertar el nuevo usuario en la base de datos
    await supabase.from('usuarios').insert({
      'nombre': nombreController.text.trim(),
      'correo': correoController.text.trim(),
      'contrasena': passwordController.text.trim(),
      'programa': programaSeleccionado,
      'semestre_actual': int.tryParse(semestreController.text) ?? 1,
      'creditos_programa': int.tryParse(creditosController.text) ?? 160,
      'foto_url': fotoUrl,
    });

    if (!mounted) return;

    // 4. Guardar el correo para que quede autocompletado en el login
    final String correoRegistrado = correoController.text.trim();

    // 5. Limpiar los campos del formulario de registro
    nombreController.clear();
    passwordController.clear();
    semestreController.text = '1';
    creditosController.text = '160';

    // 6. Cambiar el estado para pasar a la pantalla de Inicio de Sesión
    setState(() {
      esModoLogin = true; // Cambia la pestaña a "Iniciar sesión"
      imagenSeleccionada = null;
      correoController.text = correoRegistrado; // Mantiene el correo ingresado
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
              // --- TARJETA SUPERIOR AZUL (TrayectoriaU) ---
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
                          child: _tarjetaInfoHeader(
                            icon: Icons.calculate_outlined,
                            titulo: 'Promedios',
                            subtitulo: 'Por créditos',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tarjetaInfoHeader(
                            icon: Icons.show_chart,
                            titulo: 'Progreso',
                            subtitulo: 'Toda la carrera',
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
                              child: _botonTab(
                                texto: 'Iniciar sesión',
                                icono: Icons.login,
                                activo: esModoLogin,
                                colorActivo: azulBoton,
                                onTap: () => setState(() => esModoLogin = true),
                              ),
                            ),
                            Expanded(
                              child: _botonTab(
                                texto: 'Registrarse',
                                icono: Icons.person_add_alt,
                                activo: !esModoLogin,
                                colorActivo: azulBoton,
                                onTap: () => setState(() => esModoLogin = false),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- CAMPOS ESPECÍFICOS DE REGISTRO ---
                      if (!esModoLogin) ...[
                        _construirCampo(
                          controller: nombreController,
                          hintText: 'Nombre completo',
                          icon: Icons.person_outline,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 12),

                        // Dropdown Programa
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: grisCampos,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: programaSeleccionado,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.school_outlined, color: Colors.grey),
                                border: InputBorder.none,
                                labelText: 'Programa académico',
                                labelStyle: TextStyle(fontSize: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Ingeniería de Sistemas', child: Text('Ingeniería de Sistemas')),
                                DropdownMenuItem(value: 'Ingeniería Informática', child: Text('Ingeniería Informática')),
                                DropdownMenuItem(value: 'Ingeniería Electrónica', child: Text('Ingeniería Electrónica')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => programaSeleccionado = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _construirCampo(
                                controller: semestreController,
                                hintText: 'Semestre...',
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _construirCampo(
                                controller: creditosController,
                                hintText: 'Créditos t...',
                                icon: Icons.workspace_premium_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // --- CAMPOS COMUNES ---
                      _construirCampo(
                        controller: correoController,
                        hintText: 'estudiante@universidad.edu.co',
                        label: 'Correo institucional',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => val == null || !val.contains('@') ? 'Correo no válido' : null,
                      ),
                      const SizedBox(height: 12),

                      _construirCampo(
                        controller: passwordController,
                        hintText: '••••••',
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscureText: ocultarPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                        ),
                        validator: (val) => val == null || val.length < 4 ? 'Mínimo 4 caracteres' : null,
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
                              child: _botonFoto(
                                texto: 'Tomar foto',
                                icono: Icons.camera_alt_outlined,
                                onTap: () => seleccionarImagen(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _botonFoto(
                                texto: 'Galería',
                                icono: Icons.image_outlined,
                                onTap: () => seleccionarImagen(ImageSource.gallery),
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

  // Widget auxiliar para las tarjetas de la cabecera
  Widget _tarjetaInfoHeader({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitulo,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para las pestañas de selección (Iniciar sesión / Registrarse)
  Widget _botonTab({
    required String texto,
    required IconData icono,
    required bool activo,
    required Color colorActivo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? colorActivo : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 18, color: activo ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.white : Colors.grey.shade700,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir los campos de texto con estilo redondeado gris
  Widget _construirCampo({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? label,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey.shade700, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // Widget para los botones de Cámara y Galería
  Widget _botonFoto({
    required String texto,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECEEFA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 18, color: const Color(0xFF4C5FD7)),
            const SizedBox(width: 6),
            Text(
              texto,
              style: const TextStyle(
                color: Color(0xFF4C5FD7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}