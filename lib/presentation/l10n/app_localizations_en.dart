// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ventana_titulo => 'Supertonic-AudioBook — File to audio converter';

  @override
  String get ajustes => 'Settings';

  @override
  String get tema => 'Theme';

  @override
  String get idioma => 'Language';

  @override
  String get claro => 'Light';

  @override
  String get oscuro => 'Dark';

  @override
  String get estilo => 'Style';

  @override
  String get estilo_material => 'Material (current)';

  @override
  String get estilo_neumorfismo => 'Neumorphism';

  @override
  String get estilo_skeuomorfismo => 'Skeuomorphism';

  @override
  String get acerca_de => 'About';

  @override
  String get acerca_descripcion =>
      'Turn your Markdown books into audiobooks with synthetic speech: 100 % local, no cloud, no GPU.';

  @override
  String get acerca_version => 'Version';

  @override
  String get acerca_licencia => 'MIT License';

  @override
  String get acerca_creditos =>
      'Speech model: Supertonic 3, by Supertone Inc. (OpenRAIL-M license)';

  @override
  String get acerca_ver_modelo => 'View the model on Hugging Face';

  @override
  String get acerca_ver_codigo => 'Model source code';

  @override
  String get cerrar => 'Close';

  @override
  String get tab_entrada => 'Input & output';

  @override
  String get tab_sintesis => 'Synthesis & log';

  @override
  String get salida_audio => 'Audio output';

  @override
  String get carpeta_origen => 'Source folder';

  @override
  String get etiqueta_carpeta => 'Folder:';

  @override
  String get examinar => 'Browse…';

  @override
  String get archivos_encontrados => 'Files Found';

  @override
  String get todo => 'All';

  @override
  String get nada => 'None';

  @override
  String get refrescar => 'Refresh';

  @override
  String get ayuda_seleccion => 'Check the ones you want\nnone checked = all';

  @override
  String get opciones_sintesis => 'Synthesis options';

  @override
  String get formato => 'Format';

  @override
  String get voz => 'Voice';

  @override
  String get modelo_supertonic => 'supertonic-3 model';

  @override
  String get pasos => 'Steps';

  @override
  String get calidad_lento => 'more quality = slower';

  @override
  String get velocidad => 'Speed';

  @override
  String get rapido_lento => 'faster / slower';

  @override
  String get idioma_voz => 'Voice language';

  @override
  String get idioma_voz_auto => 'Auto (no language)';

  @override
  String get escuchar => 'Listen';

  @override
  String get muestra_texto => 'This is a sample of the synthetic voice.';

  @override
  String log_muestra(String voz, String lang) {
    return '    Generating sample of voice $voz ($lang)...';
  }

  @override
  String get log_muestra_fin => '    Sample ready. Playing...';

  @override
  String get log_muestra_error => '    Could not generate or play the sample.';

  @override
  String get registro => 'Log';

  @override
  String get btn_procesar => 'Process';

  @override
  String get btn_cancelar => 'Cancel';

  @override
  String get estado_listo => 'Ready.';

  @override
  String estado_archivo(int i, int n, String nombre) {
    return 'File $i of $n: $nombre';
  }

  @override
  String estado_segmentos(int actual, int total) {
    return '$actual/$total segments synthesized';
  }

  @override
  String estado_listo_n(int n, String tiempo) {
    return 'Done: $n file(s) in $tiempo.';
  }

  @override
  String get estado_cancelando =>
      'Cancelling (exports what was generated so far)…';

  @override
  String get estado_cancelado => 'Cancelled by the user.';

  @override
  String get estado_error => 'Error.';

  @override
  String estado_con_errores(int exitos, int total, int errores) {
    return 'Finished with errors: $exitos/$total OK, $errores error(s).';
  }

  @override
  String get snackbar_formato => 'Choose at least one output format.';

  @override
  String get snackbar_sin_md => 'There are no .md files in the input folder.';

  @override
  String snackbar_procesado(int n, String tiempo) {
    return '$n file(s) processed in $tiempo.';
  }

  @override
  String get snackbar_exportado => 'Exported what was generated so far.';

  @override
  String snackbar_con_errores(int exitos, int errores, String tiempo) {
    return '$exitos processed, $errores error(s) in $tiempo.';
  }

  @override
  String conteo_seleccionados(int sel, int total) {
    return '$sel/$total selected';
  }

  @override
  String conteo_archivos(int total) {
    return '$total files';
  }

  @override
  String get conteo_sin => 'No files';

  @override
  String log_inicio(int sel, int total) {
    return '▶ Start: $sel file(s) selected of $total available.';
  }

  @override
  String get log_formato_no_ok =>
      'Could not start: no output format was chosen.';

  @override
  String get log_sin_md =>
      'Could not start: the input folder has no .md files.';

  @override
  String get log_cancelar =>
      '■ Cancellation requested: what was generated so far will be exported.';

  @override
  String get log_config_titulo => '  CONFIGURATION';

  @override
  String log_config_voz(String voz, int pasos, String vel) {
    return '    Voice: $voz   Steps: $pasos   Speed: $vel';
  }

  @override
  String log_config_lang(String lang) {
    return '    Voice language: $lang';
  }

  @override
  String log_config_formatos(String formatos) {
    return '    Formats: $formatos';
  }

  @override
  String log_config_salida(String salida) {
    return '    Output: $salida';
  }

  @override
  String log_archivo(int i, int n, String nombre) {
    return '▶ File $i/$n: $nombre';
  }

  @override
  String log_segmento(int actual, int total) {
    return '      Segment $actual/$total synthesized…';
  }

  @override
  String log_archivo_fin(int i, int n) {
    return '✔ File $i/$n finished.';
  }

  @override
  String log_archivo_omitido(int i, int n, String nombre) {
    return '⏭ File $i/$n skipped: $nombre (no audio content).';
  }

  @override
  String log_archivo_error(int i, int n, String nombre) {
    return '✖ File $i/$n failed: $nombre (could not be read).';
  }

  @override
  String log_completado(int n, String tiempo) {
    return '✔ PROCESSING COMPLETED: $n file(s) in $tiempo.';
  }

  @override
  String log_con_errores(int errores, int total) {
    return 'Finished with $errores error(s) out of $total file(s).';
  }

  @override
  String log_cancelado(String tiempo) {
    return '✖ Processing cancelled by the user after $tiempo.';
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
  String get modelo_titulo => 'Voice model';

  @override
  String get modelo_aviso =>
      'The first run downloads the voice model (~400 MB). It is a one-time, resumable download stored on your device.';

  @override
  String get modelo_descargar => 'Download model';

  @override
  String get modelo_verificando => 'Verifying the model…';

  @override
  String get modelo_cancelar => 'Cancel';

  @override
  String modelo_progreso(int bytes, int total) {
    return '$bytes MB of $total MB';
  }

  @override
  String modelo_error(String error) {
    return 'Download error: $error';
  }

  @override
  String get splash_descripcion => 'Turn your Markdown books into audiobooks';

  @override
  String get onboarding_titulo => 'How to generate audio';

  @override
  String get onboarding_saltar => 'Skip';

  @override
  String get onboarding_anterior => 'Back';

  @override
  String get onboarding_siguiente => 'Next';

  @override
  String get onboarding_empezar => 'Get started';

  @override
  String get onboarding_paso1_titulo => 'Download the voice model';

  @override
  String get onboarding_paso1_descripcion =>
      'On the first run the app downloads a local voice model (~400 MB). It is a one-time, resumable download.';

  @override
  String get onboarding_paso2_titulo => 'Select your files';

  @override
  String get onboarding_paso2_descripcion =>
      'Choose the folder with your Markdown books. The app scans it and lists every file ready to convert.';

  @override
  String get onboarding_paso3_titulo => 'Pick a voice';

  @override
  String get onboarding_paso3_descripcion =>
      'Choose the voice you like and listen to a sample before you start.';

  @override
  String get onboarding_paso4_titulo => 'Process the audio';

  @override
  String get onboarding_paso4_descripcion =>
      'Run the conversion. Each chapter is read aloud and exported as audio on your device.';

  @override
  String get onboarding_paso5_titulo => 'Choose where to save';

  @override
  String get onboarding_paso5_descripcion =>
      'Select the folder where your audiobooks will be saved. You can change it later from Settings.';

  @override
  String get onboarding_paso5_examinar => 'Browse folder…';

  @override
  String onboarding_paso5_ruta(String ruta) {
    return 'Folder: $ruta';
  }

  @override
  String get dashboard_titulo => 'Supertonic';

  @override
  String get dashboard_bienvenida => 'What do you want to do today?';

  @override
  String get dashboard_bienvenida_sub => 'Pick an option and get started.';

  @override
  String get dashboard_procesar => 'Convert files to audio';

  @override
  String get dashboard_procesar_desc =>
      'Pick a folder, choose a voice and export your Markdown books as audio.';

  @override
  String get dashboard_procesar_sueltos => 'Process loose files';

  @override
  String get dashboard_procesar_sueltos_desc =>
      'Pick one or more .md files from anywhere and convert them to audio.';

  @override
  String get dashboard_biblioteca => 'Library';

  @override
  String get dashboard_biblioteca_desc =>
      'Listen again to the audiobooks you\'ve already generated.';

  @override
  String get dashboard_modelos => 'Models';

  @override
  String get dashboard_modelo_descargar => 'Download model';

  @override
  String get dashboard_modelo_descargando => 'downloading…';

  @override
  String get dashboard_modelo_descargado => 'downloaded';

  @override
  String get dashboard_modelo_sin_descargar => 'not downloaded';

  @override
  String get dashboard_modelo_verificando => 'checking…';

  @override
  String get carpetas => 'Folders';

  @override
  String get settings_carpeta_salida => 'Output folder';

  @override
  String settings_carpeta_salida_ruta(String ruta) {
    return 'Path: $ruta';
  }

  @override
  String get settings_carpeta_salida_cambiar => 'Change folder…';

  @override
  String get seleccion_titulo => 'Process loose files';

  @override
  String get seleccion_sin_archivos => 'You haven\'t picked any files yet.';

  @override
  String get seleccion_buscando => 'Opening the file picker…';

  @override
  String get seleccion_elegir => 'Pick files…';

  @override
  String get seleccion_agregar => 'Add more';

  @override
  String get seleccion_quitar => 'Remove';

  @override
  String get seleccion_error_picker => 'Could not open the file picker.';

  @override
  String get seleccion_modelo_aviso =>
      'The voice model is not downloaded yet. You need to download it before processing these files.';

  @override
  String get seleccion_ir_modelo => 'Go download the model';

  @override
  String get biblioteca_titulo => 'Library';

  @override
  String get biblioteca_vacio => 'You haven\'t generated any audiobooks yet.';

  @override
  String get biblioteca_vacio_accion => 'Go convert';

  @override
  String get biblioteca_play => 'Play';

  @override
  String get biblioteca_pausa => 'Pause';

  @override
  String biblioteca_error(String error) {
    return 'Could not play: $error';
  }

  @override
  String get btn_carpeta => 'Folder';

  @override
  String get btn_archivos => 'Files';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_biblioteca => 'Library';

  @override
  String get nav_settings => 'Settings';
}
