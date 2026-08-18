import 'package:equatable/equatable.dart';

/// Value object that bundles the 4 voice-related fields.
///
/// Encapsulates `voz`, `steps`, `speed`, and `langVoz` into a single
/// immutable, equatable unit to reduce parameter coupling across the codebase.
class VoiceConfig extends Equatable {
  const VoiceConfig({
    required this.voz,
    this.steps = 32,
    this.speed = 1.0,
    this.langVoz = 'es',
  });

  final String voz;
  final int steps;
  final double speed;
  final String langVoz;

  VoiceConfig copyWith({
    String? voz,
    int? steps,
    double? speed,
    String? langVoz,
  }) {
    return VoiceConfig(
      voz: voz ?? this.voz,
      steps: steps ?? this.steps,
      speed: speed ?? this.speed,
      langVoz: langVoz ?? this.langVoz,
    );
  }

  @override
  List<Object?> get props => [voz, steps, speed, langVoz];
}
