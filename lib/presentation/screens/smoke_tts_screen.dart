import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supertonic_audiobook/data/helpers/supertonic_helper.dart';
import 'package:supertonic_audiobook/data/modelo/modelo_manager.dart';

/// Smoke de Fase 2 (plan §8): valida que el modelo corre en el target real.
/// Descarga el modelo si falta, sintetiza una oración y la reproduce.
class SmokeTtsScreen extends StatefulWidget {
  const SmokeTtsScreen({super.key});

  @override
  State<SmokeTtsScreen> createState() => _SmokeTtsScreenState();
}

class _SmokeTtsScreenState extends State<SmokeTtsScreen> {
  final _modeloManager = ModeloManager();
  final _audioPlayer = AudioPlayer();
  final _textoController =
      TextEditingController(text: 'Hola, esta es una prueba de síntesis.');

  bool _descargando = false;
  bool _cargando = false;
  bool _sintetizando = false;
  bool _reproduciendo = false;
  String _estado = 'Listo';
  int _bytesDescargados = 0;
  int _bytesTotales = 0;
  double? _rtf;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _reproduciendo = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _estado = 'Reproducción terminada';
          _reproduciendo = false;
        }
      });
    });
  }

  Future<void> _descargarModelo() async {
    setState(() {
      _descargando = true;
      _estado = 'Descargando modelo (~400 MB)…';
      _bytesDescargados = 0;
    });
    try {
      final raiz = await _modeloManager.asegurarModelo(
        onProgreso: (bytes, total, archivo) {
          if (!mounted) return;
          setState(() {
            _bytesDescargados = bytes;
            _bytesTotales = total;
            _estado = 'Descargando $archivo';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _descargando = false;
        _estado = 'Modelo verificado en ${raiz.path}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargando = false;
        _estado = 'Error de descarga: $e';
      });
    }
  }

  Future<void> _sintetizarYReproducir() async {
    if (_cargando || _sintetizando) return;
    setState(() {
      _cargando = true;
      _estado = 'Cargando motor TTS…';
    });

    try {
      final raiz = await _modeloManager.asegurarModelo(
        onProgreso: (bytes, total, archivo) {
          if (!mounted) return;
          setState(() {
            _bytesDescargados = bytes;
            _bytesTotales = total;
            _estado = 'Descargando $archivo';
          });
        },
      );
      final dirOnnx = '${raiz.path}${Platform.pathSeparator}onnx';
      final dirStyles = '${raiz.path}${Platform.pathSeparator}voice_styles';

      if (!mounted) return;
      setState(() {
        _cargando = false;
        _sintetizando = true;
        _estado = 'Cargando sesiones ONNX…';
      });

      final tts = await loadTextToSpeech(dirOnnx);
      final style = await loadVoiceStyle([
        '$dirStyles${Platform.pathSeparator}M1.json',
      ]);

      if (!mounted) return;
      setState(() => _estado = 'Sintetizando…');

      final inicio = DateTime.now();
      final resultado = await tts.call(
        _textoController.text,
        'es',
        style,
        8,
        speed: 1.05,
      );
      final duracionMs =
          DateTime.now().difference(inicio).inMilliseconds;

      final wav = _safeListDouble(resultado['wav']);
      final audioDur = resultado['duration'][0] as double;
      _rtf = audioDur > 0 ? (duracionMs / 1000) / audioDur : null;

      final tempDir = await getTemporaryDirectory();
      final ruta = '${tempDir.path}${Platform.pathSeparator}'
          'smoke_${DateTime.now().millisecondsSinceEpoch}.wav';
      writeWavFile(ruta, wav, tts.sampleRate);

      if (!mounted) return;
      setState(() {
        _sintetizando = false;
        _estado = 'Reproduciendo ${audioDur.toStringAsFixed(2)} s…';
      });

      await _audioPlayer.setFilePath(ruta);
      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _sintetizando = false;
        _estado = 'Error: $e';
      });
    }
  }

  List<double> _safeListDouble(dynamic raw) {
    if (raw is List<double>) return raw;
    if (raw is List) return raw.cast<double>();
    return [];
  }

  @override
  void dispose() {
    _textoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activo = _descargando || _cargando || _sintetizando;
    final progreso = _bytesTotales > 0
        ? (_bytesDescargados / _bytesTotales).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Smoke TTS — Fase 2')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_estado),
              ),
            ),
            if (_descargando) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progreso),
              const SizedBox(height: 4),
              Text(
                '${(_bytesDescargados / 1048576).toStringAsFixed(0)} / '
                '${(_bytesTotales / 1048576).toStringAsFixed(0)} MB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _textoController,
              maxLines: 4,
              enabled: !activo,
              decoration: const InputDecoration(
                labelText: 'Texto a sintetizar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: activo ? null : _descargarModelo,
              icon: const Icon(Icons.download),
              label: const Text('Descargar modelo'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: activo ? null : _sintetizarYReproducir,
              icon: Icon(
                _reproduciendo ? Icons.stop : Icons.play_arrow,
              ),
              label: const Text('Sintetizar y reproducir'),
            ),
            if (_rtf != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'RTF: ${_rtf!.toStringAsFixed(3)} '
                    '(${_rtf! <= 1 ? 'en tiempo real' : 'más lento que real'})',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
