import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @ventana_titulo.
  ///
  /// In en, this message translates to:
  /// **'Supertonic-AudioBook — File to audio converter'**
  String get ventana_titulo;

  /// No description provided for @ajustes.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get ajustes;

  /// No description provided for @tema.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get tema;

  /// No description provided for @idioma.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get idioma;

  /// No description provided for @claro.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get claro;

  /// No description provided for @oscuro.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get oscuro;

  /// No description provided for @estilo.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get estilo;

  /// No description provided for @estilo_material.
  ///
  /// In en, this message translates to:
  /// **'Material (current)'**
  String get estilo_material;

  /// No description provided for @estilo_neumorfismo.
  ///
  /// In en, this message translates to:
  /// **'Neumorphism'**
  String get estilo_neumorfismo;

  /// No description provided for @estilo_skeuomorfismo.
  ///
  /// In en, this message translates to:
  /// **'Skeuomorphism'**
  String get estilo_skeuomorfismo;

  /// No description provided for @acerca_de.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get acerca_de;

  /// No description provided for @acerca_descripcion.
  ///
  /// In en, this message translates to:
  /// **'Turn your Markdown books into audiobooks with synthetic speech: 100 % local, no cloud, no GPU.'**
  String get acerca_descripcion;

  /// No description provided for @acerca_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get acerca_version;

  /// No description provided for @acerca_licencia.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get acerca_licencia;

  /// No description provided for @acerca_creditos.
  ///
  /// In en, this message translates to:
  /// **'Speech model: Supertonic 3, by Supertone Inc. (OpenRAIL-M license)'**
  String get acerca_creditos;

  /// No description provided for @acerca_ver_modelo.
  ///
  /// In en, this message translates to:
  /// **'View the model on Hugging Face'**
  String get acerca_ver_modelo;

  /// No description provided for @acerca_ver_codigo.
  ///
  /// In en, this message translates to:
  /// **'Model source code'**
  String get acerca_ver_codigo;

  /// No description provided for @cerrar.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cerrar;

  /// No description provided for @tab_entrada.
  ///
  /// In en, this message translates to:
  /// **'Input & output'**
  String get tab_entrada;

  /// No description provided for @tab_sintesis.
  ///
  /// In en, this message translates to:
  /// **'Synthesis & log'**
  String get tab_sintesis;

  /// No description provided for @salida_audio.
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get salida_audio;

  /// No description provided for @carpeta_origen.
  ///
  /// In en, this message translates to:
  /// **'Source folder'**
  String get carpeta_origen;

  /// No description provided for @etiqueta_carpeta.
  ///
  /// In en, this message translates to:
  /// **'Folder:'**
  String get etiqueta_carpeta;

  /// No description provided for @examinar.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get examinar;

  /// No description provided for @archivos_encontrados.
  ///
  /// In en, this message translates to:
  /// **'Files Found'**
  String get archivos_encontrados;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get todo;

  /// No description provided for @nada.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get nada;

  /// No description provided for @refrescar.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refrescar;

  /// No description provided for @ayuda_seleccion.
  ///
  /// In en, this message translates to:
  /// **'Check the ones you want\nnone checked = all'**
  String get ayuda_seleccion;

  /// No description provided for @opciones_sintesis.
  ///
  /// In en, this message translates to:
  /// **'Synthesis options'**
  String get opciones_sintesis;

  /// No description provided for @formato.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formato;

  /// No description provided for @voz.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voz;

  /// No description provided for @modelo_supertonic.
  ///
  /// In en, this message translates to:
  /// **'supertonic-3 model'**
  String get modelo_supertonic;

  /// No description provided for @pasos.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get pasos;

  /// No description provided for @calidad_lento.
  ///
  /// In en, this message translates to:
  /// **'more quality = slower'**
  String get calidad_lento;

  /// No description provided for @velocidad.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get velocidad;

  /// No description provided for @rapido_lento.
  ///
  /// In en, this message translates to:
  /// **'faster / slower'**
  String get rapido_lento;

  /// No description provided for @idioma_voz.
  ///
  /// In en, this message translates to:
  /// **'Voice language'**
  String get idioma_voz;

  /// No description provided for @idioma_voz_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto (no language)'**
  String get idioma_voz_auto;

  /// No description provided for @escuchar.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get escuchar;

  /// No description provided for @muestra_texto.
  ///
  /// In en, this message translates to:
  /// **'This is a sample of the synthetic voice.'**
  String get muestra_texto;

  /// Log when generating the voice sample for Listen.
  ///
  /// In en, this message translates to:
  /// **'    Generating sample of voice {voz} ({lang})...'**
  String log_muestra(String voz, String lang);

  /// No description provided for @log_muestra_fin.
  ///
  /// In en, this message translates to:
  /// **'    Sample ready. Playing...'**
  String get log_muestra_fin;

  /// No description provided for @log_muestra_error.
  ///
  /// In en, this message translates to:
  /// **'    Could not generate or play the sample.'**
  String get log_muestra_error;

  /// No description provided for @registro.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get registro;

  /// No description provided for @btn_procesar.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get btn_procesar;

  /// No description provided for @btn_cancelar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btn_cancelar;

  /// No description provided for @estado_listo.
  ///
  /// In en, this message translates to:
  /// **'Ready.'**
  String get estado_listo;

  /// No description provided for @estado_archivo.
  ///
  /// In en, this message translates to:
  /// **'File {i} of {n}: {nombre}'**
  String estado_archivo(int i, int n, String nombre);

  /// No description provided for @estado_segmentos.
  ///
  /// In en, this message translates to:
  /// **'{actual}/{total} segments synthesized'**
  String estado_segmentos(int actual, int total);

  /// No description provided for @estado_listo_n.
  ///
  /// In en, this message translates to:
  /// **'Done: {n} file(s) in {tiempo}.'**
  String estado_listo_n(int n, String tiempo);

  /// No description provided for @estado_cancelando.
  ///
  /// In en, this message translates to:
  /// **'Cancelling (exports what was generated so far)…'**
  String get estado_cancelando;

  /// No description provided for @estado_cancelado.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the user.'**
  String get estado_cancelado;

  /// No description provided for @estado_error.
  ///
  /// In en, this message translates to:
  /// **'Error.'**
  String get estado_error;

  /// No description provided for @estado_con_errores.
  ///
  /// In en, this message translates to:
  /// **'Finished with errors: {exitos}/{total} OK, {errores} error(s).'**
  String estado_con_errores(int exitos, int total, int errores);

  /// No description provided for @snackbar_formato.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one output format.'**
  String get snackbar_formato;

  /// No description provided for @snackbar_sin_md.
  ///
  /// In en, this message translates to:
  /// **'There are no .md files in the input folder.'**
  String get snackbar_sin_md;

  /// No description provided for @snackbar_procesado.
  ///
  /// In en, this message translates to:
  /// **'{n} file(s) processed in {tiempo}.'**
  String snackbar_procesado(int n, String tiempo);

  /// No description provided for @snackbar_exportado.
  ///
  /// In en, this message translates to:
  /// **'Exported what was generated so far.'**
  String get snackbar_exportado;

  /// No description provided for @snackbar_con_errores.
  ///
  /// In en, this message translates to:
  /// **'{exitos} processed, {errores} error(s) in {tiempo}.'**
  String snackbar_con_errores(int exitos, int errores, String tiempo);

  /// No description provided for @conteo_seleccionados.
  ///
  /// In en, this message translates to:
  /// **'{sel}/{total} selected'**
  String conteo_seleccionados(int sel, int total);

  /// No description provided for @conteo_archivos.
  ///
  /// In en, this message translates to:
  /// **'{total} files'**
  String conteo_archivos(int total);

  /// No description provided for @conteo_sin.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get conteo_sin;

  /// No description provided for @log_inicio.
  ///
  /// In en, this message translates to:
  /// **'▶ Start: {sel} file(s) selected of {total} available.'**
  String log_inicio(int sel, int total);

  /// No description provided for @log_formato_no_ok.
  ///
  /// In en, this message translates to:
  /// **'Could not start: no output format was chosen.'**
  String get log_formato_no_ok;

  /// No description provided for @log_sin_md.
  ///
  /// In en, this message translates to:
  /// **'Could not start: the input folder has no .md files.'**
  String get log_sin_md;

  /// No description provided for @log_cancelar.
  ///
  /// In en, this message translates to:
  /// **'■ Cancellation requested: what was generated so far will be exported.'**
  String get log_cancelar;

  /// No description provided for @log_config_titulo.
  ///
  /// In en, this message translates to:
  /// **'  CONFIGURATION'**
  String get log_config_titulo;

  /// No description provided for @log_config_voz.
  ///
  /// In en, this message translates to:
  /// **'    Voice: {voz}   Steps: {pasos}   Speed: {vel}'**
  String log_config_voz(String voz, int pasos, String vel);

  /// No description provided for @log_config_lang.
  ///
  /// In en, this message translates to:
  /// **'    Voice language: {lang}'**
  String log_config_lang(String lang);

  /// No description provided for @log_config_formatos.
  ///
  /// In en, this message translates to:
  /// **'    Formats: {formatos}'**
  String log_config_formatos(String formatos);

  /// No description provided for @log_config_salida.
  ///
  /// In en, this message translates to:
  /// **'    Output: {salida}'**
  String log_config_salida(String salida);

  /// No description provided for @log_archivo.
  ///
  /// In en, this message translates to:
  /// **'▶ File {i}/{n}: {nombre}'**
  String log_archivo(int i, int n, String nombre);

  /// No description provided for @log_segmento.
  ///
  /// In en, this message translates to:
  /// **'      Segment {actual}/{total} synthesized…'**
  String log_segmento(int actual, int total);

  /// No description provided for @log_archivo_fin.
  ///
  /// In en, this message translates to:
  /// **'✔ File {i}/{n} finished.'**
  String log_archivo_fin(int i, int n);

  /// No description provided for @log_archivo_omitido.
  ///
  /// In en, this message translates to:
  /// **'⏭ File {i}/{n} skipped: {nombre} (no audio content).'**
  String log_archivo_omitido(int i, int n, String nombre);

  /// No description provided for @log_archivo_error.
  ///
  /// In en, this message translates to:
  /// **'✖ File {i}/{n} failed: {nombre} (could not be read).'**
  String log_archivo_error(int i, int n, String nombre);

  /// No description provided for @log_completado.
  ///
  /// In en, this message translates to:
  /// **'✔ PROCESSING COMPLETED: {n} file(s) in {tiempo}.'**
  String log_completado(int n, String tiempo);

  /// No description provided for @log_con_errores.
  ///
  /// In en, this message translates to:
  /// **'Finished with {errores} error(s) out of {total} file(s).'**
  String log_con_errores(int errores, int total);

  /// No description provided for @log_cancelado.
  ///
  /// In en, this message translates to:
  /// **'✖ Processing cancelled by the user after {tiempo}.'**
  String log_cancelado(String tiempo);

  /// No description provided for @log_error.
  ///
  /// In en, this message translates to:
  /// **'✖ ERROR: {texto}'**
  String log_error(String texto);

  /// No description provided for @tiempo_seg.
  ///
  /// In en, this message translates to:
  /// **'{total} s'**
  String tiempo_seg(int total);

  /// No description provided for @tiempo_min_seg.
  ///
  /// In en, this message translates to:
  /// **'{min} min {seg} s'**
  String tiempo_min_seg(int min, int seg);

  /// No description provided for @tiempo_hora_min.
  ///
  /// In en, this message translates to:
  /// **'{horas} h {min} min'**
  String tiempo_hora_min(int horas, int min);

  /// No description provided for @modelo_titulo.
  ///
  /// In en, this message translates to:
  /// **'Voice model'**
  String get modelo_titulo;

  /// No description provided for @modelo_aviso.
  ///
  /// In en, this message translates to:
  /// **'The first run downloads the voice model (~400 MB). It is a one-time, resumable download stored on your device.'**
  String get modelo_aviso;

  /// No description provided for @modelo_descargar.
  ///
  /// In en, this message translates to:
  /// **'Download model'**
  String get modelo_descargar;

  /// No description provided for @modelo_verificando.
  ///
  /// In en, this message translates to:
  /// **'Verifying the model…'**
  String get modelo_verificando;

  /// No description provided for @modelo_cancelar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get modelo_cancelar;

  /// No description provided for @modelo_progreso.
  ///
  /// In en, this message translates to:
  /// **'{bytes} MB of {total} MB'**
  String modelo_progreso(int bytes, int total);

  /// No description provided for @modelo_error.
  ///
  /// In en, this message translates to:
  /// **'Download error: {error}'**
  String modelo_error(String error);

  /// No description provided for @splash_descripcion.
  ///
  /// In en, this message translates to:
  /// **'Turn your Markdown books into audiobooks'**
  String get splash_descripcion;

  /// No description provided for @onboarding_titulo.
  ///
  /// In en, this message translates to:
  /// **'How to generate audio'**
  String get onboarding_titulo;

  /// No description provided for @onboarding_saltar.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_saltar;

  /// No description provided for @onboarding_anterior.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboarding_anterior;

  /// No description provided for @onboarding_siguiente.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboarding_siguiente;

  /// No description provided for @onboarding_empezar.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboarding_empezar;

  /// No description provided for @onboarding_paso1_titulo.
  ///
  /// In en, this message translates to:
  /// **'Download the voice model'**
  String get onboarding_paso1_titulo;

  /// No description provided for @onboarding_paso1_descripcion.
  ///
  /// In en, this message translates to:
  /// **'On the first run the app downloads a local voice model (~400 MB). It is a one-time, resumable download.'**
  String get onboarding_paso1_descripcion;

  /// No description provided for @onboarding_paso2_titulo.
  ///
  /// In en, this message translates to:
  /// **'Select your files'**
  String get onboarding_paso2_titulo;

  /// No description provided for @onboarding_paso2_descripcion.
  ///
  /// In en, this message translates to:
  /// **'Choose the folder with your Markdown books. The app scans it and lists every file ready to convert.'**
  String get onboarding_paso2_descripcion;

  /// No description provided for @onboarding_paso3_titulo.
  ///
  /// In en, this message translates to:
  /// **'Pick a voice'**
  String get onboarding_paso3_titulo;

  /// No description provided for @onboarding_paso3_descripcion.
  ///
  /// In en, this message translates to:
  /// **'Choose the voice you like and listen to a sample before you start.'**
  String get onboarding_paso3_descripcion;

  /// No description provided for @onboarding_paso4_titulo.
  ///
  /// In en, this message translates to:
  /// **'Process the audio'**
  String get onboarding_paso4_titulo;

  /// No description provided for @onboarding_paso4_descripcion.
  ///
  /// In en, this message translates to:
  /// **'Run the conversion. Each chapter is read aloud and exported as audio on your device.'**
  String get onboarding_paso4_descripcion;

  /// No description provided for @dashboard_titulo.
  ///
  /// In en, this message translates to:
  /// **'Supertonic'**
  String get dashboard_titulo;

  /// No description provided for @dashboard_bienvenida.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do today?'**
  String get dashboard_bienvenida;

  /// No description provided for @dashboard_procesar.
  ///
  /// In en, this message translates to:
  /// **'Convert files to audio'**
  String get dashboard_procesar;

  /// No description provided for @dashboard_procesar_desc.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder, choose a voice and export your Markdown books as audio.'**
  String get dashboard_procesar_desc;

  /// No description provided for @dashboard_opcion2.
  ///
  /// In en, this message translates to:
  /// **'Process loose files'**
  String get dashboard_opcion2;

  /// No description provided for @dashboard_opcion2_desc.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more .md files from anywhere and convert them to audio.'**
  String get dashboard_opcion2_desc;

  /// No description provided for @dashboard_opcion3.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get dashboard_opcion3;

  /// No description provided for @dashboard_opcion3_desc.
  ///
  /// In en, this message translates to:
  /// **'New features are on their way.'**
  String get dashboard_opcion3_desc;

  /// No description provided for @dashboard_modelos.
  ///
  /// In en, this message translates to:
  /// **'Models: '**
  String get dashboard_modelos;

  /// No description provided for @dashboard_modelo_descargado.
  ///
  /// In en, this message translates to:
  /// **'downloaded'**
  String get dashboard_modelo_descargado;

  /// No description provided for @dashboard_modelo_sin_descargar.
  ///
  /// In en, this message translates to:
  /// **'not downloaded'**
  String get dashboard_modelo_sin_descargar;

  /// No description provided for @dashboard_modelo_verificando.
  ///
  /// In en, this message translates to:
  /// **'checking…'**
  String get dashboard_modelo_verificando;

  /// No description provided for @carpetas.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get carpetas;

  /// No description provided for @seleccion_titulo.
  ///
  /// In en, this message translates to:
  /// **'Process loose files'**
  String get seleccion_titulo;

  /// No description provided for @seleccion_sin_archivos.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t picked any files yet.'**
  String get seleccion_sin_archivos;

  /// No description provided for @seleccion_buscando.
  ///
  /// In en, this message translates to:
  /// **'Opening the file picker…'**
  String get seleccion_buscando;

  /// No description provided for @seleccion_elegir.
  ///
  /// In en, this message translates to:
  /// **'Pick files…'**
  String get seleccion_elegir;

  /// No description provided for @seleccion_agregar.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get seleccion_agregar;

  /// No description provided for @seleccion_quitar.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get seleccion_quitar;

  /// No description provided for @seleccion_error_picker.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker.'**
  String get seleccion_error_picker;

  /// No description provided for @seleccion_modelo_aviso.
  ///
  /// In en, this message translates to:
  /// **'The voice model is not downloaded yet. You need to download it before processing these files.'**
  String get seleccion_modelo_aviso;

  /// No description provided for @seleccion_ir_modelo.
  ///
  /// In en, this message translates to:
  /// **'Go download the model'**
  String get seleccion_ir_modelo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
