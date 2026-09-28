// lib/Config/presentation/screen/progreso/progreso.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/presentation/screen/menu_inferior/menu_inferior.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';

class ProgressScreen extends StatefulWidget {
  static const name = 'progreso';

  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _cargando = true;

  // Métricas generales
  int _creditosTotales = 160;
  int _creditosAprobados = 0;
  int _creditosCursados = 0;
  int _creditosPendientes = 160;
  int _materiasAprobadas = 0;
  double _promedioAcumulado = 0.0;

  // Datos para listas
  List<Map<String, dynamic>> _promediosSemestrales = [];
  List<String> _materiasReprobadas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosProgreso();
  }

  Future<void> _cargarDatosProgreso() async {
    final int? idUsuario = usuarioActual?['id_usuario'];
    _creditosTotales = usuarioActual?['creditos_totales'] ?? 160;

    if (idUsuario == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      // Consultar semestres y materias pertenecientes al usuario
      final resSemestres = await supabase
          .from('semestres')
          .select('*, materias(*)')
          .eq('id_usuario', idUsuario)
          .order('id', ascending: false);

      int creditosAprob = 0;
      int creditosCurs = 0;
      int materiasAprob = 0;

      double sumaNotasPonderadasGlobal = 0;
      int sumaCreditosConNotaGlobal = 0;

      List<Map<String, dynamic>> listaSemestres = [];
      List<String> reprobadas = [];

      for (var sem in (resSemestres as List)) {
        final List materias = sem['materias'] ?? [];
        final String periodo = sem['periodo'] ?? 'Semestre';

        double sumaNotasPonderadasSem = 0;
        int sumaCreditosConNotaSem = 0;
        int cantMateriasSemestre = materias.length;

        for (var mat in materias) {
          final dynamic nota = mat['nota_definitiva'];
          final int creditos = (mat['creditos'] as num?)?.toInt() ?? 0;
          final String codigo = mat['codigo'] ?? mat['nombre'] ?? '';

          if (nota != null) {
            final double valNota = (nota as num).toDouble();
            creditosCurs += creditos;

            sumaNotasPonderadasGlobal += (valNota * creditos);
            sumaCreditosConNotaGlobal += creditos;

            sumaNotasPonderadasSem += (valNota * creditos);
            sumaCreditosConNotaSem += creditos;

            if (valNota >= 3.0) {
              creditosAprob += creditos;
              materiasAprob++;
            } else {
              if (codigo.isNotEmpty && !reprobadas.contains(codigo)) {
                reprobadas.add(codigo);
              }
            }
          }
        }

        double promedioSemestre = sumaCreditosConNotaSem > 0
            ? (sumaNotasPonderadasSem / sumaCreditosConNotaSem)
            : 0.0;

        if (cantMateriasSemestre > 0) {
          listaSemestres.add({
            'periodo': periodo,
            'cantidadMaterias': cantMateriasSemestre,
            'promedio': promedioSemestre,
          });
        }
      }

      double promedioGlobal = sumaCreditosConNotaGlobal > 0
          ? (sumaNotasPonderadasGlobal / sumaCreditosConNotaGlobal)
          : 0.0;

      int pendientes = _creditosTotales - creditosAprob;
      if (pendientes < 0) pendientes = 0;

      if (mounted) {
        setState(() {
          _creditosAprobados = creditosAprob;
          _creditosCursados = creditosCurs;
          _creditosPendientes = pendientes;
          _materiasAprobadas = materiasAprob;
          _promedioAcumulado = promedioGlobal;
          _promediosSemestrales = listaSemestres;
          _materiasReprobadas = reprobadas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color grisFondo = Color(0xFFF7F8FC);
    final double porcentajeAvance = _creditosTotales > 0
        ? ((_creditosAprobados / _creditosTotales) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text(
          'TrayectoriaU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const MenuInferior(indiceActual: 3),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progreso académico',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resumen ponderado por créditos de toda tu carrera.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // 1. TARJETA AZUL DE AVANCE DE LA CARRERA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5161DC), Color(0xFF6B78E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avance de la carrera',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${porcentajeAvance.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (porcentajeAvance / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_creditosAprobados aprobados de $_creditosTotales créditos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. CUADRÍCULA DE 4 MÉTRICAS (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricaCard(
                          icon: Icons.workspace_premium_outlined,
                          iconBgColor: const Color(0xFFF2E7FE),
                          iconColor: const Color(0xFF9C27B0),
                          valor: _promedioAcumulado.toStringAsFixed(2),
                          etiqueta: 'Promedio acu...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricaCard(
                          icon: Icons.check_circle_outline,
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF4CAF50),
                          valor: '$_materiasAprobadas',
                          etiqueta: 'Materias apro...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricaCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          iconBgColor: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFFF9800),
                          valor: '$_creditosCursados',
                          etiqueta: 'Créditos curs...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricaCard(
                          icon: Icons.outlined_flag,
                          iconBgColor: const Color(0xFFE8EAF6),
                          iconColor: const Color(0xFF3F51B5),
                          valor: '$_creditosPendientes',
                          etiqueta: 'Créditos pend...',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. SECCIÓN PROMEDIO POR SEMESTRE
                  const Text(
                    'Promedio por semestre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _promediosSemestrales.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No hay datos semestrales registrados.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _promediosSemestrales.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final sem = _promediosSemestrales[index];
                            final String periodo = sem['periodo'];
                            final int cant = sem['cantidadMaterias'];
                            final double prom = sem['promedio'];

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECEFFB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xFF5161DC),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          periodo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$cant materias',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    prom.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 24),

                  // 4. SECCIÓN ALERTAS ACADÉMICAS
                  const Text(
                    'Alertas académicas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _materiasReprobadas.isEmpty
                        ? Row(
                            children: const [
                              Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Sin alertas ni materias reprobadas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_materiasReprobadas.length} intento(s) reprobado(s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Materias repetidas detectadas: ${_materiasReprobadas.join(", ")}.',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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

// =========================================================================
// WIDGET AUXILIAR PARA CADA UNO DE LOS 4 CUADROS DE MÉTRICAS
// =========================================================================
class _MetricaCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String valor;
  final String etiqueta;

  const _MetricaCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}