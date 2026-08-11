import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

void main() {
  group('Paleta.para', () {
    test('material claro usa los hex exactos del plan §6.2', () {
      final p = Paleta.para(oscuro: false, estilo: AppEstilo.material);

      expect(p.fondo, const Color(0xFFF4F1FA));
      expect(p.superficie, const Color(0xFFFFFFFF));
      expect(p.superficieVariante, const Color(0xFFE7E0EC));
      expect(p.primario, const Color(0xFF6750A4));
      expect(p.primarioClaro, const Color(0xFFEADDFF));
      expect(p.primarioVivo, const Color(0xFF7B67C8));
      expect(p.sobrePrimario, const Color(0xFFFFFFFF));
      expect(p.texto, const Color(0xFF1C1B1F));
      expect(p.textoSecundario, const Color(0xFF79747E));
      expect(p.borde, const Color(0xFFCAC4D0));
      expect(p.advertencia, const Color(0xFFB45309));
      expect(p.error, const Color(0xFFB3261E));
      expect(p.errorVivo, const Color(0xFFD0453E));
      expect(p.sobreError, const Color(0xFFFFFFFF));
      expect(p.snackbarFondo, const Color(0xFF322F35));
      expect(p.snackbarTexto, const Color(0xFFFFFFFF));
    });

    test('material oscuro usa los hex exactos del plan §6.2', () {
      final p = Paleta.para(oscuro: true, estilo: AppEstilo.material);

      expect(p.fondo, const Color(0xFF141218));
      expect(p.superficie, const Color(0xFF211F26));
      expect(p.superficieVariante, const Color(0xFF49454F));
      expect(p.primario, const Color(0xFFD0BCFF));
      expect(p.primarioClaro, const Color(0xFF4F378B));
      expect(p.primarioVivo, const Color(0xFFBBA6F4));
      expect(p.sobrePrimario, const Color(0xFF381E72));
      expect(p.texto, const Color(0xFFE6E0E9));
      expect(p.textoSecundario, const Color(0xFFCAC4D0));
      expect(p.borde, const Color(0xFF4A4458));
      expect(p.advertencia, const Color(0xFFFDD663));
      expect(p.error, const Color(0xFFF2B8B5));
      expect(p.errorVivo, const Color(0xFFF8C7C4));
      expect(p.sobreError, const Color(0xFF381E72));
      expect(p.snackbarFondo, const Color(0xFFE6E0E9));
      expect(p.snackbarTexto, const Color(0xFF141218));
    });

    test('neumo: superficie coincide con fondo y define biseles', () {
      final claro = Paleta.para(oscuro: false, estilo: AppEstilo.neumo);
      final oscuro = Paleta.para(oscuro: true, estilo: AppEstilo.neumo);

      expect(claro.fondo, claro.superficie);
      expect(claro.fondo, const Color(0xFFE8E4F0));
      expect(claro.luz, const Color(0xFFFDFBFF));
      expect(claro.sombra, const Color(0xFFC2BAD6));
      expect(claro.primarioLuz, const Color(0xFFFFFFFF));
      expect(claro.primarioSombra, const Color(0xFF574E8C));

      expect(oscuro.fondo, const Color(0xFF1C1A23));
      expect(oscuro.superficie, const Color(0xFF1C1A23));
      expect(oscuro.luz, const Color(0xFF302C3C));
      expect(oscuro.sombra, const Color(0xFF0E0C12));
    });

    test('skeuo: acento azul acero y biseles marcados', () {
      final claro = Paleta.para(oscuro: false, estilo: AppEstilo.skeuo);
      final oscuro = Paleta.para(oscuro: true, estilo: AppEstilo.skeuo);

      expect(claro.fondo, const Color(0xFFDEDEDE));
      expect(claro.superficie, const Color(0xFFEBEBEB));
      expect(claro.primario, const Color(0xFF2E6DB4));
      expect(claro.luz, const Color(0xFFFFFFFF));
      expect(claro.sombra, const Color(0xFF7F7F7F));

      expect(oscuro.fondo, const Color(0xFF3C3C3C));
      expect(oscuro.superficie, const Color(0xFF484848));
      expect(oscuro.primario, const Color(0xFF4D8CD6));
      expect(oscuro.luz, const Color(0xFF5C5C5C));
      expect(oscuro.sombra, const Color(0xFF222222));
    });
  });

  group('AppEstilo', () {
    test('desdeId resuelve los tres estilos y cae a material', () {
      expect(AppEstilo.desdeId('material'), AppEstilo.material);
      expect(AppEstilo.desdeId('neumo'), AppEstilo.neumo);
      expect(AppEstilo.desdeId('skeuo'), AppEstilo.skeuo);
      expect(AppEstilo.desdeId(null), AppEstilo.material);
      expect(AppEstilo.desdeId('no_existe'), AppEstilo.material);
    });
  });

  group('construirTema', () {
    test('aplica la paleta como scaffold y colorScheme', () {
      final claro = construirTema(oscuro: false, estilo: AppEstilo.material);
      final oscuro = construirTema(oscuro: true, estilo: AppEstilo.material);

      expect(claro.scaffoldBackgroundColor, const Color(0xFFF4F1FA));
      expect(claro.colorScheme.primary, const Color(0xFF6750A4));
      expect(claro.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(claro.colorScheme.error, const Color(0xFFB3261E));

      expect(oscuro.scaffoldBackgroundColor, const Color(0xFF141218));
      expect(oscuro.colorScheme.primary, const Color(0xFFD0BCFF));
      expect(oscuro.colorScheme.onPrimary, const Color(0xFF381E72));
      expect(oscuro.colorScheme.error, const Color(0xFFF2B8B5));
    });

    test('registra la extensión PaletaExt con el estilo pedido', () {
      final tema = construirTema(oscuro: false, estilo: AppEstilo.neumo);
      final ext = tema.extension<PaletaExt>();

      expect(ext, isNotNull);
      expect(ext!.estilo, AppEstilo.neumo);
      expect(ext.paleta.luz, const Color(0xFFFDFBFF));
    });
  });
}
