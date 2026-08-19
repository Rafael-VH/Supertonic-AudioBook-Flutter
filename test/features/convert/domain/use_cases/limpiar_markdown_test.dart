import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/limpiar_markdown.dart';

void main() {
  group('limpiarMarkdown', () {
    test('quita títulos', () {
      expect(limpiarMarkdown('# Título'), 'Título');
      expect(limpiarMarkdown('## Subtítulo'), 'Subtítulo');
    });

    test('quita negrita, cursiva y código inline', () {
      expect(
        limpiarMarkdown('**negrita** _cursiva_ `codigo`'),
        'negrita cursiva codigo',
      );
    });

    test('quita links e imágenes', () {
      expect(limpiarMarkdown('[texto](https://x.com)'), 'texto');
      expect(limpiarMarkdown('![alt](img.png)'), 'alt');
    });

    test('quita blockquotes y listas', () {
      expect(
        limpiarMarkdown('> cita\n- item1\n- item2'),
        'cita\nitem1\nitem2',
      );
    });

    test('quita bloques de código', () {
      expect(
        limpiarMarkdown('antes\n```python\nprint(1)\n```\ndespues'),
        'antes\n\ndespues',
      );
    });

    test('quita bloques tilde', () {
      expect(
        limpiarMarkdown('antes\n~~~\ncodigo\n~~~\ndespues'),
        'antes\n\ndespues',
      );
    });

    test('normaliza saltos y recorta', () {
      expect(limpiarMarkdown('  hola\n\n\n\nmundo  '), 'hola\n\nmundo');
    });

    test('la prosa con operadores no se altera', () {
      const texto = '2 + 3 = 5\na * b = c';
      expect(limpiarMarkdown(texto), texto);
    });

    test('las multiplicaciones con espacios no se alteran', () {
      const texto = '2 * 3 * 4 = 24';
      expect(limpiarMarkdown(texto), texto);
    });

    test('los underscores no comen snake_case', () {
      expect(
        limpiarMarkdown('clave_privada_valor'),
        'clave_privada_valor',
      );
      expect(limpiarMarkdown('2 __ 3 = 5'), '2 __ 3 = 5');
      expect(limpiarMarkdown('texto _cursiva_ fin'), 'texto cursiva fin');
    });

    test('los HR de guiones espaciados no se mutilan', () {
      expect(limpiarMarkdown('- - -'), '');
      expect(limpiarMarkdown('- item'), 'item');
    });

    test('los HR con más de tres marcadores se quitan', () {
      expect(limpiarMarkdown('----'), '');
      expect(limpiarMarkdown('****'), '');
      expect(limpiarMarkdown('- - - -'), '');
      expect(limpiarMarkdown('* * * *'), '');
    });

    test('los operadores de asterisco sin espacios no se alteran', () {
      const texto = 'a*b*c\n5*4*3=60\napp*util*main';
      expect(limpiarMarkdown(texto), texto);
    });

    test('la negrita pegada a una palabra no se mutila', () {
      expect(limpiarMarkdown('**a**b'), '**a**b');
      expect(limpiarMarkdown('la **mejor**opcion'), 'la **mejor**opcion');
      expect(limpiarMarkdown('a**b**c'), 'a**b**c');
      expect(limpiarMarkdown('***a***b'), '***a***b');
      expect(
        limpiarMarkdown('**Nota:***esto* es clave'),
        '**Nota:***esto* es clave',
      );
    });

    test('los comparadores y flechas no se alteran', () {
      const texto = '5 > 3\na -> b';
      expect(limpiarMarkdown(texto), texto);
    });

    test('quita listas ordenadas', () {
      expect(
        limpiarMarkdown('1. primero\n2. segundo'),
        'primero\nsegundo',
      );
    });

    test('el HR solo se quita en línea completa', () {
      expect(limpiarMarkdown('a---b'), 'a---b');
      expect(limpiarMarkdown('x***y'), 'x***y');
      expect(limpiarMarkdown('---'), '');
      expect(limpiarMarkdown('* * *'), '');
    });

    test('la negrita dentro de un bloque de código no se toca', () {
      expect(
        limpiarMarkdown('antes\n```\n**no_negrita**\n```\ndespues'),
        'antes\n\ndespues',
      );
    });
  });
}
