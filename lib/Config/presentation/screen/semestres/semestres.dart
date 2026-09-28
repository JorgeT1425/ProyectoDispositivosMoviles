// lib/Config/presentation/screen/semestres/semestres.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/presentation/screen/menu_inferior/menu_inferior.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';

class Semestres extends StatefulWidget {
  static const String name = 'semestres';

  const Semestres({super.key});

  @override
  State<Semestres> createState() => _SemestresState();
}

class _SemestresState extends State<Semestres> {
  late Future<List<Map<String, dynamic>>> _futureSemestres;

  @override
  void initState() {
    super.initState();
    _cargarSemestres();
  }

  void _cargarSemestres() {
    final int? idUsuario = usuarioActual?['id_usuario'];
    if (idUsuario == null) return;

    setState(() {
      _futureSemestres = supabase
          .from('semestres')
          .select('*, materias(*)')
          .eq('id_usuario', idUsuario)
          .order('fecha_inicio', ascending: false);
    });
  }

  // --- DIÁLOGO DE CONFIRMACIÓN DE ELIMINACIÓN ---
  void _confirmarEliminacion(BuildContext context, int idSemestre) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFECEEF5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Eliminar semestre',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text(
            'También se eliminarán sus materias. ¿Deseas continuar?',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF4E538A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E538A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await supabase.from('semestres').delete().eq('id', idSemestre);
                  _cargarSemestres();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar: $e')),
                    );
                  }
                }
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

  void _abrirFormulario({Map<String, dynamic>? semestre}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioSemestreScreen(semestreExistente: semestre),
      ),
    );

    if (resultado == true) {
      _cargarSemestres();
    }
  }

  String _obtenerEstadoMateria(dynamic nota) {
    if (nota == null) return 'En curso';
    final num valorNota = nota as num;
    return valorNota >= 3.0 ? 'Aprobada' : 'Reprobada';
  }

  @override
  Widget build(BuildContext context) {
    const Color grisFondo = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text(
          'TrayectoriaU',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const MenuInferior(indiceActual: 1),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFDCDFFE),
        foregroundColor: const Color(0xFF2C3270),
        elevation: 1,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add, color: Color(0xFF2C3270)),
        label: const Text('Semestre', style: TextStyle(color: Color(0xFF2C3270), fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureSemestres,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final semestres = snapshot.data ?? [];

          if (semestres.isEmpty) {
            return const Center(child: Text('No has creado semestres aún.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: semestres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sem = semestres[index];
              final List materias = sem['materias'] ?? [];
              final bool enCurso = sem['estado'] == 'Actual' || sem['estado'] == 'En curso';

              int creditosTotales = materias.fold(0, (sum, m) => sum + (m['creditos'] as int? ?? 0));
              
              double promedioSemestre = 0.0;
              final materiasConNota = materias.where((m) => m['nota_definitiva'] != null).toList();
              if (materiasConNota.isNotEmpty) {
                double suma = materiasConNota.fold(0.0, (s, m) => s + (m['nota_definitiva'] as num).toDouble());
                promedioSemestre = suma / materiasConNota.length;
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CABECERA (BARRITA LATERAL + PERIODO + FECHAS) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Barrita de color solo para la cabecera
                        Container(
                          width: 5,
                          height: 38,
                          decoration: BoxDecoration(
                            color: enCurso ? const Color(0xFF1E2875) : const Color(0xFF107C41),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sem['periodo'] ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                                    onSelected: (val) {
                                      if (val == 'editar') {
                                        _abrirFormulario(semestre: sem);
                                      } else if (val == 'eliminar') {
                                        _confirmarEliminacion(context, sem['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${sem['fecha_inicio']} – ${sem['fecha_fin']}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // PRIMERA LÍNEA DIVISORIA (DEBAJO DEL PERIODO Y FECHAS)
                    const SizedBox(height: 12),
                    Divider(height: 1, thickness: 0.8, color: Colors.grey.shade300),
                    const SizedBox(height: 12),

                    // --- SECCIÓN ESTADO, MATERIAS, CRÉDITOS Y PROMEDIO ---
                    Row(
                      children: [
                        _pillLabel(
                          sem['estado'] ?? 'Actual',
                          enCurso ? const Color(0xFFE8EAF6) : const Color(0xFFE8F5E9),
                          enCurso ? const Color(0xFF283593) : const Color(0xFF107C41),
                        ),
                        const SizedBox(width: 8),
                        _pillLabel('${materias.length} materias', Colors.grey.shade100, Colors.black87),
                        const Spacer(),
                        Text(
                          '$creditosTotales créditos',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    if (materiasConNota.isNotEmpty || !enCurso) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Promedio: ${promedioSemestre.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],

                    // SEGUNDA LÍNEA DIVISORIA (DEBAJO DE ESTADO / MATERIAS Y PROMEDIO)
                    if (materias.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, thickness: 0.8, color: Colors.grey.shade300),
                      const SizedBox(height: 14),

                      // --- LISTADO DE MATERIAS DEL SEMESTRE ---
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: materias.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, mIndex) {
                          final m = materias[mIndex];
                          final dynamic nota = m['nota_definitiva'];
                          final String estadoTexto = _obtenerEstadoMateria(nota);
                          final String notaTexto = nota != null ? (nota as num).toStringAsFixed(1) : '--';

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFECEEFA),
                                child: Text(
                                  '${m['creditos'] ?? 0}',
                                  style: const TextStyle(
                                    color: Color(0xFF3F51B5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['nombre'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${m['codigo'] ?? ''} · $estadoTexto',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                notaTexto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pillLabel(String texto, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(texto, style: TextStyle(color: textCol, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// =========================================================================
// PANTALLA COMPLETA DE FORMULARIO DE SEMESTRE (Crear / Editar)
// =========================================================================
class FormularioSemestreScreen extends StatefulWidget {
  final Map<String, dynamic>? semestreExistente;

  const FormularioSemestreScreen({super.key, this.semestreExistente});

  @override
  State<FormularioSemestreScreen> createState() => _FormularioSemestreScreenState();
}

class _FormularioSemestreScreenState extends State<FormularioSemestreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController periodoCtrl;
  late TextEditingController fechaInicioCtrl;
  late TextEditingController fechaFinCtrl;
  String estadoSeleccionado = 'Actual';
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    periodoCtrl = TextEditingController(text: widget.semestreExistente?['periodo'] ?? '');
    fechaInicioCtrl = TextEditingController(text: widget.semestreExistente?['fecha_inicio'] ?? '');
    fechaFinCtrl = TextEditingController(text: widget.semestreExistente?['fecha_fin'] ?? '');
    estadoSeleccionado = widget.semestreExistente?['estado'] ?? 'Actual';
  }

  @override
  void dispose() {
    periodoCtrl.dispose();
    fechaInicioCtrl.dispose();
    fechaFinCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseFecha(String input) {
    try {
      final partes = input.trim().split(RegExp(r'[/.-]'));
      if (partes.length == 3) {
        final dia = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final anio = int.parse(partes[2]);
        return DateTime(anio, mes, dia);
      }
    } catch (_) {}
    return DateTime.tryParse(input.trim());
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final int? idUsuario = usuarioActual?['id_usuario'];
    if (idUsuario == null) return;

    setState(() => guardando = true);

    try {
      final String periodoLimpio = periodoCtrl.text.trim();
      final String fechaInicioTexto = fechaInicioCtrl.text.trim();
      final String fechaFinTexto = fechaFinCtrl.text.trim();

      // 1. VALIDACIÓN: Fecha final posterior a la fecha inicial
      final fInicio = _parseFecha(fechaInicioTexto);
      final fFin = _parseFecha(fechaFinTexto);

      if (fInicio != null && fFin != null) {
        if (!fFin.isAfter(fInicio)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La fecha final debe ser posterior a la fecha inicial.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          setState(() => guardando = false);
          return;
        }
      }

      // 2. VALIDACIÓN: Un usuario no puede repetir el mismo periodo
      var queryPeriodo = supabase
          .from('semestres')
          .select('id')
          .eq('id_usuario', idUsuario)
          .ilike('periodo', periodoLimpio);

      if (widget.semestreExistente != null) {
        queryPeriodo = queryPeriodo.neq('id', widget.semestreExistente!['id']);
      }

      final periodoExistente = await queryPeriodo.maybeSingle();
      if (periodoExistente != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El periodo "$periodoLimpio" ya está registrado.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => guardando = false);
        return;
      }

      // 3. VALIDACIÓN: No finalizar semestre si alguna materia no tiene nota
      if (estadoSeleccionado == 'Finalizado' && widget.semestreExistente != null) {
        final resMaterias = await supabase
            .from('materias')
            .select('nota_definitiva')
            .eq('semestre_id', widget.semestreExistente!['id']);

        final List materiasList = resMaterias as List;
        final bool haySinNota = materiasList.any((m) => m['nota_definitiva'] == null);

        if (haySinNota) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se puede finalizar el semestre si alguna materia no tiene nota.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          setState(() => guardando = false);
          return;
        }
      }

      final datos = {
        'id_usuario': idUsuario,
        'periodo': periodoLimpio,
        'fecha_inicio': fechaInicioTexto,
        'fecha_fin': fechaFinTexto,
        'estado': estadoSeleccionado,
      };

      if (widget.semestreExistente == null) {
        await supabase.from('semestres').insert(datos);
      } else {
        await supabase
            .from('semestres')
            .update(datos)
            .eq('id', widget.semestreExistente!['id']);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.semestreExistente != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          esEdicion ? 'Editar semestre' : 'Nuevo semestre',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _campoEstilizado(
                  controller: periodoCtrl,
                  label: 'Periodo',
                  hint: 'ej: 2026-1',
                  validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                _campoEstilizado(
                  controller: fechaInicioCtrl,
                  label: 'Fecha de inicio',
                  hint: 'DD/MM/AAAA',
                  validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                _campoEstilizado(
                  controller: fechaFinCtrl,
                  label: 'Fecha de finalización',
                  hint: 'DD/MM/AAAA',
                  validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: estadoSeleccionado,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Actual', child: Text('Actual')),
                            DropdownMenuItem(value: 'Finalizado', child: Text('Finalizado')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => estadoSeleccionado = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E538A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    onPressed: guardando ? null : _guardar,
                    icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    label: Text(
                      esEdicion ? 'Guardar semestre' : 'Crear semestre',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoEstilizado({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}