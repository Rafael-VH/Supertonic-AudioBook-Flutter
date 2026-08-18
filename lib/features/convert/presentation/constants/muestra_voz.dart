/// Texto y nombres de idiomas de voz — valores EXACTOS (plan §6.4, paridad
/// con `app/presentation/gui.py`).
library;

/// Texto de muestra por idioma de voz (los idiomas sin entrada usan la clave
/// `muestra_texto` del idioma de la interfaz).
const textoMuestraIdiomas = {
  'es': 'Hola, soy la voz de Supertonic. Esta es una muestra de audio.',
  'en': 'Hello, I am a Supertonic voice. This is an audio sample.',
  'fr': 'Bonjour, je suis une voix Supertonic. Ceci est un échantillon audio.',
  'de': 'Hallo, ich bin eine Supertonic-Stimme. Das ist eine Audioprobe.',
  'pt': 'Olá, eu sou uma voz Supertonic. Esta é uma amostra de áudio.',
  'it': 'Ciao, sono una voce Supertonic. Questo è un campione audio.',
  'nl': 'Hallo, ik ben een Supertonic-stem. Dit is een audiofragment.',
  'pl': 'Cześć, jestem głosem Supertonic. To jest próbka audio.',
  'ru': 'Привет, я голос Supertonic. Это образец аудио.',
  'uk': 'Привіт, я голос Supertonic. Це зразок аудіо.',
  'tr': 'Merhaba, ben bir Supertonic sesiyim. Bu bir ses örneğidir.',
  'ja': 'こんにちは、Supertonicの音声です。オーディオサンプルです。',
  'ko': '안녕하세요, Supertonic 음성입니다. 오디오 샘플입니다.',
  'ar': 'مرحباً، أنا صوت سوبرتونيك. هذه عينة صوتية.',
  'hi': 'नमस्ते, मैं Supertonic आवाज़ हूँ। यह एक ऑडियो नमूना है।',
  'vi': 'Xin chào, tôi là giọng nói Supertonic. Đây là mẫu âm thanh.',
};

/// Nombre nativo de cada idioma de voz (`na` se traduce con la clave de UI
/// `idioma_voz_auto`).
const idiomasVozNativos = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'pt': 'Português',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ru': 'Русский',
  'uk': 'Українська',
  'tr': 'Türkçe',
  'ar': 'العربية',
  'hi': 'हिन्दी',
  'ko': '한국어',
  'ja': '日本語',
  'bg': 'Български',
  'cs': 'Čeština',
  'da': 'Dansk',
  'el': 'Ελληνικά',
  'et': 'Eesti',
  'fi': 'Suomi',
  'hr': 'Hrvatski',
  'hu': 'Magyar',
  'id': 'Bahasa Indonesia',
  'lt': 'Lietuvių',
  'lv': 'Latviešu',
  'ro': 'Română',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'sv': 'Svenska',
  'vi': 'Tiếng Việt',
};
