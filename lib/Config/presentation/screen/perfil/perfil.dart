// lib/Config/presentation/screen/perfil/perfil.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/presentation/screen/login/login.dart';
import 'package:flutter_application_2/Config/presentation/screen/menu_inferior/menu_inferior.dart';
import 'package:flutter_application_2/Config/presentation/screen/perfil/editar_perfil_screen.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';

class PerfilScreen extends StatefulWidget {
  static const name = 'perfil';

  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _cargando = true;
  double _promedioAcumulado = 0.0;
  int _creditosAprobados = 0;
  int _materiasAprobadas = 0;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    final int? idUsuario = usuarioActual?['id_usuario'];
    if (idUsuario == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final resMaterias = await supabase
          .from('materias')
          .select('*, semestres!inner(id_usuario)')
          .eq('semestres.id_usuario', idUsuario);

      final List materias = resMaterias as List;

      int creditosAprob = 0;
      int materiasAprob = 0;
      double sumaNotasPonderadas = 0;
      int sumaCreditosConNota = 0;

      for (var m in materias) {
        final dynamic nota = m['nota_definitiva'];
        final int creditos = (m['creditos'] as num?)?.toInt() ?? 0;

        if (nota != null) {
          final double valNota = (nota as num).toDouble();
          sumaNotasPonderadas += (valNota * creditos);
          sumaCreditosConNota += creditos;

          if (valNota >= 3.0) {
            creditosAprob += creditos;
            materiasAprob++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _creditosAprobados = creditosAprob;
          _materiasAprobadas = materiasAprob;
          _promedioAcumulado = sumaCreditosConNota > 0
              ? (sumaNotasPonderadas / sumaCreditosConNota)
              : 0.0;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFECEEF5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text(
            '¿Estás seguro de que deseas salir de TrayectoriaU?',
            style: TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF4E538A), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E538A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _cerrarSesion();
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint("Error al cerrar sesión en Supabase: $e");
    }

    usuarioActual = null;

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color grisFondo = Color(0xFFF6F7FB);

    final String nombre = usuarioActual?['nombre'] ?? 'Usuario';
    final String correo = usuarioActual?['correo'] ?? 'estudiante@universidad.edu.co';
    final String carrera = usuarioActual?['carrera'] ?? 'Carrera';
    final int semestre = usuarioActual?['semestre_actual'] ?? 1;
    final int creditosTotales = usuarioActual!['creditos_programa'] ?? 0;
    final String? fotoUrl = usuarioActual?['foto_url'];

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text(
          'TrayectoriaU',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const MenuInferior(indiceActual: 4),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tarjeta principal de usuario
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE8EEFA),
                            backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                                ? NetworkImage(fotoUrl)
                                : null,
                            child: (fotoUrl == null || fotoUrl.isEmpty)
                                ? const Icon(Icons.person, size: 32, color: Color(0xFF3B54C8))
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  correo,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$semestre.º semestre · $carrera',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditarPerfilScreen(),
                                ),
                              );
                              if (res == true) {
                                setState(() {
                                  _cargarResumen();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Resumen Personal
                  const Text(
                    'Resumen personal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Tarjetas de métricas
                  _ItemResumenCard(
                    icon: Icons.show_chart_rounded,
                    title: 'Promedio acumulado',
                    subtitle: _promedioAcumulado.toStringAsFixed(2),
                    iconColor: const Color(0xFF3B54C8),
                  ),
                  const SizedBox(height: 10),
                  _ItemResumenCard(
                    icon: Icons.school_outlined,
                    title: 'Créditos aprobados',
                    subtitle: '$_creditosAprobados de $creditosTotales',
                    iconColor: const Color(0xFF3B54C8),
                  ),
                  const SizedBox(height: 10),
                  _ItemResumenCard(
                    icon: Icons.check_circle_outline,
                    title: 'Materias aprobadas',
                    subtitle: '$_materiasAprobadas asignaturas aprobadas',
                    iconColor: const Color(0xFF3B54C8),
                  ),

                  const SizedBox(height: 24),

                  // 4. Tarjeta Azul Inferior con Botón de Cerrar Sesión
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B54C8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus datos están seguros',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Versión 1.1',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _confirmarCerrarSesion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _ItemResumenCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _ItemResumenCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: iconColor, size: 26),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}