// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get ventana_titulo =>
      'Supertonic-AudioBook — Conversor de archivos a audio';

  @override
  String get ajustes => 'Ajustes';

  @override
  String get tema => 'Tema';

  @override
  String get idioma => 'Idioma';

  @override
  String get claro => 'Claro';

  @override
  String get oscuro => 'Oscuro';

  @override
  String get estilo => 'Estilo';

  @override
  String get estilo_material => 'Material (actual)';

  @override
  String get estilo_neumorfismo => 'Neumorfismo';

  @override
  String get estilo_skeuomorfismo => 'Skeuomorfismo';

  @override
  String get acerca_de => 'Acerca de';

  @override
  String get acerca_descripcion =>
      'Convierte tus libros Markdown en audiolibros con voz sintética: 100 % local, sin nube y sin GPU.';

  @override
  String get acerca_version => 'Versión';

  @override
  String get acerca_licencia => 'Licencia MIT';

  @override
  String get acerca_creditos =>
      'Modelo de voz: Supertonic 3, de Supertone Inc. (licencia OpenRAIL-M)';

  @override
  String get acerca_ver_modelo => 'Ver el modelo en Hugging Face';

  @override
  String get acerca_ver_codigo => 'Código fuente del modelo';

  @override
  String get cerrar => 'Cerrar';

  @override
  String get tab_entrada => 'Entrada y salida';

  @override
  String get tab_sintesis => 'Síntesis y registro';

  @override
  String get salida_audio => 'Salida de audio';

  @override
  String get carpeta_origen => 'Carpeta de origen';

  @override
  String get etiqueta_carpeta => 'Carpeta:';

  @override
  String get examinar => 'Examinar…';

  @override
  String get archivos_encontrados => 'Archivos Encontrados';

  @override
  String get archivos_seleccionados => 'Archivos Seleccionados';

  @override
  String get todo => 'Todo';

  @override
  String get nada => 'Nada';

  @override
  String get refrescar => 'Refrescar';

  @override
  String get ayuda_seleccion => 'Marcá los que querés\nsin marcas = todos';

  @override
  String get opciones_sintesis => 'Opciones de síntesis';

  @override
  String get formato => 'Formato';

  @override
  String get voz => 'Voz';

  @override
  String get modelo_supertonic => 'Modelo supertonic-3';

  @override
  String get pasos => 'Pasos';

  @override
  String get calidad_lento => 'más calidad = más lento';

  @override
  String get velocidad => 'Velocidad';

  @override
  String get rapido_lento => 'más rápido / más lento';

  @override
  String get idioma_voz => 'Idioma de la voz';

  @override
  String get idioma_voz_auto => 'Auto (sin idioma)';

  @override
  String get escuchar => 'Escuchar';

  @override
  String get muestra_texto => 'Esta es una muestra de la voz sintética.';

  @override
  String log_muestra(String voz, String lang) {
    return '    Generando muestra de voz $voz ($lang)...';
  }

  @override
  String get log_muestra_fin => '    Muestra lista. Reproduciendo...';

  @override
  String get log_muestra_error =>
      '    No se pudo generar o reproducir la muestra.';

  @override
  String get registro => 'Registro';

  @override
  String get btn_procesar => 'Procesar';

  @override
  String get btn_cancelar => 'Cancelar';

  @override
  String get estado_listo => 'Listo.';

  @override
  String estado_archivo(int i, int n, String nombre) {
    return 'Archivo $i de $n: $nombre';
  }

  @override
  String estado_segmentos(int actual, int total) {
    return '$actual/$total segmentos sintetizados';
  }

  @override
  String estado_listo_n(int n, String tiempo) {
    return 'Listo: $n archivo(s) en $tiempo.';
  }

  @override
  String get estado_cancelando =>
      'Cancelando (exporta lo generado hasta ahora)…';

  @override
  String get estado_cancelado => 'Cancelado por el usuario.';

  @override
  String get estado_error => 'Error.';

  @override
  String estado_con_errores(int exitos, int total, int errores) {
    return 'Completado con errores: $exitos/$total OK, $errores error/es.';
  }

  @override
  String get snackbar_formato => 'Elegí al menos un formato de salida.';

  @override
  String get snackbar_sin_md => 'No hay archivos .md en la carpeta de entrada.';

  @override
  String snackbar_procesado(int n, String tiempo) {
    return 'Se procesaron $n archivo(s) en $tiempo.';
  }

  @override
  String get snackbar_exportado => 'Se exportó lo generado hasta el momento.';

  @override
  String snackbar_con_errores(int exitos, int errores, String tiempo) {
    return '$exitos procesado(s), $errores error(es) en $tiempo.';
  }

  @override
  String conteo_seleccionados(int sel, int total) {
    return '$sel/$total seleccionados';
  }

  @override
  String conteo_archivos(int total) {
    return '$total archivos';
  }

  @override
  String get conteo_sin => 'Sin archivos';

  @override
  String log_inicio(int sel, int total) {
    return '▶ Inicio: $sel archivo(s) seleccionado(s) de $total disponible(s).';
  }

  @override
  String get log_formato_no_ok =>
      'No se pudo iniciar: no se eligió ningún formato de salida.';

  @override
  String get log_sin_md =>
      'No se pudo iniciar: la carpeta de entrada no tiene archivos .md.';

  @override
  String get log_cancelar =>
      '■ Cancelación solicitada: se exporta lo generado hasta el momento.';

  @override
  String get log_config_titulo => '  CONFIGURACIÓN';

  @override
  String log_config_voz(String voz, int pasos, String vel) {
    return '    Voz: $voz   Pasos: $pasos   Velocidad: $vel';
  }

  @override
  String log_config_lang(String lang) {
    return '    Idioma de la voz: $lang';
  }

  @override
  String log_config_formatos(String formatos) {
    return '    Formatos: $formatos';
  }

  @override
  String log_config_salida(String salida) {
    return '    Salida: $salida';
  }

  @override
  String log_archivo(int i, int n, String nombre) {
    return '▶ Archivo $i/$n: $nombre';
  }

  @override
  String log_segmento(int actual, int total) {
    return '      Segmento $actual/$total sintetizado…';
  }

  @override
  String log_archivo_fin(int i, int n) {
    return '✔ Archivo $i/$n terminado.';
  }

  @override
  String log_archivo_omitido(int i, int n, String nombre) {
    return '⏭ Archivo $i/$n omitido: $nombre (sin contenido de audio).';
  }

  @override
  String log_archivo_error(int i, int n, String nombre) {
    return '✖ Archivo $i/$n con error: $nombre (no se pudo leer).';
  }

  @override
  String log_completado(int n, String tiempo) {
    return '✔ PROCESAMIENTO COMPLETADO: $n archivo(s) en $tiempo.';
  }

  @override
  String log_con_errores(int errores, int total) {
    return 'Finalizado con $errores error(es) de $total archivo(s).';
  }

  @override
  String log_cancelado(String tiempo) {
    return '✖ Procesamiento cancelado por el usuario tras $tiempo.';
  }

  @override
  String log_error(String texto) {
    return '✖ ERROR: $texto';
  }

  @override
  String tiempo_seg(int total) {
    return '$total s';
  }

  @override
  String tiempo_min_seg(int min, int seg) {
    return '$min min $seg s';
  }

  @override
  String tiempo_hora_min(int horas, int min) {
    return '$horas h $min min';
  }

  @override
  String get modelo_titulo => 'Modelo de voz';

  @override
  String get modelo_aviso =>
      'La primera vez se descarga el modelo de voz (~400 MB). Es una sola vez, resumible, y queda guardado en tu equipo.';

  @override
  String get modelo_descargar => 'Descargar modelo';

  @override
  String get modelo_verificando => 'Verificando el modelo…';

  @override
  String get modelo_cancelar => 'Cancelar';

  @override
  String modelo_progreso(int bytes, int total) {
    return '$bytes MB de $total MB';
  }

  @override
  String modelo_error(String error) {
    return 'Error de descarga: $error';
  }

  @override
  String get splash_descripcion =>
      'Convierte tus libros en Markdown a audiolibros';

  @override
  String get onboarding_titulo => 'Cómo generar audio';

  @override
  String get onboarding_saltar => 'Omitir';

  @override
  String get onboarding_anterior => 'Atrás';

  @override
  String get onboarding_siguiente => 'Siguiente';

  @override
  String get onboarding_empezar => 'Comenzar';

  @override
  String get onboarding_paso1_titulo => 'Descarga el modelo de voz';

  @override
  String get onboarding_paso1_descripcion =>
      'En la primera ejecución la app descarga un modelo de voz local (~400 MB). Es una sola vez y se puede reanudar.';

  @override
  String get onboarding_paso2_titulo => 'Selecciona tus archivos';

  @override
  String get onboarding_paso2_descripcion =>
      'Elige la carpeta con tus libros en Markdown. La app la escanea y lista cada archivo listo para convertir.';

  @override
  String get onboarding_paso3_titulo => 'Elige una voz';

  @override
  String get onboarding_paso3_descripcion =>
      'Selecciona la voz que prefieras y escucha una muestra antes de empezar.';

  @override
  String get onboarding_paso4_titulo => 'Procesa el audio';

  @override
  String get onboarding_paso4_descripcion =>
      'Ejecuta la conversión. Cada capítulo se lee en voz alta y se exporta como audio en tu dispositivo.';

  @override
  String get onboarding_paso5_titulo => 'Elegí dónde guardar';

  @override
  String get onboarding_paso5_descripcion =>
      'Seleccioná la carpeta donde se guardarán tus audiolibros. Podés cambiarla después desde Ajustes.';

  @override
  String get onboarding_paso5_examinar => 'Examinar carpeta…';

  @override
  String onboarding_paso5_ruta(String ruta) {
    return 'Carpeta: $ruta';
  }

  @override
  String get dashboard_titulo => 'Supertonic';

  @override
  String get dashboard_bienvenida => '¿Qué quieres hacer hoy?';

  @override
  String get dashboard_bienvenida_sub => 'Elegí una función y empezá.';

  @override
  String get dashboard_procesar => 'Convertir archivos a audio';

  @override
  String get dashboard_procesar_desc =>
      'Elige una carpeta, una voz y exporta tus libros en Markdown como audio.';

  @override
  String get dashboard_procesar_sueltos => 'Procesar archivos sueltos';

  @override
  String get dashboard_procesar_sueltos_desc =>
      'Elegí uno o más archivos .md de cualquier lugar y convertilos en audio.';

  @override
  String get home_seleccionar_fuente => '¿Qué querés convertir?';

  @override
  String get home_seleccionar_carpeta => 'Seleccionar carpeta';

  @override
  String get home_seleccionar_carpeta_desc =>
      'Elegí una carpeta con archivos .md para convertir';

  @override
  String get home_seleccionar_archivos => 'Seleccionar archivos';

  @override
  String get home_seleccionar_archivos_desc =>
      'Elegí uno o más archivos .md sueltos';

  @override
  String get dashboard_biblioteca => 'Biblioteca';

  @override
  String get dashboard_biblioteca_desc =>
      'Volvé a escuchar los audiolibros que ya generaste.';

  @override
  String get dashboard_modelos => 'Modelos';

  @override
  String get dashboard_modelo_descargar => 'Descargar modelo';

  @override
  String get dashboard_modelo_descargando => 'descargando…';

  @override
  String get dashboard_modelo_descargado => 'descargado';

  @override
  String get dashboard_modelo_sin_descargar => 'sin descargar';

  @override
  String get dashboard_modelo_verificando => 'verificando…';

  @override
  String get carpetas => 'Carpetas';

  @override
  String get settings_carpeta_salida => 'Carpeta de salida';

  @override
  String settings_carpeta_salida_ruta(String ruta) {
    return 'Ruta: $ruta';
  }

  @override
  String get settings_carpeta_salida_cambiar => 'Cambiar carpeta…';

  @override
  String get seleccion_titulo => 'Procesar archivos sueltos';

  @override
  String get seleccion_sin_archivos => 'Todavía no elegiste archivos.';

  @override
  String get seleccion_buscando => 'Abriendo el buscador de archivos…';

  @override
  String get seleccion_elegir => 'Elegir archivos…';

  @override
  String get seleccion_agregar => 'Agregar más';

  @override
  String get seleccion_quitar => 'Quitar';

  @override
  String get seleccion_error_picker =>
      'No se pudo abrir el buscador de archivos.';

  @override
  String get seleccion_modelo_aviso =>
      'El modelo de voz todavía no está descargado. Para procesar estos archivos primero tenés que descargarlo.';

  @override
  String get seleccion_ir_modelo => 'Ir a descargar el modelo';

  @override
  String get biblioteca_titulo => 'Biblioteca';

  @override
  String get biblioteca_vacio => 'Todavía no generaste ningún audiolibro.';

  @override
  String get biblioteca_vacio_accion => 'Ir a convertir';

  @override
  String get biblioteca_play => 'Reproducir';

  @override
  String get biblioteca_pausa => 'Pausar';

  @override
  String biblioteca_error(String error) {
    return 'No se pudo reproducir: $error';
  }

  @override
  String get btn_carpeta => 'Carpeta';

  @override
  String get btn_archivos => 'Archivos';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_biblioteca => 'Biblioteca';

  @override
  String get nav_settings => 'Configuración';

  @override
  String get home_proximamente => 'Próximamente';

  @override
  String get home_proximamente_desc =>
      'Esta función estará disponible en una próxima versión.';

  @override
  String get home_editor_voz => 'Editor de voz';

  @override
  String get home_editor_voz_desc =>
      'Edita y personaliza las voces de tus audiolibros.';

  @override
  String get home_editor_metadata => 'Editor de metadatos';

  @override
  String get home_editor_metadata_desc =>
      'Edita los metadatos de tus archivos MP3.';

  @override
  String get editor_metadata_seleccionar => 'Seleccionar archivo MP3';

  @override
  String get editor_metadata_sin_archivo =>
      'Seleccioná un archivo MP3 para editar sus metadatos.';

  @override
  String get editor_metadata_titulo_campo => 'Título';

  @override
  String get editor_metadata_artista_campo => 'Artista';

  @override
  String get editor_metadata_album_campo => 'Álbum';

  @override
  String get editor_metadata_pista_campo => 'Pista';

  @override
  String get editor_metadata_disco_campo => 'Disco';

  @override
  String get editor_metadata_anio_campo => 'Año';

  @override
  String get editor_metadata_genero_campo => 'Género';

  @override
  String get editor_metadata_comentario_campo => 'Comentario';

  @override
  String get editor_metadata_cover_art => 'Portada';

  @override
  String get editor_metadata_cambiar_portada => 'Cambiar portada';

  @override
  String get editor_metadata_quitar_portada => 'Quitar portada';

  @override
  String get editor_metadata_guardar => 'Guardar';

  @override
  String get editor_metadata_cancelar => 'Cancelar';

  @override
  String get editor_metadata_exito => 'Metadatos guardados correctamente.';

  @override
  String get editor_metadata_error_lectura =>
      'No se pudo leer los metadatos del archivo.';

  @override
  String get editor_metadata_error_escritura =>
      'No se pudieron guardar los metadatos.';

  @override
  String get editor_metadata_error_portada =>
      'La portada debe ser JPEG y no superar 500KB.';

  @override
  String get benchmark_titulo => 'Benchmark del motor';

  @override
  String get benchmark_subtitle =>
      'Mide la velocidad de tu motor TTS con textos de prueba.';

  @override
  String get benchmark_sin_datos =>
      'Sin datos. Ejecutá un benchmark para ver resultados.';

  @override
  String get benchmark_btn_ejecutar => 'Ejecutar benchmark';

  @override
  String get benchmark_btn_cancelar => 'Cancelar';

  @override
  String benchmark_progreso(int paso, int tamanio) {
    return 'Paso $paso/6 — $tamanio caracteres';
  }

  @override
  String benchmark_ultima_corrida(String fecha) {
    return 'Última corrida: $fecha';
  }

  @override
  String benchmark_avg_chars_sec(String valor) {
    return '$valor chars/s';
  }

  @override
  String get benchmark_tab_tamano => 'Tamaño';

  @override
  String get benchmark_tab_tiempo => 'Tiempo';

  @override
  String get benchmark_tab_chars_seg => 'Chars/seg';

  @override
  String get benchmark_estimacion_label => 'Tiempo estimado para tu texto:';

  @override
  String benchmark_estimacion_valor(String tiempo) {
    return '~$tiempo';
  }

  @override
  String get benchmark_modelo_no_listo =>
      'El modelo de voz no está descargado. Descargalo primero desde Ajustes.';

  @override
  String get benchmark_seleccionar_tamanios => 'Seleccionar tamaños de prueba';

  @override
  String get historial_titulo => 'Historial de conversiones';

  @override
  String get historial_vacio => 'Sin conversiones registradas';

  @override
  String get historial_col_palabras => 'Palabras';

  @override
  String get historial_col_segmentos => 'Segmentos';

  @override
  String get historial_col_duracion => 'Duración';
}
