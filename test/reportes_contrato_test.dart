import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/features/session/data/reportes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// El contrato acordado con el backend para `POST /questions/{id}/reports`.
void main() {
  test('manda la ruta y el cuerpo acordados, sin campos vacíos', () async {
    final cliente = _Cliente();
    final repo = ApiReportesRepository(cliente);

    final r = await repo.reportar(
      preguntaId: 'q-123',
      motivo: 'clave',
      sessionId: 's-9',
    );

    expect(cliente.ruta, '/questions/q-123/reports');
    expect(cliente.cuerpo, {'motivo': 'clave', 'sessionId': 's-9'});
    expect(r.id, 'rep-1');
    expect(r.estado, 'recibido');
  });

  test('el comentario viaja cuando lo hay', () async {
    final cliente = _Cliente();
    await ApiReportesRepository(
      cliente,
    ).reportar(preguntaId: 'q', motivo: 'texto', comentario: 'Falta la unidad');

    expect(cliente.cuerpo, {
      'motivo': 'texto',
      'comentario': 'Falta la unidad',
    });
  });
}

class _Cliente implements ApiClient {
  String? ruta;
  Object? cuerpo;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Object? cancelToken,
  }) async {
    ruta = path;
    cuerpo = data;
    return {'id': 'rep-1', 'estado': 'recibido'} as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
