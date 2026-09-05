import 'package:equatable/equatable.dart';

/// Audio temporal pendiente de confirmar en el Audio Manager.
class AudioPendiente extends Equatable {
  final String tempPath;
  final String displayName;
  final String format;
  final double durationSec;
  final int fileSizeBytes;

  const AudioPendiente({
    required this.tempPath,
    required this.displayName,
    required this.format,
    required this.durationSec,
    required this.fileSizeBytes,
  });

  AudioPendiente copyWith({String? displayName}) {
    return AudioPendiente(
      tempPath: tempPath,
      displayName: displayName ?? this.displayName,
      format: format,
      durationSec: durationSec,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  List<Object?> get props => [tempPath, displayName, format, durationSec, fileSizeBytes];
}
