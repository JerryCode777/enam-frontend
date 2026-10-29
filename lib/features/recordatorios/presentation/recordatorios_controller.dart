import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/notificador.dart';
import '../domain/recordatorios.dart';

final notificadorProvider = Provider<Notificador>((ref) {
  if (AppConfig.useMocks) return NotificadorNulo();
  return NotificadorLocal();
});

/// Lo que ve Ajustes 9.2: lo elegido y si el sistema deja mostrar avisos.
class EstadoDeRecordatorios {
  const EstadoDeRecordatorios({
    this.ajustes = const AjustesDeRecordatorio(),
    this.permitidos = false,
  });

  final AjustesDeRecordatorio ajustes;
  final bool permitidos;

  /// Encendido de verdad: lo eligió y el sistema lo deja.
  bool get encendido => ajustes.activo && permitidos;
}

/// De dónde salió la decisión sobre el permiso (`notif_permiso.origen`).
enum OrigenDelPermiso {
  /// «¿Te recuerdo practicar cada día?», tras la primera sesión terminada.
  prePantalla('pre_pantalla'),
  ajustes('ajustes');

  const OrigenDelPermiso(this.codigo);

  final String codigo;
}

/// Los recordatorios locales: guarda lo elegido, pide el permiso cuando toca y
/// vuelve a programar cada vez que cambia algo que afecta al texto o la hora.
class RecordatoriosController extends AsyncNotifier<EstadoDeRecordatorios> {
  static const _activo = 'recordatorio_activo';
  static const _hora = 'recordatorio_hora';
  static const _minuto = 'recordatorio_minuto';
  static const _preguntado = 'recordatorio_preguntado';
  static const _ultimaPractica = 'recordatorio_ultima_practica_ms';
  static const _cupoAgotado = 'recordatorio_cupo_agotado_ms';

  Notificador get _notificador => ref.read(notificadorProvider);
  Analitica get _analitica => ref.read(analiticaProvider);

  @override
  Future<EstadoDeRecordatorios> build() async {
    final prefs = await SharedPreferences.getInstance();
    return EstadoDeRecordatorios(
      ajustes: AjustesDeRecordatorio(
        activo: prefs.getBool(_activo) ?? false,
        hora: prefs.getInt(_hora) ?? AjustesDeRecordatorio.horaPorDefecto,
        minuto: prefs.getInt(_minuto) ?? 0,
      ),
      permitidos: await _permitidos(),
    );
  }

  Future<bool> _permitidos() async {
    try {
      return await _notificador.permitidos();
    } catch (_) {
      return false;
    }
  }

