import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/presentation/screen/menu_inferior/menu_inferior.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';


class Home extends StatefulWidget {
  static const String name = 'home';

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Consulta las materias a través de la relación de semestres con el usuario
  Future<List<Map<String, dynamic>>> obtenerMateriasUsuario() async {
    final dynamic idUsuario = usuarioActual?['id_usuario'];

    if (idUsuario == null) return [];

    // Realiza el JOIN entre materias y semestres filtrando por el id_usuario
    final response = await supabase
        .from('materias')
        .select('*, semestres!inner(id_usuario)')
        .eq('semestres.id_usuario', idUsuario);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    if (usuarioActual == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesión activa.')),
      );
    }

    // Datos del usuario traídos desde la sesión tras el login
    final String nombreCompleto = usuarioActual!['nombre'] ?? '';
    final String primerNombre = nombreCompleto.isNotEmpty 
        ? nombreCompleto.trim().split(' ').first 
        : '';
    final String programa = usuarioActual!['programa'] ?? 'Sin programa';
    final int semestre = usuarioActual!['semestre_actual'] ?? 1;
    final int creditosTotales = usuarioActual!['creditos_programa'] ?? 0;
    final String? fotoUrl = usuarioActual!['foto_url'];

    const Color azulHeader = Color(0xFF4C5FD7);
    const Color azulBotonOscuro = Color(0xFF4C5493);
    const Color grisFondo = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text(
          'TrayectoriaU',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const MenuInferior(indiceActual: 0),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerMateriasUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar datos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final materias = snapshot.data ?? [];

          // --- CÁLCULOS DINÁMICOS SOBRE TUS TABLAS DE SUPABASE ---
          final int totalMateriasActuales = materias.length;
          
          // Materias sin nota_definitiva asignada
          final int notasPendientes = materias.where((m) => m['nota_definitiva'] == null).length;

          // Créditos ganados de materias con nota_definitiva >= 3.0
          final int creditosAprobados = materias
              .where((m) => m['nota_definitiva'] != null && (m['nota_definitiva'] as num) >= 3.0)
              .fold(0, (sum, m) => sum + ((m['creditos'] as int? ?? 0)));

          // Promedio acumulado de las materias que ya tienen nota
          final materiasConNota = materias.where((m) => m['nota_definitiva'] != null).toList();
          double promedioCalculado = 0.0;

          if (materiasConNota.isNotEmpty) {
            double sumaNotas = materiasConNota.fold(
                0.0, (sum, m) => sum + ((m['nota_definitiva'] as num).toDouble()));
            promedioCalculado = sumaNotas / materiasConNota.length;
          }

          final double avanceCreditos = creditosTotales > 0
              ? (creditosAprobados / creditosTotales).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TARJETA DE PERFIL Y BIENVENIDA ---
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                ? NetworkImage(fotoUrl)
                                : null,
                            child: (fotoUrl == null || fotoUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Hola, $primerNombre',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('👋', style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  programa,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vas en $semestre.° semestre y has aprobado $creditosAprobados de $creditosTotales créditos.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: avanceCreditos,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- ESTADÍSTICAS (TARJETAS 2x2) ---
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaEstadistica(
                        icono: Icons.school_outlined,
                        colorIcono: Colors.blue.shade100,
                        colorIconoTexto: Colors.blue.shade700,
                        valor: '$totalMateriasActuales',
                        etiqueta: 'Materias actuales',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tarjetaEstadistica(
                        icono: Icons.assignment_outlined,
                        colorIcono: Colors.amber.shade100,
                        colorIconoTexto: Colors.amber.shade800,
                        valor: '$notasPendientes',
                        etiqueta: 'Notas pendientes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaEstadistica(
                        icono: Icons.show_chart,
                        colorIcono: Colors.green.shade100,
                        colorIconoTexto: Colors.green.shade700,
                        valor: promedioCalculado.toStringAsFixed(1),
                        etiqueta: 'Promedio actual',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tarjetaEstadistica(
                        icono: Icons.workspace_premium_outlined,
                        colorIcono: Colors.purple.shade100,
                        colorIconoTexto: Colors.purple.shade700,
                        valor: promedioCalculado.toStringAsFixed(1),
                        etiqueta: 'Promedio general',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- SECCIÓN: ESTADO DE TUS MATERIAS ---
                const Text(
                  'Estado de tus materias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                if (materias.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Text(
                        'No tienes materias registradas aún.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: materias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final materia = materias[index];
                      final String nombreMateria = materia['nombre'] ?? 'Sin nombre';
                      final int creditos = materia['creditos'] ?? 0;
                      final dynamic notaDefinitiva = materia['nota_definitiva'];

                      final String textoNota = notaDefinitiva != null 
                          ? (notaDefinitiva as num).toStringAsFixed(1) 
                          : '--';

                      final String textoSubtitulo = notaDefinitiva != null 
                          ? '$creditos créditos · Nota: $textoNota' 
                          : '$creditos créditos · Sin nota definitiva';

                      return _itemMateria(
                        nombre: nombreMateria,
                        subtitulo: textoSubtitulo,
                        nota: textoNota,
                      );
                    },
                  ),

                const SizedBox(height: 18),

                // --- BOTÓN VER PROGRESO COMPLETO ---
                SizedBox(
                  width: 190,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulBotonOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => context.go('/progreso'),
                    icon: const Icon(Icons.show_chart, color: Colors.white, size: 18),
                    label: const Text(
                      'Ver progreso completo',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaEstadistica({
    required IconData icono,
    required Color colorIcono,
    required Color colorIconoTexto,
    required String valor,
    required String etiqueta,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorIcono,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIconoTexto, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMateria({
    required String nombre,
    required String subtitulo,
    required String nota,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4252B5), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              nota,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}