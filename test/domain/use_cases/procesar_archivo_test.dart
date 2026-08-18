import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/convert/domain/use_cases/procesar_archivo.dart';

void main() {
  group('ProcesarArchivo.presupuestoMemoria', () {
    test('en desktop conserva el margen configurado', () {
      final presupuesto = ProcesarArchivo.presupuestoMemoria(
        memoriaSafeMarginBytes: 524288000,
        esMovil: false,
        topeMovil: 67108864,
      );

      expect(presupuesto, 524288000);
    });

    test('en móvil usa el tope menor cuando el margen lo supera', () {
      final presupuesto = ProcesarArchivo.presupuestoMemoria(
        memoriaSafeMarginBytes: 524288000,
        esMovil: true,
        topeMovil: 67108864,
      );

      expect(presupuesto, 67108864);
    });

    test('en móvil conserva el margen si ya es menor que el tope', () {
      final presupuesto = ProcesarArchivo.presupuestoMemoria(
        memoriaSafeMarginBytes: 33554432, // 32 MiB
        esMovil: true,
        topeMovil: 67108864,
      );

      expect(presupuesto, 33554432);
    });
  });
}
