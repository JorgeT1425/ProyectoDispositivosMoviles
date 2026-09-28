// lib/Config/presentation/screen/materias/materias.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_2/Config/presentation/screen/menu_inferior/menu_inferior.dart';
import 'package:flutter_application_2/Config/supabase/session.dart';
import 'package:flutter_application_2/Config/supabase/supabase_config.dart';

class Materias extends StatefulWidget {
  static const String name = 'materias';

  const Materias({super.key});

  @override
  State<Materias> createState() => _MateriasState();
}

class _MateriasState extends State<Materias> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _todasLasMaterias = [];
  List<Map<String, dynamic>> _materiasFiltradas = [];
  List<Map<String, dynamic>> _semestresUsuario = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final int? idUsuario = usuarioActual?['id_usuario'];
    if (idUsuario == null) return;

    try {
      final resSemestres = await supabase
          .from('semestres')
          .select()
          .eq('id_usuario', idUsuario);

      final resMaterias = await supabase
          .from('materias')
          .select('*, semestres!inner(periodo, estado, id_usuario)')
          .eq('semestres.id_usuario', idUsuario);

      setState(() {
        _semestresUsuario = List<Map<String, dynamic>>.from(resSemestres);
        _todasLasMaterias = List<Map<String, dynamic>>.from(resMaterias);
        _materiasFiltradas = List.from(_todasLasMaterias);
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _filtrarMaterias(String query) {
    setState(() {
      if (query.isEmpty) {
        _materiasFiltradas = List.from(_todasLasMaterias);
      } else {
        _materiasFiltradas = _todasLasMaterias.where((m) {
          final nombre = (m['nombre'] ?? '').toString().toLowerCase();
          final codigo = (m['codigo'] ?? '').toString().toLowerCase();
          return nombre.contains(query.toLowerCase()) || codigo.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _confirmarEliminacion(BuildContext context, int idMateria) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFECEEF5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Eliminar materia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: const Text('¿Estás seguro de que deseas eliminar esta materia?', style: TextStyle(fontSize: 14)),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF4E538A), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E538A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await supabase.from('materias').delete().eq('id', idMateria);
                  _cargarDatos();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
                  }
                }
              },
              child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  void _abrirFormulario({Map<String, dynamic>? materia}) async {
    if (_semestresUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes crear un semestre.')),
      );
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioMateriaScreen(
          materiaExistente: materia,
          semestresUsuario: _semestresUsuario,
        ),
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  Map<String, dynamic> _obtenerEstiloEstado(dynamic nota) {
    if (nota == null) {
      return {
        'texto': 'En curso',
        'colorBorde': const Color(0xFF3F51B5),
        'colorBg': const Color(0xFFE8EAF6),
        'colorTexto': const Color(0xFF283593),
        'etiquetaNota': 'actual',
      };
    }
    final double val = (nota as num).toDouble();
    if (val >= 3.0) {
      return {
        'texto': 'Aprobada',
        'colorBorde': const Color(0xFF4CAF50),
        'colorBg': const Color(0xFFE8F5E9),
        'colorTexto': const Color(0xFF2E7D32),
        'etiquetaNota': 'final',
      };
    } else {
      return {
        'texto': 'Reprobada',
        'colorBorde': const Color(0xFFE53935),
        'colorBg': const Color(0xFFFFEBEE),
        'colorTexto': const Color(0xFFC62828),
        'etiquetaNota': 'final',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color grisFondo = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: grisFondo,
      appBar: AppBar(
        title: const Text('TrayectoriaU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const MenuInferior(indiceActual: 2),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFDCDFFE),
        foregroundColor: const Color(0xFF2C3270),
        elevation: 1,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add, color: Color(0xFF2C3270)),
        label: const Text('Materia', style: TextStyle(color: Color(0xFF2C3270), fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Materias', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('Consulta notas actuales e historial de materias.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrarMaterias,
                decoration: const InputDecoration(
                  hintText: 'Buscar materia o código',
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _materiasFiltradas.isEmpty
                    ? const Center(child: Text('No hay asignaturas registradas.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _materiasFiltradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final mat = _materiasFiltradas[index];
                          final semestreInfo = mat['semestres'];
                          final String periodo = semestreInfo?['periodo'] ?? '';
                          final dynamic nota = mat['nota_definitiva'];
                          final int creditos = mat['creditos'] ?? 0;
                          final String codigoMateria = mat['codigo'] ?? '';

                          // DETECCIÓN: Materia repetida (mismo código presente en 2 o más semestres distintos)
                          final semestresConEsteCodigo = _todasLasMaterias
                              .where((m) =>
                                  m['codigo'] != null &&
                                  m['codigo'].toString().trim().toLowerCase() == codigoMateria.trim().toLowerCase())
                              .map((m) => m['semestre_id'])
                              .toSet();

                          final bool esMateriaRepetida = semestresConEsteCodigo.length >= 2;

                          final estilo = _obtenerEstiloEstado(nota);
                          final String notaTexto = nota != null ? (nota as num).toStringAsFixed(1) : '--';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: estilo['colorBorde'] as Color,
                                      width: 5,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mat['nombre'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$codigoMateria · $periodo',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: estilo['colorBg'] as Color,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  estilo['texto'] as String,
                                                  style: TextStyle(
                                                    color: estilo['colorTexto'] as Color,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              if (esMateriaRepetida) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF3E0),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'Repetida',
                                                    style: TextStyle(
                                                      color: Color(0xFFE65100),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 10),
                                              Text(
                                                '$creditos créditos',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          notaTexto,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: estilo['colorTexto'] as Color,
                                          ),
                                        ),
                                        Text(
                                          estilo['etiquetaNota'] as String,
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.black87),
                                          onSelected: (val) {
                                            if (val == 'editar') {
                                              _abrirFormulario(materia: mat);
                                            } else if (val == 'eliminar') {
                                              _confirmarEliminacion(context, mat['id']);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'editar', child: Text('Editar')),
                                            const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// PANTALLA COMPLETA DE FORMULARIO DE MATERIA (Crear / Editar)
// =========================================================================
class FormularioMateriaScreen extends StatefulWidget {
  final Map<String, dynamic>? materiaExistente;
  final List<Map<String, dynamic>> semestresUsuario;

  const FormularioMateriaScreen({
    super.key,
    this.materiaExistente,
    required this.semestresUsuario,
  });

  @override
  State<FormularioMateriaScreen> createState() => _FormularioMateriaScreenState();
}

class _FormularioMateriaScreenState extends State<FormularioMateriaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController codigoCtrl;
  late TextEditingController creditosCtrl;
  late TextEditingController nombreCtrl;
  late TextEditingController docenteCtrl;
  late TextEditingController notaCtrl;

  int? semestreSeleccionadoId;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    codigoCtrl = TextEditingController(text: widget.materiaExistente?['codigo'] ?? 'MAT-');
    creditosCtrl = TextEditingController(text: widget.materiaExistente?['creditos']?.toString() ?? '3');
    nombreCtrl = TextEditingController(text: widget.materiaExistente?['nombre'] ?? '');
    docenteCtrl = TextEditingController(text: widget.materiaExistente?['docente'] ?? '');
    notaCtrl = TextEditingController(
      text: widget.materiaExistente?['nota_definitiva'] != null
          ? widget.materiaExistente!['nota_definitiva'].toString()
          : '',
    );

    semestreSeleccionadoId = widget.materiaExistente?['semestre_id'] ??
        (widget.semestresUsuario.isNotEmpty ? widget.semestresUsuario.first['id'] : null);
  }

  @override
  void dispose() {
    codigoCtrl.dispose();
    creditosCtrl.dispose();
    nombreCtrl.dispose();
    docenteCtrl.dispose();
    notaCtrl.dispose();
    super.dispose();
  }

  // Comprueba si el semestre seleccionado actualmente tiene estado 'Finalizado'
  bool _esSemestreFinalizado() {
    if (semestreSeleccionadoId == null) return false;
    final semestre = widget.semestresUsuario.firstWhere(
      (s) => s['id'] == semestreSeleccionadoId,
      orElse: () => <String, dynamic>{},
    );
    return semestre['estado'] == 'Finalizado';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (semestreSeleccionadoId == null) return;

    setState(() => guardando = true);

    try {
      final String codigoLimpio = codigoCtrl.text.trim();

      // VALIDACIÓN: Una materia no puede repetirse dentro del mismo semestre con el mismo código
      var queryMateriaSemestre = supabase
          .from('materias')
          .select('id')
          .eq('semestre_id', semestreSeleccionadoId!)
          .ilike('codigo', codigoLimpio);

      if (widget.materiaExistente != null) {
        queryMateriaSemestre = queryMateriaSemestre.neq('id', widget.materiaExistente!['id']);
      }

      final materiaExistenteEnSemestre = await queryMateriaSemestre.maybeSingle();

      if (materiaExistenteEnSemestre != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ya existe una materia con el código "$codigoLimpio" en este semestre.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => guardando = false);
        return;
      }

      final datos = {
        'semestre_id': semestreSeleccionadoId,
        'codigo': codigoLimpio,
        'nombre': nombreCtrl.text.trim(),
        'docente': docenteCtrl.text.trim().isEmpty ? null : docenteCtrl.text.trim(),
        'creditos': int.tryParse(creditosCtrl.text) ?? 0,
        'nota_definitiva': notaCtrl.text.trim().isNotEmpty ? double.tryParse(notaCtrl.text.trim()) : null,
      };

      if (widget.materiaExistente == null) {
        await supabase.from('materias').insert(datos);
      } else {
        await supabase.from('materias').update(datos).eq('id', widget.materiaExistente!['id']);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.materiaExistente != null;
    final esFinalizado = _esSemestreFinalizado();

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
          esEdicion ? 'Editar materia' : 'Nueva materia',
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
                // Dropdown Semestre
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
                      Text('Semestre', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: semestreSeleccionadoId,
                          isExpanded: true,
                          items: widget.semestresUsuario.map((s) {
                            return DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text('${s['periodo']} · ${s['estado']}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                semestreSeleccionadoId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Código y Créditos
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _campoEstilizado(
                        controller: codigoCtrl,
                        label: 'Código',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _campoEstilizado(
                        controller: creditosCtrl,
                        label: 'Créditos',
                        tipoTeclado: TextInputType.number,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _campoEstilizado(
                  controller: nombreCtrl,
                  label: 'Nombre de la materia',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                _campoEstilizado(
                  controller: docenteCtrl,
                  label: 'Docente',
                ),
                const SizedBox(height: 16),

                // Campo Nota Definitiva con Validación Dinámica de Semestre Finalizado
                _campoEstilizado(
                  controller: notaCtrl,
                  label: esFinalizado ? 'Nota definitiva *' : 'Nota definitiva',
                  tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    final textoNota = val?.trim() ?? '';

                    // Si el semestre está finalizado, la nota NO puede estar vacía
                    if (esFinalizado && textoNota.isEmpty) {
                      return 'Semestre finalizado: debes ingresar la nota';
                    }

                    // Si se ingresó un texto, se valida formato y rango (0.0 a 5.0)
                    if (textoNota.isNotEmpty) {
                      final parsed = double.tryParse(textoNota);
                      if (parsed == null) {
                        return 'Ingresa una nota válida';
                      }
                      if (parsed < 0.0 || parsed > 5.0) {
                        return 'La nota debe estar entre 0.0 y 5.0';
                      }
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                  child: Text(
                    esFinalizado
                        ? 'Obligatoria porque el semestre seleccionado está finalizado.'
                        : 'Puede quedar vacía mientras la materia esté en curso.',
                    style: TextStyle(
                      color: esFinalizado ? const Color(0xFFC62828) : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: esFinalizado ? FontWeight.w500 : FontWeight.normal,
                    ),
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
                      esEdicion ? 'Guardar materia' : 'Crear materia',
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
    TextInputType tipoTeclado = TextInputType.text,
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
        keyboardType: tipoTeclado,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}