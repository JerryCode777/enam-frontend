import '../../../core/error/failure.dart';
import '../../session/data/session_repository.dart';
import '../../session/domain/session_models.dart';
import '../domain/aula_models.dart';
import 'aula_repository.dart';

/// El aula sin servidor, para los mocks y las pruebas.
///
/// Los cursos son los de `enam-contenido/cursos`, con su profe y su lema. Las
/// clases no traen video: el doble no tiene dónde servirlo, y una URL de fuera
/// haría depender las pruebas de la red. El reproductor se prueba contra el
/// backend local (`cargar-aula` con `AULA_MEDIOS_DIR`).
class MockAulaRepository implements AulaRepository {
  MockAulaRepository({
    this.premium = true,
    this.sesiones,
    this.delay = const Duration(milliseconds: 400),
  });

  /// Sin Premium, solo las 3 primeras clases de cada curso se abren.
  final bool premium;

  /// Quién arma la práctica de la clase. Sin él, la práctica falla.
  final SessionRepository? sesiones;
  final Duration delay;

  final _progreso = <String, ProgresoDeClase>{
    'pediatria.01-01': const ProgresoDeClase(
      segundosVistos: 512,
      posicionS: 500,
      completada: true,
    ),
    'pediatria.01-02': const ProgresoDeClase(
      segundosVistos: 260,
      posicionS: 262,
    ),
  };

  static const _cursos = [
    (
      'repaso-final',
      'Repaso final ENAM',
      'Esto cae seguro',
      'Profe Andrea',
      'la',
    ),
    ('medicina', 'Medicina', 'Vamos por partes', 'Profe Martín', 'el'),
    ('pediatria', 'Pediatría', 'Primero, la norma', 'Profe Ximena', 'la'),
    (
      'gineco-obstetricia',
      'Ginecología y Obstetricia',
      'Son dos pacientes',
      'Profe Rocío',
      'la',
    ),
    ('cirugia', 'Cirugía', '¿Cuál es la indicación?', 'Profe Raúl', 'el'),
    (
      'salud-publica',
      'Salud Pública',
      'Esto se ve en el primer nivel',
      'Profe Wilber',
      'el',
    ),
    (
      'emergencias',
      'Emergencias',
      'Primero lo que mata primero',
      'Profe Diego',
      'el',
    ),
    (
      'ciencias-basicas',
      'Ciencias Básicas',
      '¿Y por qué pasa eso?',
      'Profe Patricia',
      'la',
    ),
    (
      'etica',
      'Ética y Deontología',
      'Primero, el paciente',
      'Profe Teresa',
      'la',
    ),
    (
      'gestion',
      'Gestión en Salud',
      '¿Quién es el responsable?',
      'Profe Gladys',
      'la',
    ),
    (
      'investigacion',
      'Investigación',
      '¿Qué tipo de estudio es?',
      'Profe Nicolás',
      'el',
    ),
  ];

  /// El temario de ejemplo: dos módulos de cinco clases, con una que viene.
  static const _modulos = [
    (
      'Lo que más cae',
      [
        ('Anemia ferropénica I: diagnóstico y tamizaje', 512),
        ('Anemia ferropénica II: tratamiento según la norma', 534),
        ('Desnutrición crónica infantil', 468),
        ('Esquema nacional de vacunación', 601),
        ('Control de crecimiento y desarrollo', 455),
      ],
    ),
    (
      'Casos de primer nivel',
      [
        ('Infección respiratoria aguda', 488),
        ('Enfermedad diarreica aguda y deshidratación', 523),
        ('Fiebre sin foco en el lactante', 497),
        ('Síndrome de dificultad respiratoria del recién nacido', 515),
        ('Ictericia neonatal', 0),
      ],
    ),
  ];

  /// Lo mismo que responde el servidor al pedir una clase bloqueada.
  static const _bloqueada = ForbiddenFailure(
    'Los cursos completos son de Premium.',
    'FUNCION_PREMIUM',
  );

  /// Sin clases todavía: sale como «Próximamente».
  static const _sinClases = {'gestion', 'investigacion'};

  Profe _profe(String nombre, String articulo) => Profe(
    id: 'profe-${nombre.split(' ').last.toLowerCase()}',
    nombre: nombre,
    articulo: articulo,
  );

  Curso _curso(int i) {
    final (id, titulo, lema, profe, articulo) = _cursos[i];
    final modulos = <Modulo>[];
    if (!_sinClases.contains(id)) {
      var orden = 0;
      for (final (m, (tituloModulo, clases)) in _modulos.indexed) {
        final codigoModulo = (m + 1).toString().padLeft(2, '0');
        modulos.add(
          Modulo(
            id: '$id.$codigoModulo',
            codigo: codigoModulo,
            orden: m + 1,
            titulo: tituloModulo,
            nodoId: '$id-$codigoModulo',
            clases: [
              for (final (c, (tituloClase, duracion)) in clases.indexed)
                _clase(
                  '$id.$codigoModulo-${(c + 1).toString().padLeft(2, '0')}',
                  tituloClase,
                  duracion,
                  orden: ++orden,
                ),
            ],
          ),
        );
      }
    }
    final todas = modulos.expand((m) => m.clases).toList();
    final disponibles = todas.where((c) => c.disponible).toList();
    return Curso(
      id: id,
      tipo: id == 'repaso-final' ? TipoDeCurso.repaso : TipoDeCurso.area,
      areaId: id == 'repaso-final' ? null : id,
      titulo: titulo,
      lema: lema,
      descripcion: id == 'repaso-final'
          ? 'Lo que más se repite en el ENAM, área por área, en clases cortas '
                'para las últimas semanas.'
          : 'El temario oficial de $titulo, con las normas técnicas del MINSA '
                'y las guías que se preguntan.',
      profe: _profe(profe, articulo),
      clases: todas.length,
      disponibles: disponibles.length,
      gratis: todas.where((c) => c.gratis).length,
      duracionS: disponibles.fold(0, (s, c) => s + c.duracionS),
      completadas: disponibles.where((c) => c.progreso.completada).length,
      premium: premium,
      modulos: modulos,
      continuar: disponibles
          .where((c) => !c.bloqueada && !c.progreso.completada)
          .firstOrNull,
    );
  }

