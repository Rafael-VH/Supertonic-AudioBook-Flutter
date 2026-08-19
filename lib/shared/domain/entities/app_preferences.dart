import 'package:equatable/equatable.dart';

import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

/// Typed preferences object replacing `Map<String, Object>` for preference
/// storage. Bundles voice settings with app-level preferences.
class AppPreferences extends Equatable {
  const AppPreferences({
    required this.voiceConfig,
    this.carpetaSalida,
    this.onboardingVisto = false,
    this.modeloState,
    this.modeloPath,
  });

  final VoiceConfig voiceConfig;
  final String? carpetaSalida;
  final bool onboardingVisto;

  /// Model download state: 'descargado', 'no_descargado', or null.
  final String? modeloState;
  final String? modeloPath;

  factory AppPreferences.fromMap(Map<String, Object?> map) {
    return AppPreferences(
      voiceConfig: VoiceConfig(
        voz: map['voz'] as String? ?? 'default',
        steps: (map['steps'] as num?)?.toInt() ?? 32,
        speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
        langVoz: map['langVoz'] as String? ?? 'es',
      ),
      carpetaSalida: map['carpeta_salida'] as String?,
      onboardingVisto: map['onboarding_visto'] as bool? ?? false,
      modeloState: map['modelo_state'] as String?,
      modeloPath: map['modelo_path'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'voz': voiceConfig.voz,
      'steps': voiceConfig.steps,
      'speed': voiceConfig.speed,
      'langVoz': voiceConfig.langVoz,
      'carpeta_salida': carpetaSalida,
      'onboarding_visto': onboardingVisto,
      'modelo_state': modeloState,
      'modelo_path': modeloPath,
    };
  }

  AppPreferences copyWith({
    VoiceConfig? voiceConfig,
    String? carpetaSalida,
    bool? onboardingVisto,
    String? modeloState,
    String? modeloPath,
  }) {
    return AppPreferences(
      voiceConfig: voiceConfig ?? this.voiceConfig,
      carpetaSalida: carpetaSalida ?? this.carpetaSalida,
      onboardingVisto: onboardingVisto ?? this.onboardingVisto,
      modeloState: modeloState ?? this.modeloState,
      modeloPath: modeloPath ?? this.modeloPath,
    );
  }

  @override
  List<Object?> get props => [
        voiceConfig,
        carpetaSalida,
        onboardingVisto,
        modeloState,
        modeloPath,
      ];
}
