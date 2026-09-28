
class Semestre {
  final int? id;
  final int idUsuario;
  final String periodo;
  final String fechaInicio;
  final String fechaFin;
  final String estado; // 'En curso', 'Finalizado', etc.
  final DateTime? createdAt;

  Semestre({
    this.id,
    required this.idUsuario,
    required this.periodo,
    required this.fechaInicio,
    required this.fechaFin,
    this.estado = 'En curso',
    this.createdAt,
  });

  factory Semestre.fromJson(Map<String, dynamic> json) {
    return Semestre(
      id: json['id'] as int?,
      idUsuario: json['id_usuario'] as int,
      periodo: json['periodo'] as String? ?? '',
      fechaInicio: json['fecha_inicio'] as String? ?? '',
      fechaFin: json['fecha_fin'] as String? ?? '',
      estado: json['estado'] as String? ?? 'En curso',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_usuario': idUsuario,
      'periodo': periodo,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'estado': estado,
    };
  }
}

class Materia {
  final int? id;
  final int semestreId;
  final String codigo;
  final String nombre;
  final String? docente;
  final int creditos;
  final double? notaDefinitiva;
  final DateTime? createdAt;

  Materia({
    this.id,
    required this.semestreId,
    required this.codigo,
    required this.nombre,
    this.docente,
    required this.creditos,
    this.notaDefinitiva,
    this.createdAt,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] as int?,
      semestreId: json['semestre_id'] as int,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      docente: json['docente'] as String?,
      creditos: json['creditos'] as int? ?? 0,
      notaDefinitiva: json['nota_definitiva'] != null
          ? (json['nota_definitiva'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'semestre_id': semestreId,
      'codigo': codigo,
      'nombre': nombre,
      'docente': docente,
      'creditos': creditos,
      'nota_definitiva': notaDefinitiva,
    };
  }
}