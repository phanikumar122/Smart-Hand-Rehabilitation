// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'हाथ पुनर्वास';

  @override
  String get appSubtitle => 'हाथों का पुनर्वास';

  @override
  String get settings => 'व्यवस्था';

  @override
  String get language => 'भाषा';

  @override
  String get deviceLanguage => 'उपकरण की भाषा';

  @override
  String get appearance => 'रूप';

  @override
  String get systemTheme => 'उपकरण का रूप';

  @override
  String get lightTheme => 'उजला';

  @override
  String get darkTheme => 'गहरा';

  @override
  String get connection => 'संपर्क';

  @override
  String get autoReconnect => 'फिर जोड़ें';

  @override
  String get autoReconnectHint => 'संपर्क टूटने पर फिर जोड़ें।';

  @override
  String get legacyFirmware => 'पुराने उपकरण की विधि';

  @override
  String get legacyFirmwareHint =>
      'केवल पुराने दस्तानों के लिए। आदेश और माप-सुधार की पुष्टि नहीं हो सकती।';

  @override
  String get disconnectGlove => 'दस्ताना अलग करें';

  @override
  String get connectedDevice => 'जुड़ा हुआ उपकरण';

  @override
  String get dataPrivacy => 'जानकारी और गोपनीयता';

  @override
  String get storedOnDevice => 'इसी उपकरण पर सुरक्षित';

  @override
  String get clearSessionData => 'सभी अभ्यास विवरण मिटाएँ';

  @override
  String get clearSessionDataHint =>
      'सुरक्षित अभ्यास इतिहास स्थायी रूप से मिटाएँ';

  @override
  String get clearData => 'विवरण मिटाएँ';

  @override
  String get cannotUndo => 'मिटाए गए विवरण वापस नहीं मिलेंगे।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get clear => 'मिटाएँ';

  @override
  String get historyCleared => 'अभ्यास इतिहास मिटाया गया।';

  @override
  String get historyClearFailed => 'इतिहास नहीं मिटा सके। फिर प्रयास करें।';

  @override
  String get today => 'आज';

  @override
  String get live => 'प्रत्यक्ष';

  @override
  String get noSignal => 'संकेत नहीं';

  @override
  String get session => 'अभ्यास';

  @override
  String get progress => 'प्रगति';

  @override
  String get sessionInProgress => 'अभ्यास चल रहा है';

  @override
  String get startASession => 'अभ्यास आरंभ करें';

  @override
  String get startSession => 'अभ्यास आरंभ करें';

  @override
  String get viewSession => 'अभ्यास देखें';

  @override
  String get stopSession => 'अभ्यास रोकें';

  @override
  String get latestReadings => 'नए माप';

  @override
  String get averageBend => 'औसत झुकाव';

  @override
  String get grip => 'पकड़';

  @override
  String get liveGrip => 'वर्तमान पकड़';

  @override
  String get liveHand => 'हाथ की गति';

  @override
  String get viewProgress => 'प्रगति देखें';

  @override
  String get vibration => 'कंपन';

  @override
  String get movement => 'गति';

  @override
  String get tapFinger => 'माप देखने के लिए उँगली छुएँ';

  @override
  String get all => 'सभी';

  @override
  String get thumb => 'अँगूठा';

  @override
  String get indexFinger => 'तर्जनी';

  @override
  String get middleFinger => 'मध्यमा';

  @override
  String get ringFinger => 'अनामिका';

  @override
  String get pinky => 'कनिष्ठा';

  @override
  String fingerBend(String finger) {
    return '$finger: झुकाव';
  }

  @override
  String get gripHint => 'पकड़ का माप: 0–1023';

  @override
  String get handNoSignal => 'हाथ का चित्र। संकेत नहीं है।';

  @override
  String get handLiveHint =>
      'उँगलियों की गति प्रत्यक्ष दिखाई देती है। माप देखने के लिए उँगली चुनें।';

  @override
  String handInspected(String finger) {
    return '$finger का माप चुना गया। उँगलियों की गति प्रत्यक्ष दिखाई देती है।';
  }

  @override
  String get recording => 'दर्ज हो रहा है';

  @override
  String get elapsedTime => 'बीता समय';

  @override
  String get saving => 'सुरक्षित कर रहे हैं…';

  @override
  String get calibrateInSettings => 'व्यवस्था में माप-सुधार पूरा करें।';

  @override
  String get connectToBegin => 'आरंभ करने के लिए दस्ताना जोड़ें।';

  @override
  String get openSettings => 'व्यवस्था खोलें';

  @override
  String get sessionStopped => 'अभ्यास रोक दिया गया।';

  @override
  String get liveTrends => 'माप में बदलाव';

  @override
  String get sessions => 'अभ्यास';

  @override
  String get connectForTrends => 'माप में बदलाव देखने के लिए दस्ताना जोड़ें।';

  @override
  String get oneMinute => '1 मि.';

  @override
  String get fiveMinutes => '5 मि.';

  @override
  String get sensorReading => 'उपकरण का माप';

  @override
  String get degrees => 'अंश';

  @override
  String get clearHistory => 'इतिहास मिटाएँ';

  @override
  String get clearHistoryConfirm =>
      'सभी सुरक्षित अभ्यास मिटाएँ? ये वापस नहीं मिलेंगे।';

  @override
  String get noSessions => 'अभी कोई अभ्यास सुरक्षित नहीं है।';

  @override
  String get completeSessionHint =>
      'प्रगति सुरक्षित करने के लिए अभ्यास पूरा करें।';

  @override
  String get sessionHistory => 'अभ्यास इतिहास';

  @override
  String completedSessions(int count) {
    return 'पूर्ण अभ्यास: $count';
  }

  @override
  String sessionDuration(int minutes, int seconds) {
    return '$minutes मि. $seconds से.';
  }

  @override
  String get maxGrip => 'अधिकतम पकड़';

  @override
  String get averageMovement => 'औसत गति';

  @override
  String get readings => 'माप';

  @override
  String get connectGlove => 'दस्ताना जोड़ें';

  @override
  String get nearbyDevices => 'पास के उपकरण';

  @override
  String get scan => 'खोजें';

  @override
  String get refreshDevices => 'उपकरण सूची फिर देखें';

  @override
  String get reconnecting => 'दस्ताना फिर जोड़ रहे हैं…';

  @override
  String get noDevices => 'कोई उपकरण नहीं मिला';

  @override
  String get pairGloveHint =>
      'उपकरण की व्यवस्था में दस्ताना जोड़ें, फिर यहाँ खोजें।';

  @override
  String get bluetoothEnabled => 'बेतार संपर्क चालू';

  @override
  String get bluetoothDisabled => 'बेतार संपर्क बंद';

  @override
  String get scanOrSelect => 'खोजें या जुड़ा हुआ दस्ताना चुनें।';

  @override
  String get turnOnToConnect => 'दस्ताना जोड़ने के लिए संपर्क चालू करें।';

  @override
  String get enable => 'चालू करें';

  @override
  String get connect => 'जोड़ें';

  @override
  String get gloveCalibration => 'माप-सुधार';

  @override
  String get holdOpen => 'पकड़ मापने वाले भाग को दबाए बिना हाथ खुला रखें।';

  @override
  String get holdBent => 'माप पूरा होने तक उँगलियाँ सहज रूप से मोड़कर रखें।';

  @override
  String get openCaptured =>
      'खुले हाथ का माप दर्ज हुआ। अब सहज झुकाव का माप दर्ज करें।';

  @override
  String get positionsCaptured =>
      'दोनों स्थितियों के माप दर्ज हुए। लागू करने के लिए सुरक्षित करें।';

  @override
  String get savingCalibration =>
      'माप-सुधार सुरक्षित कर रहे हैं। दस्ताना चालू रखें।';

  @override
  String get captureFailed =>
      'माप दर्ज नहीं हुआ। फिर प्रयास करें या पुराना माप-सुधार रखने के लिए रद्द करें।';

  @override
  String get calibratedHint =>
      'माप-सुधार पूरा है। फिर सुधारने के लिए पकड़ वाले भाग को दबाए बिना हाथ खोलें।';

  @override
  String get captureOpenHint =>
      'पकड़ वाले भाग को दबाए बिना हाथ खोलें, फिर माप दर्ज करें।';

  @override
  String get calibrationNeedsUpgrade =>
      'माप-सुधार के लिए उपकरण का नया संस्करण चाहिए।';

  @override
  String get connectToCalibrate => 'माप-सुधार के लिए दस्ताना जोड़ें।';

  @override
  String firmwareStatus(String version, String status) {
    return 'उपकरण संस्करण $version · $status';
  }

  @override
  String get calibrationSaved => 'माप-सुधार सुरक्षित है';

  @override
  String get calibrationNotSaved => 'माप-सुधार सुरक्षित नहीं है';

  @override
  String get stopBeforeCalibration => 'माप-सुधार से पहले अभ्यास रोकें।';

  @override
  String get captureOpen => 'खुले हाथ का माप';

  @override
  String get captureBent => 'मुड़े हाथ का माप';

  @override
  String get saveCalibration => 'माप-सुधार सुरक्षित करें';

  @override
  String get cancelCalibration => 'माप-सुधार रद्द करें';

  @override
  String get resetCalibration => 'माप-सुधार मिटाएँ';

  @override
  String get refreshStatus => 'स्थिति फिर देखें';

  @override
  String get vibrationControls => 'कंपन नियंत्रण';

  @override
  String get legacyUnconfirmed =>
      'पुरानी विधि: कंपन की स्थिति की पुष्टि नहीं है।';

  @override
  String get motorManualHint =>
      'कंपन नियंत्रण से दस्ताना स्वयं नियंत्रण की विधि में बदलता है।';

  @override
  String modeLabel(String mode) {
    return 'विधि: $mode';
  }

  @override
  String get unknown => 'अज्ञात';

  @override
  String get manual => 'स्वयं नियंत्रण';

  @override
  String get automatic => 'स्वचालित';

  @override
  String get allOn => 'सभी चालू करें';

  @override
  String get allOff => 'सभी बंद करें';

  @override
  String get unconfirmed => 'पुष्टि नहीं';

  @override
  String get on => 'चालू';

  @override
  String get off => 'बंद';

  @override
  String requestedState(String state) {
    return 'चाही गई स्थिति: $state';
  }

  @override
  String get operationFailed => 'काम पूरा नहीं कर सके। फिर प्रयास करें।';

  @override
  String get languageSaveFailed => 'भाषा का विकल्प सुरक्षित नहीं कर सके।';

  @override
  String get permissionRequired =>
      'दस्ताना जोड़ने के लिए संपर्क की अनुमति चाहिए।';

  @override
  String get permissionDenied =>
      'संपर्क की अनुमति नहीं है। उपकरण की व्यवस्था में पास के उपकरणों की अनुमति दें।';

  @override
  String get enableBeforeScan => 'खोजने से पहले बेतार संपर्क चालू करें।';

  @override
  String get locationRequired =>
      'पुराने उपकरणों पर खोजने के लिए स्थान सेवा चालू करें।';

  @override
  String get connectionNotReady =>
      'तैयार होने से पहले दस्ताने का संपर्क टूट गया।';

  @override
  String get connectionClosed => 'दस्ताने का संपर्क टूट गया।';

  @override
  String get gloveDisconnected => 'दस्ताना जुड़ा नहीं है।';

  @override
  String get connectFirst => 'पहले दस्ताना जोड़ें।';

  @override
  String get autoReconnectSaveFailed =>
      'फिर जोड़ने का विकल्प सुरक्षित नहीं कर सके।';

  @override
  String get deviceStatusUnavailable =>
      'दस्ताने की स्थिति नहीं मिल रही। उपकरण और संपर्क जाँचें।';

  @override
  String get firmwareUnavailable =>
      'उपकरण की स्थिति नहीं मिली। दस्ताना और संपर्क जाँचें। केवल पुराने उपकरणों के लिए पुरानी विधि चुनें।';

  @override
  String get disconnectedBeforeAck =>
      'पुष्टि मिलने से पहले दस्ताना अलग हो गया।';

  @override
  String get sessionDiscarded => 'माप दर्ज नहीं हुए; अभ्यास सुरक्षित नहीं हुआ।';

  @override
  String sessionSaved(int count) {
    return 'अभ्यास सुरक्षित हुआ ($count माप)।';
  }

  @override
  String get sessionSaveFailed =>
      'अभ्यास सुरक्षित नहीं कर सके। फिर प्रयास करें।';

  @override
  String get upgradeRequired => 'इस सुविधा के लिए उपकरण का नया संस्करण चाहिए।';

  @override
  String get legacyCommandSent =>
      'आदेश भेजा गया; पुराना उपकरण कंपन की स्थिति की पुष्टि नहीं कर सकता।';

  @override
  String get legacyNotNeeded =>
      'यह दस्ताना नई विधि का समर्थन करता है। पुरानी विधि केवल पुराने उपकरणों के लिए है।';

  @override
  String get waitAfterSession =>
      'अभ्यास रोकें और आदेश पूरे होने तक प्रतीक्षा करें।';

  @override
  String get legacyModeHint =>
      'पुरानी विधि में कंपन की पुष्टि और माप-सुधार नहीं हैं। स्वचालित कंपन भेजे गए आदेश बदल सकता है।';

  @override
  String get readingDeviceStatus => 'उपकरण की स्थिति पढ़ रहे हैं';

  @override
  String get waitForCommand => 'वर्तमान आदेश पूरा होने तक प्रतीक्षा करें।';

  @override
  String get sending => 'भेज रहे हैं';

  @override
  String get confirmed => 'पुष्टि हुई';

  @override
  String get commandTimedOut =>
      'दस्ताने ने उत्तर नहीं दिया। संपर्क जाँचकर फिर प्रयास करें।';

  @override
  String get connectionChanged => 'आदेश भेजते समय संपर्क बदल गया।';

  @override
  String fingerTimedOut(String finger) {
    return '$finger का कंपन रुका: समय सीमा पूरी हुई। बंद करें और फिर चालू करने से पहले 2 सेकंड प्रतीक्षा करें।';
  }

  @override
  String get manualExpired =>
      'स्वयं नियंत्रण का समय पूरा हुआ; सभी कंपन रुक गए।';

  @override
  String get unstableReadings =>
      'माप बहुत बदले। हाथ स्थिर रखकर फिर प्रयास करें।';

  @override
  String get invalidSpan =>
      'खुले और मुड़े हाथ के माप बहुत पास हैं। मापने वाले भागों का स्थान जाँचें और मुड़ा माप फिर दर्ज करें।';

  @override
  String get communicationOverflow =>
      'दस्ताने की जानकारी पूरी नहीं मिली। कंपन की स्थिति अज्ञात है; स्थिति फिर देखें।';

  @override
  String get cannotSaveEmptySession =>
      'माप के बिना अभ्यास सुरक्षित नहीं हो सकता।';

  @override
  String get storageFailed => 'अभ्यास सुरक्षित करना विफल हुआ।';

  @override
  String get commandRejected =>
      'दस्ताना आदेश पूरा नहीं कर सका। स्थिति जाँचकर फिर प्रयास करें।';
}
