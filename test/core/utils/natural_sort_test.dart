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

    test('números de más de 19 dígitos no lanzan y se comparan como texto',
        () {
      final grande = '9' * 20;
      final masGrande = '${'9' * 19}8';
      final claveA = naturalSortKey('cap_$grande');
      final claveB = naturalSortKey('cap_$masGrande');

      // No debe lanzar FormatException: se compara como String.
      expect(() => compararNaturalSortKey(claveA, claveB), returnsNormally);
    });

    test('mezcla texto y número conservando el orden por tokens', () {
      final claves = ['a10', 'a2', 'a1'].map(naturalSortKey).toList();
      claves.sort(compararNaturalSortKey);
      expect(claves.map((c) => c.stem), ['a1', 'a2', 'a10']);
    });
  });
}
