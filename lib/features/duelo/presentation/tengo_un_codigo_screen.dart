import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/enam_button.dart';

/// La tercera puerta: escribir el PIN que te dieron.
///
/// # Por qué existe
///
/// Porque el enlace no siempre llega. WhatsApp e Instagram abren los enlaces en
/// su propio navegador, **que no comparte la sesión de la app**: quien toca el
/// enlace ahí aterriza sin cuenta, y el reto se pierde por el camino sin que
/// ninguno de los dos entienda por qué.
///
/// Un PIN de seis caracteres se dicta en voz alta, se escribe aquí, y eso deja
/// de pasar. Y para dos personas sentadas al lado —que es el caso más común—
/// mandarse un mensaje para jugar juntas era absurdo desde el principio.
class TengoUnCodigoScreen extends ConsumerStatefulWidget {
  const TengoUnCodigoScreen({super.key});

  @override
  ConsumerState<TengoUnCodigoScreen> createState() =>
      _TengoUnCodigoScreenState();
}

class _TengoUnCodigoScreenState extends ConsumerState<TengoUnCodigoScreen> {
  final _control = TextEditingController();
  bool _entrando = false;
  String? _error;

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tengo un código')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            Text(
              'Escribe el código que te dieron',
              style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Son seis caracteres y caduca a los 10 minutos.',
              style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: DesignTokens.space6),
            TextField(
              controller: _control,
              autofocus: true,
              // En mayúsculas y sin autocorrector: el código se dicta, y el
              // teclado predictivo lo convertía en una palabra.
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: texto.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                _AMayusculas(),
              ],
              decoration: InputDecoration(
                hintText: 'K7M2QX',
                errorText: _error,
                counterText: '',
              ),
              onSubmitted: (_) => unawaited(_entrar()),
            ),
            const SizedBox(height: DesignTokens.space5),
            EnamButton(
              label: 'Entrar al duelo',
              loading: _entrando,
              onPressed: _control.text.trim().length < 4
                  ? null
                  : () => unawaited(_entrar()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _entrar() async {
    final codigo = _control.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    setState(() {
      _entrando = true;
      _error = null;
    });

    try {
      final duelo = await ref
          .read(dueloRepositoryProvider)
          .unirsePorCodigo(codigo);
      if (!mounted) return;
      context.pushReplacement(Routes.dueloPartidaOf(duelo.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}

/// El código se guarda en mayúsculas: así lo compara el servidor.
class _AMayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) => nuevo.copyWith(text: nuevo.text.toUpperCase());
}
