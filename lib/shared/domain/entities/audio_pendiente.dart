import 'package:equatable/equatable.dart';

class AudioPendiente extends Equatable {
  final String tempPath;
  final String originalName;
  final String displayName;
  final String format;
  final double durationSec;
  final int fileSizeBytes;
  final int chars;
  final int segments;
  final DateTime fecha;

  const AudioPendiente({
    required this.tempPath,
    required this.originalName,
    required this.displayName,
    required this.format,
    required this.durationSec,
    required this.fileSizeBytes,
    required this.chars,
    required this.segments,
    required this.fecha,
  });

  AudioPendiente copyWith({String? displayName}) {
    return AudioPendiente(
      tempPath: tempPath,
      originalName: originalName,
      displayName: displayName ?? this.displayName,
      format: format,
      durationSec: durationSec,
      fileSizeBytes: fileSizeBytes,
      chars: chars,
      segments: segments,
      fecha: fecha,
    );
  }

  @override
  List<Object?> get props => [tempPath, originalName, displayName, format, durationSec, fileSizeBytes, chars, segments, fecha];
}
