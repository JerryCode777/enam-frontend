import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import '../domain/recordatorios.dart';

/// Habla con el sistema para mostrar avisos: permiso, programar y toques.
///
/// No decide nada: qué avisar y cuándo lo decide [planDeAvisos].
abstract interface class Notificador {
  /// Prepara el plugin y el huso horario. [alTocar] recibe el `payload` del
  /// aviso que se tocó con la app abierta o en segundo plano.
  Future<void> iniciar({required void Function(String payload) alTocar});

  /// El `payload` del aviso que abrió la app desde cerrada, si fue uno.
  Future<String?> payloadDeArranque();

  /// Pide el permiso al sistema. `true` si quedó concedido. Si el sistema ya
  /// había decidido antes, no muestra nada y devuelve lo que había.
  Future<bool> pedirPermiso();

  /// Si hoy se pueden mostrar avisos (la persona pudo apagarlos en Ajustes
  /// del teléfono).
  Future<bool> permitidos();

  /// Deja programados exactamente [avisos]: borra antes los propios que
  /// hubiera ([idsPropios]).
  Future<void> reemplazar(List<AvisoProgramado> avisos);
}

class NotificadorLocal implements Notificador {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _canal = AndroidNotificationDetails(
    'recordatorios',
    'Recordatorios de estudio',
    channelDescription:
        'El recordatorio diario y el aviso de que se renovó tu cupo gratis.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_notificacion',
  );

  static const _detalles = NotificationDetails(
    android: _canal,
    iOS: DarwinNotificationDetails(),
  );

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> iniciar({required void Function(String payload) alTocar}) async {
    tzdatos.initializeTimeZones();
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {
      // Sin zona conocida, Lima: es donde está casi todo el público.
      tz.setLocalLocation(tz.getLocation('America/Lima'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notificacion'),
        // El permiso NO se pide al iniciar: se pide en contexto, después de
        // la primera sesión terminada y de nuestra propia pantalla.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final p? when p.isNotEmpty) alTocar(p);
      },
    );
  }

  @override
  Future<String?> payloadDeArranque() async {
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    if (detalles?.didNotificationLaunchApp != true) return null;
    return detalles?.notificationResponse?.payload;
  }

  @override
  Future<bool> pedirPermiso() async {
    if (_android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool> permitidos() async {
    if (_android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final opciones = await ios?.checkPermissions();
    return opciones?.isEnabled ?? false;
  }

  @override
  Future<void> reemplazar(List<AvisoProgramado> avisos) async {
    for (final id in idsPropios) {
      await _plugin.cancel(id: id);
    }
    for (final a in avisos) {
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.titulo,
        body: a.cuerpo,
        payload: a.payload,
        scheduledDate: tz.TZDateTime.from(a.cuando, tz.local),
        notificationDetails: _detalles,
        // Sin alarma exacta: unos minutos tarde no importan, y así no hace
        // falta pedir SCHEDULE_EXACT_ALARM (que Play revisa).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// No muestra nada: con datos de ejemplo y en las pruebas.
class NotificadorNulo implements Notificador {
  @override
  Future<void> iniciar({
    required void Function(String payload) alTocar,
  }) async {}

  @override
  Future<String?> payloadDeArranque() async => null;

  @override
  Future<bool> pedirPermiso() async => false;

  @override
  Future<bool> permitidos() async => false;

  @override
  Future<void> reemplazar(List<AvisoProgramado> avisos) async {}
}
