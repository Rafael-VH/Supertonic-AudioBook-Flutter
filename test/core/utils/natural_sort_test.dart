import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/core/utils/natural_sort.dart';

void main() {
  group('naturalSortKey', () {
    test('ordena números como ints (10 antes que 9)', () {
      final claveA = naturalSortKey('cap10');
      final claveB = naturalSortKey('cap9');
      expect(compararNaturalSortKey(claveA, claveB), greaterThan(0));
      expect(compararNaturalSortKey(claveB, claveA), lessThan(0));
    });

    test('números que desbordan int64 no lanzan y se ordenan por valor', () {
      final grande = '9' * 20;
      final masGrande = '${'9' * 19}8';
      final claveA = naturalSortKey('cap_$grande');
      final claveB = naturalSortKey('cap_$masGrande');

      // 999…98 (19 dígitos) < 999…99 (20 dígitos): comparación numérica, no
      // lexicográfica (donde el de 19 dígitos sería "mayor" por longitud).
      expect(compararNaturalSortKey(claveB, claveA), lessThan(0));
      expect(compararNaturalSortKey(claveA, claveB), greaterThan(0));
    });

    test('19 dígitos en el límite de int64 no lanzan (9223372036854775808)',
        () {
      final maxInt64 = '9223372036854775807';
      final desborda = '9223372036854775808';
      final claveA = naturalSortKey('cap_$maxInt64');
      final claveB = naturalSortKey('cap_$desborda');

      expect(compararNaturalSortKey(claveA, claveB), lessThan(0));
      expect(compararNaturalSortKey(claveB, claveA), greaterThan(0));
    });

    test('token int y token que desborda: el que cabe en int64 va primero',
        () {
      final clavePeque = naturalSortKey('cap_2');
      final claveGrande = naturalSortKey('cap_19999999999999999999');

      // 2 < 19999999999999999999: no debe comparar "2" > "1" como texto.
      expect(compararNaturalSortKey(clavePeque, claveGrande), lessThan(0));
      expect(compararNaturalSortKey(claveGrande, clavePeque), greaterThan(0));
    });

    test('mezcla texto y número conservando el orden por tokens', () {
      final claves = ['a10', 'a2', 'a1'].map(naturalSortKey).toList();
      claves.sort(compararNaturalSortKey);
      expect(claves.map((c) => c.stem), ['a1', 'a2', 'a10']);
    });

    test(
        'stem que arranca con número que desborda int64 se agrupa como '
        'número, no como texto', () {
      // El primer token es BigInt (no int): el discriminador debe ser 0 para
      // no separar '9223372036854775808_cap' de los demás prefijos numéricos.
      final claveBig = naturalSortKey('9223372036854775808_cap');
      expect(claveBig.discriminador, 0);
      expect(claveBig.tokens.first, isA<BigInt>());

      final claves = ['9223372036854775808_cap', '1_cap', 'b_cap']
          .map(naturalSortKey)
          .toList();
      claves.sort(compararNaturalSortKey);
      // Números (incluido el BigInt) antes que texto, ordenados por valor.
      expect(
        claves.map((c) => c.stem),
        ['1_cap', '9223372036854775808_cap', 'b_cap'],
      );
    });
  });
}