  /// Si toca la pantalla previa: nunca se mostró, y no está ya encendido.
  Future<bool> debePreguntar() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_preguntado) ?? false) return false;
    final estado = await future;
    return !estado.encendido;
  }

  /// La persona dijo que sí: en la pantalla previa o en Ajustes.
  ///
  /// Pide el permiso al sistema (que solo muestra su diálogo la primera vez) y
  /// lo respeta: si dice que no, queda apagado y no se insiste. Devuelve si
  /// quedó encendido.
  Future<bool> activar(OrigenDelPermiso origen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preguntado, true);

    bool concedido;
    try {
      concedido = await _notificador.pedirPermiso();
    } catch (_) {
      concedido = false;
    }
    _analitica.registrar(
      Evento.notifPermiso,
      propiedades: {
        'respuesta': concedido ? 'concedido' : 'denegado',
        'origen': origen.codigo,
      },
    );
    if (!concedido) {
      state = AsyncData(
        EstadoDeRecordatorios(
          ajustes: (await future).ajustes.copyWith(activo: false),
        ),
      );
      return false;
    }

    await prefs.setBool(_activo, true);
    final ajustes = (await future).ajustes.copyWith(activo: true);
    state = AsyncData(
      EstadoDeRecordatorios(ajustes: ajustes, permitidos: true),
    );
    _registrarDiario(ajustes);
    await reprogramar();
    return true;
  }

  /// «Ahora no» en la pantalla previa: no se vuelve a preguntar.
  Future<void> rechazarPrePantalla() async {
    // Primero la medición: guardar puede tardar, y la decisión ya está tomada.
    _analitica.registrar(
      Evento.notifPermiso,
      propiedades: {
        'respuesta': 'ahora_no',
        'origen': OrigenDelPermiso.prePantalla.codigo,
      },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preguntado, true);
  }

  Future<void> apagar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activo, false);
    final estado = await future;
    state = AsyncData(
      EstadoDeRecordatorios(
        ajustes: estado.ajustes.copyWith(activo: false),
        permitidos: estado.permitidos,
      ),
    );
    await _reemplazar(const []);
  }

  Future<void> cambiarHora(int hora, int minuto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hora, hora);
    await prefs.setInt(_minuto, minuto);
    final estado = await future;
    final ajustes = estado.ajustes.copyWith(hora: hora, minuto: minuto);
    state = AsyncData(
      EstadoDeRecordatorios(ajustes: ajustes, permitidos: estado.permitidos),
    );
    if (estado.encendido) {
      _registrarDiario(ajustes);
      await reprogramar();
    }
  }

  /// Terminó una sesión: hoy ya practicó, así que hoy no se le recuerda.
  Future<void> sesionTerminada({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _ultimaPractica,
      (ahora ?? DateTime.now()).millisecondsSinceEpoch,
    );
    await reprogramar(ahora: ahora);
  }

  /// Topó el cupo gratis de hoy: mañana temprano, «tu cupo gratis se renovó».
  Future<void> cupoAgotado({DateTime? ahora}) async {
    final momento = ahora ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final antes = prefs.getInt(_cupoAgotado);
    await prefs.setInt(_cupoAgotado, momento.millisecondsSinceEpoch);

    final estado = await future;
    if (!estado.encendido) return;
    final yaHoy =
        antes != null &&
        _mismoDia(DateTime.fromMillisecondsSinceEpoch(antes), momento);
    if (!yaHoy) {
      _analitica.registrar(
        Evento.notifProgramada,
        propiedades: {'tipo': TipoDeAviso.cupo.codigo},
      );
    }
    await reprogramar(ahora: momento);
  }

  /// Vuelve a calcular y programar los avisos. Se llama al abrir la app, al
  /// volver a ella, al terminar una sesión y al cambiar algo en Ajustes.
  Future<void> reprogramar({DateTime? ahora}) async {
    final estado = await future;
    final permitidos = await _permitidos();
    if (permitidos != estado.permitidos) {
      state = AsyncData(
        EstadoDeRecordatorios(ajustes: estado.ajustes, permitidos: permitidos),
      );
    }
    if (!estado.ajustes.activo || !permitidos) {
      await _reemplazar(const []);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    DateTime? fecha(String clave) => switch (prefs.getInt(clave)) {
      final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
      null => null,
    };

    await _reemplazar(
      planDeAvisos(
        ahora: ahora ?? DateTime.now(),
        ajustes: estado.ajustes,
        ultimaPractica: fecha(_ultimaPractica),
        cupoAgotadoEl: fecha(_cupoAgotado),
        racha: ref.read(dashboardProvider).value?.racha?.dias,
        fechaExamen: ref.read(currentUserProvider)?.fechaObjetivo,
        preguntasGratis: ref.read(cupoGratisProvider)?.preguntasPorDia,
      ),
    );
  }

  Future<void> _reemplazar(List<AvisoProgramado> avisos) async {
    try {
      await _notificador.reemplazar(avisos);
    } catch (_) {
      // Un fallo del sistema al programar no puede romper la pantalla.
    }
  }

  void _registrarDiario(AjustesDeRecordatorio ajustes) => _analitica.registrar(
    Evento.notifProgramada,
    propiedades: {'tipo': TipoDeAviso.diario.codigo, 'hora': '${ajustes.hora}'},
  );

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final recordatoriosProvider =
    AsyncNotifierProvider<RecordatoriosController, EstadoDeRecordatorios>(
      RecordatoriosController.new,
    );

/// El aviso que se tocó y todavía no se atendió (`diario:racha`…). Lo atiende
/// la app cuando hay sesión: tocar un aviso con la sesión cerrada lleva al
/// login, y después al destino.
class AvisoTocado extends Notifier<String?> {
  @override
  String? build() => null;

  void tocado(String payload) => state = payload;

  void atendido() => state = null;
}

final avisoTocadoProvider = NotifierProvider<AvisoTocado, String?>(
  AvisoTocado.new,
);

/// Las propiedades de `notif_abierta` para un `payload`, o `null` si no es
/// uno de los nuestros.
Map<String, String>? propiedadesDeAbierta(String payload) {
  final partes = payload.split(':');
  if (partes.length != 2) return null;
  final tipo = TipoDeAviso.values.where((t) => t.codigo == partes[0]);
  final variante = VarianteDeAviso.values.where((v) => v.codigo == partes[1]);
  if (tipo.isEmpty || variante.isEmpty) return null;
  return {'tipo': tipo.first.codigo, 'variante': variante.first.codigo};
}