  ClaseResumen _clase(
    String id,
    String titulo,
    int duracion, {
    required int orden,
  }) {
    final gratis = orden <= 3;
    return ClaseResumen(
      id: id,
      codigo: id.split('.').last,
      orden: orden,
      titulo: titulo,
      duracionS: duracion,
      estado: duracion > 0
          ? EstadoDeClase.disponible
          : EstadoDeClase.proximamente,
      gratis: gratis,
      bloqueada: !premium && !gratis,
      progreso: _progreso[id] ?? const ProgresoDeClase(),
    );
  }

  CursoResumen _resumen(Curso c) => CursoResumen(
    id: c.id,
    tipo: c.tipo,
    areaId: c.areaId,
    titulo: c.titulo,
    descripcion: c.descripcion,
    lema: c.lema,
    profe: c.profe,
    orden: _cursos.indexWhere((x) => x.$1 == c.id) + 1,
    publicado: c.disponibles > 0,
    clases: c.clases,
    disponibles: c.disponibles,
    gratis: c.gratis,
    duracionS: c.duracionS,
    completadas: c.completadas,
  );

  /// La latencia simulada. Sin ella, ni un temporizador: las pruebas fallan
  /// si queda alguno pendiente.
  Future<void> _esperar() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<CursoResumen>> cursos() async {
    await _esperar();
    return [for (var i = 0; i < _cursos.length; i++) _resumen(_curso(i))];
  }

  @override
  Future<Curso> curso(String id) async {
    await _esperar();
    final i = _cursos.indexWhere((c) => c.$1 == id);
    if (i < 0) throw StateError('No existe el curso $id');
    return _curso(i);
  }

  @override
  Future<Clase> clase(String id) async {
    await _esperar();
    final curso = _curso(_cursos.indexWhere((c) => id.startsWith('${c.$1}.')));
    final todas = curso.modulos.expand((m) => m.clases).toList();
    final i = todas.indexWhere((c) => c.id == id);
    final r = todas[i];
    if (r.bloqueada) throw _bloqueada;
    Vecina? vecina(int j) => j < 0 || j >= todas.length
        ? null
        : Vecina(
            id: todas[j].id,
            titulo: todas[j].titulo,
            bloqueada: todas[j].bloqueada,
          );
    return Clase(
      id: r.id,
      codigo: r.codigo,
      titulo: r.titulo,
      duracionS: r.duracionS,
      estado: r.estado,
      gratis: r.gratis,
      bloqueada: r.bloqueada,
      progreso: r.progreso,
      cursoId: curso.id,
      cursoTitulo: curso.titulo,
      profe: curso.profe,
      moduloId: curso.modulos.firstWhere((m) => m.clases.contains(r)).id,
      objetivos: const [
        'Reconocer el cuadro y sus criterios diagnósticos',
        'Aplicar el manejo de la norma técnica vigente',
        'Distinguir lo que el ENAM suele preguntar',
      ],
      temas: [r.titulo.split(':').first],
      referencias: const [
        Referencia(
          id: 'R1',
          tipo: TipoDeReferencia.norma,
          cita:
              'NTS N.° 213-MINSA/DGIESP-2024, Prevención y control de la '
              'anemia',
          anio: 2024,
          url: 'https://www.gob.pe/minsa',
        ),
        Referencia(
          id: 'R2',
          tipo: TipoDeReferencia.libro,
          cita: 'Nelson Tratado de Pediatría',
          edicion: '21.ª',
          capitulo: '482',
          anio: 2020,
        ),
      ],
      practicaDisponible: r.disponible,
      anterior: vecina(i - 1),
      siguiente: vecina(i + 1),
    );
  }

  @override
  Future<ProgresoDeClase> progreso(
    String claseId, {
    required int segundosVistos,
    required int posicionS,
  }) async {
    final actual = _progreso[claseId] ?? const ProgresoDeClase();
    final vistos = segundosVistos > actual.segundosVistos
        ? segundosVistos
        : actual.segundosVistos;
    final clase = await this.clase(claseId);
    return _progreso[claseId] = ProgresoDeClase(
      segundosVistos: vistos,
      posicionS: posicionS,
      completada: actual.completada || vistos >= 0.9 * clase.duracionS,
    );
  }

  @override
  Future<StudySession> practica(String claseId) async {
    await clase(claseId);
    final sesiones = this.sesiones;
    if (sesiones == null) throw StateError('Sin sesiones en el doble');
    return sesiones.startPractice(const PracticeConfig(cantidadPreguntas: 5));
  }

  @override
  Future<SeguirViendo?> seguirViendo() async {
    await _esperar();
    final curso = _curso(_cursos.indexWhere((c) => c.$1 == 'pediatria'));
    return SeguirViendo(
      cursoId: curso.id,
      cursoTitulo: curso.titulo,
      clase: curso.modulos.first.clases[1],
    );
  }
}
