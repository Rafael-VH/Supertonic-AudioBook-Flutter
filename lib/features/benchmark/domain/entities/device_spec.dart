/// Especificación del dispositivo donde se ejecutó un benchmark.
///
/// Entidad pura de dominio: captura las características de hardware
/// (marca, modelo, placa, chip y RAM) que identifican el dispositivo.
/// Todos los campos son opcionales porque en algunas plataformas (iOS)
/// ciertos valores no están disponibles.
class DeviceSpec {
  const DeviceSpec({
    this.brand,
    this.model,
    this.board,
    this.hardware,
    this.ramBytes,
  });

  /// Marca del fabricante (p. ej. "Google", "Apple").
  final String? brand;

  /// Modelo comercial del dispositivo (p. ej. "Pixel 8", "iPhone 15").
  final String? model;

  /// Nombre de la placa (Android: `board`; iOS: null).
  final String? board;

  /// Nombre del chip/hardware (Android: `hardware`; iOS: null).
  final String? hardware;

  /// Cantidad de RAM en bytes.
  final int? ramBytes;

  /// Serializa a un `Map` plano con claves snake_case.
  Map<String, Object?> toMap() => {
        'brand': brand,
        'model': model,
        'board': board,
        'hardware': hardware,
        'ram_bytes': ramBytes,
      };

  /// Deserializa desde un `Map` plano. Claves ausentes o null → null.
  factory DeviceSpec.fromMap(Map<String, Object?> map) => DeviceSpec(
        brand: map['brand'] as String?,
        model: map['model'] as String?,
        board: map['board'] as String?,
        hardware: map['hardware'] as String?,
        ramBytes: (map['ram_bytes'] as num?)?.toInt(),
      );
}
