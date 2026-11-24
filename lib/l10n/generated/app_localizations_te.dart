// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'చేతి పునరావాసం';

  @override
  String get appSubtitle => 'చేతి కదలిక సాధన';

  @override
  String get settings => 'అమరికలు';

  @override
  String get language => 'భాష';

  @override
  String get deviceLanguage => 'పరికర భాష';

  @override
  String get appearance => 'రూపం';

  @override
  String get systemTheme => 'పరికర రూపం';

  @override
  String get lightTheme => 'వెలుతురు';

  @override
  String get darkTheme => 'చీకటి';

  @override
  String get connection => 'అనుసంధానం';

  @override
  String get autoReconnect => 'తిరిగి కలుపు';

  @override
  String get autoReconnectHint => 'అనుసంధానం తెగితే తిరిగి కలపండి.';

  @override
  String get legacyFirmware => 'పాత పరికర విధానం';

  @override
  String get legacyFirmwareHint =>
      'పాత తొడుగులకు మాత్రమే. ఆదేశాలు, సర్దుబాటు నిర్ధారించలేము.';

  @override
  String get disconnectGlove => 'తొడుగును విడదీయండి';

  @override
  String get connectedDevice => 'అనుసంధానమైన పరికరం';

  @override
  String get dataPrivacy => 'సమాచారం, గోప్యత';

  @override
  String get storedOnDevice => 'ఈ పరికరంలోనే భద్రపరచబడుతుంది';

  @override
  String get clearSessionData => 'సాధన వివరాలన్నీ తొలగించండి';

  @override
  String get clearSessionDataHint =>
      'భద్రపరచిన సాధన చరిత్రను పూర్తిగా తొలగించండి';

  @override
  String get clearData => 'వివరాలు తొలగించండి';

  @override
  String get cannotUndo => 'తొలగించిన వివరాలను తిరిగి పొందలేరు.';

  @override
  String get cancel => 'రద్దు';

  @override
  String get clear => 'తొలగించండి';

  @override
  String get historyCleared => 'సాధన చరిత్ర తొలగించబడింది.';

  @override
  String get historyClearFailed =>
      'చరిత్రను తొలగించలేకపోయాము. మళ్లీ ప్రయత్నించండి.';

  @override
  String get today => 'నేడు';

  @override
  String get live => 'ప్రత్యక్షం';

  @override
  String get noSignal => 'సంకేతం లేదు';

  @override
  String get session => 'సాధన';

  @override
  String get progress => 'పురోగతి';

  @override
  String get sessionInProgress => 'సాధన జరుగుతోంది';

  @override
  String get startASession => 'సాధన ప్రారంభించండి';

  @override
  String get startSession => 'సాధన ప్రారంభించండి';

  @override
  String get viewSession => 'సాధన చూడండి';

  @override
  String get stopSession => 'సాధన ఆపండి';

  @override
  String get latestReadings => 'తాజా కొలతలు';

  @override
  String get averageBend => 'సగటు వంగుదల';

  @override
  String get grip => 'పట్టు';

  @override
  String get liveGrip => 'ప్రస్తుత పట్టు';

  @override
  String get liveHand => 'చేతి కదలిక';

  @override
  String get viewProgress => 'పురోగతి చూడండి';

  @override
  String get vibration => 'కంపనం';

  @override
  String get movement => 'కదలిక';

  @override
  String get tapFinger => 'కొలత కోసం వేలిని తాకండి';

  @override
  String get all => 'అన్నీ';

  @override
  String get thumb => 'బొటనవేలు';

  @override
  String get indexFinger => 'చూపుడువేలు';

  @override
  String get middleFinger => 'మధ్యవేలు';

  @override
  String get ringFinger => 'ఉంగరపువేలు';

  @override
  String get pinky => 'చిటికెనవేలు';

  @override
  String fingerBend(String finger) {
    return '$finger వంగుదల';
  }

  @override
  String get gripHint => 'పట్టు కొలత: 0–1023';

  @override
  String get handNoSignal => 'చేతి రూపం. సంకేతం లేదు.';

  @override
  String get handLiveHint =>
      'వేళ్ల కదలిక ప్రత్యక్షంగా కనిపిస్తుంది. కొలత చూడటానికి వేలిని ఎంచుకోండి.';

  @override
  String handInspected(String finger) {
    return '$finger కొలతను చూస్తున్నారు. వేళ్ల కదలిక ప్రత్యక్షంగా కనిపిస్తుంది.';
  }

  @override
  String get recording => 'నమోదవుతోంది';

  @override
  String get elapsedTime => 'గడిచిన సమయం';

  @override
  String get saving => 'భద్రపరుస్తోంది…';

  @override
  String get calibrateInSettings => 'అమరికల్లో కొలత సర్దుబాటు పూర్తి చేయండి.';

  @override
  String get connectToBegin => 'ప్రారంభించడానికి తొడుగును కలపండి.';

  @override
  String get openSettings => 'అమరికలు తెరవండి';

  @override
  String get sessionStopped => 'సాధన ఆపబడింది.';

  @override
  String get liveTrends => 'కొలతల మార్పు';

  @override
  String get sessions => 'సాధనలు';

  @override
  String get connectForTrends => 'కొలతల మార్పు చూడటానికి తొడుగును కలపండి.';

  @override
  String get oneMinute => '1 నిమి.';

  @override
  String get fiveMinutes => '5 నిమి.';

  @override
  String get sensorReading => 'పరికర కొలత';

  @override
  String get degrees => 'కోణం';

  @override
  String get clearHistory => 'చరిత్ర తొలగించండి';

  @override
  String get clearHistoryConfirm =>
      'భద్రపరచిన సాధనలన్నీ తొలగించాలా? తిరిగి పొందలేరు.';

  @override
  String get noSessions => 'ఇంకా సాధనలు భద్రపరచలేదు.';

  @override
  String get completeSessionHint => 'పురోగతి భద్రపరచడానికి సాధన పూర్తి చేయండి.';

  @override
  String get sessionHistory => 'సాధన చరిత్ర';

  @override
  String completedSessions(int count) {
    return 'పూర్తయిన సాధనలు: $count';
  }

  @override
  String sessionDuration(int minutes, int seconds) {
    return '$minutes నిమి. $seconds సె.';
  }

  @override
  String get maxGrip => 'అత్యధిక పట్టు';

  @override
  String get averageMovement => 'సగటు కదలిక';

  @override
  String get readings => 'కొలతలు';

  @override
  String get connectGlove => 'తొడుగును కలపండి';

  @override
  String get nearbyDevices => 'సమీప పరికరాలు';

  @override
  String get scan => 'వెతకండి';

  @override
  String get refreshDevices => 'పరికరాల జాబితా నవీకరించండి';

  @override
  String get reconnecting => 'తొడుగును మళ్లీ కలుపుతోంది…';

  @override
  String get noDevices => 'పరికరాలు కనిపించలేదు';

  @override
  String get pairGloveHint =>
      'పరికర అమరికల్లో తొడుగును జత చేసి, ఇక్కడ వెతకండి.';

  @override
  String get bluetoothEnabled => 'తీగలేని అనుసంధానం సిద్ధం';

  @override
  String get bluetoothDisabled => 'తీగలేని అనుసంధానం ఆపబడింది';

  @override
  String get scanOrSelect => 'వెతకండి లేదా జత చేసిన తొడుగును ఎంచుకోండి.';

  @override
  String get turnOnToConnect =>
      'తొడుగును కలపడానికి అనుసంధానాన్ని ప్రారంభించండి.';

  @override
  String get enable => 'ప్రారంభించండి';

  @override
  String get connect => 'కలపండి';

  @override
  String get gloveCalibration => 'కొలత సర్దుబాటు';

  @override
  String get holdOpen =>
      'పట్టు కొలిచే భాగాన్ని నొక్కకుండా చేతిని తెరిచి ఉంచండి.';

  @override
  String get holdBent => 'కొలత పూర్తయ్యేవరకు సౌకర్యంగా వేళ్లను వంచి ఉంచండి.';

  @override
  String get openCaptured =>
      'తెరిచిన చేతి కొలత నమోదైంది. ఇప్పుడు సౌకర్యంగా వంచిన కొలతను నమోదు చేయండి.';

  @override
  String get positionsCaptured =>
      'రెండు స్థితుల కొలతలు నమోదయ్యాయి. వర్తింపజేయడానికి భద్రపరచండి.';

  @override
  String get savingCalibration => 'సర్దుబాటు భద్రపరుస్తోంది. తొడుగును ఆపవద్దు.';

  @override
  String get captureFailed =>
      'కొలత నమోదు కాలేదు. మళ్లీ ప్రయత్నించండి లేదా పాత సర్దుబాటు ఉంచడానికి రద్దు చేయండి.';

  @override
  String get calibratedHint =>
      'సర్దుబాటు పూర్తయింది. మళ్లీ సర్దుబాటు చేయడానికి పట్టు భాగాన్ని నొక్కకుండా చేతిని తెరవండి.';

  @override
  String get captureOpenHint =>
      'పట్టు భాగాన్ని నొక్కకుండా చేతిని తెరిచి, కొలత నమోదు చేయండి.';

  @override
  String get calibrationNeedsUpgrade =>
      'సర్దుబాటుకు పరికరంలో కొత్త సంచిక అవసరం.';

  @override
  String get connectToCalibrate => 'సర్దుబాటు కోసం తొడుగును కలపండి.';

  @override
  String firmwareStatus(String version, String status) {
    return 'పరికర సంచిక $version · $status';
  }

  @override
  String get calibrationSaved => 'సర్దుబాటు భద్రపరచబడింది';

  @override
  String get calibrationNotSaved => 'సర్దుబాటు భద్రపరచలేదు';

  @override
  String get stopBeforeCalibration => 'సర్దుబాటుకు ముందు సాధనను ఆపండి.';

  @override
  String get captureOpen => 'తెరిచిన చేతి కొలత';

  @override
  String get captureBent => 'వంచిన చేతి కొలత';

  @override
  String get saveCalibration => 'సర్దుబాటు భద్రపరచండి';

  @override
  String get cancelCalibration => 'సర్దుబాటు రద్దు';

  @override
  String get resetCalibration => 'సర్దుబాటు తొలగించండి';

  @override
  String get refreshStatus => 'స్థితి నవీకరించండి';

  @override
  String get vibrationControls => 'కంపన నియంత్రణ';

  @override
  String get legacyUnconfirmed => 'పాత విధానం: కంపన స్థితి నిర్ధారించబడలేదు.';

  @override
  String get motorManualHint =>
      'కంపన నియంత్రణతో తొడుగు చేతితో నియంత్రించే విధానంలోకి మారుతుంది.';

  @override
  String modeLabel(String mode) {
    return 'విధానం: $mode';
  }

  @override
  String get unknown => 'తెలియదు';

  @override
  String get manual => 'చేతితో నియంత్రణ';

  @override
  String get automatic => 'స్వయంచాలక';

  @override
  String get allOn => 'అన్నీ ప్రారంభించండి';

  @override
  String get allOff => 'అన్నీ ఆపండి';

  @override
  String get unconfirmed => 'నిర్ధారించలేదు';

  @override
  String get on => 'నడుస్తోంది';

  @override
  String get off => 'ఆపబడింది';

  @override
  String requestedState(String state) {
    return 'కోరిన స్థితి: $state';
  }

  @override
  String get operationFailed => 'పని పూర్తి చేయలేకపోయాము. మళ్లీ ప్రయత్నించండి.';

  @override
  String get languageSaveFailed => 'భాష అమరికను భద్రపరచలేకపోయాము.';

  @override
  String get permissionRequired => 'తొడుగును కలపడానికి అనుసంధాన అనుమతి అవసరం.';

  @override
  String get permissionDenied =>
      'అనుసంధాన అనుమతి లేదు. పరికర అమరికల్లో సమీప పరికరాల అనుమతి ఇవ్వండి.';

  @override
  String get enableBeforeScan =>
      'వెతకడానికి ముందు తీగలేని అనుసంధానాన్ని ప్రారంభించండి.';

  @override
  String get locationRequired =>
      'పాత పరికరాల్లో వెతకడానికి స్థాన సేవను ప్రారంభించండి.';

  @override
  String get connectionNotReady => 'సిద్ధమయ్యేలోపు తొడుగు అనుసంధానం తెగింది.';

  @override
  String get connectionClosed => 'తొడుగు అనుసంధానం తెగింది.';

  @override
  String get gloveDisconnected => 'తొడుగు అనుసంధానం లేదు.';

  @override
  String get connectFirst => 'ముందుగా తొడుగును కలపండి.';

  @override
  String get autoReconnectSaveFailed =>
      'తిరిగి కలిపే అమరికను భద్రపరచలేకపోయాము.';

  @override
  String get deviceStatusUnavailable =>
      'తొడుగు స్థితి తెలియడం లేదు. పరికరాన్ని, అనుసంధానాన్ని తనిఖీ చేయండి.';

  @override
  String get firmwareUnavailable =>
      'పరికర స్థితి తెలియడం లేదు. తొడుగును, అనుసంధానాన్ని తనిఖీ చేయండి. పాత పరికరాలకు మాత్రమే పాత విధానం ఎంచుకోండి.';

  @override
  String get disconnectedBeforeAck =>
      'నిర్ధారణ వచ్చేలోపు తొడుగు అనుసంధానం తెగింది.';

  @override
  String get sessionDiscarded => 'కొలతలు నమోదు కాలేదు; సాధన భద్రపరచలేదు.';

  @override
  String sessionSaved(int count) {
    return 'సాధన భద్రపరచబడింది ($count కొలతలు).';
  }

  @override
  String get sessionSaveFailed => 'సాధన భద్రపరచలేకపోయాము. మళ్లీ ప్రయత్నించండి.';

  @override
  String get upgradeRequired => 'ఈ సదుపాయానికి పరికరంలో కొత్త సంచిక అవసరం.';

  @override
  String get legacyCommandSent =>
      'ఆదేశం పంపబడింది; పాత పరికరం కంపన స్థితిని నిర్ధారించలేదు.';

  @override
  String get legacyNotNeeded =>
      'ఈ తొడుగు కొత్త విధానాన్ని అందిస్తుంది. పాత విధానం పాత పరికరాలకు మాత్రమే.';

  @override
  String get waitAfterSession => 'సాధన ఆపి, ఆదేశాలు పూర్తయ్యేవరకు వేచి ఉండండి.';

  @override
  String get legacyModeHint =>
      'పాత విధానంలో కంపన నిర్ధారణ, సర్దుబాటు లేవు. స్వయంచాలక కంపనం పంపిన ఆదేశాలను మార్చవచ్చు.';

  @override
  String get readingDeviceStatus => 'పరికర స్థితి చదువుతోంది';

  @override
  String get waitForCommand => 'ప్రస్తుత ఆదేశం పూర్తయ్యేవరకు వేచి ఉండండి.';

  @override
  String get sending => 'పంపుతోంది';

  @override
  String get confirmed => 'నిర్ధారించబడింది';

  @override
  String get commandTimedOut =>
      'తొడుగు స్పందించలేదు. అనుసంధానాన్ని తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get connectionChanged => 'ఆదేశం పంపుతుండగా అనుసంధానం మారింది.';

  @override
  String fingerTimedOut(String finger) {
    return '$finger కంపనం ఆగింది: సమయ పరిమితి చేరుకుంది. ఆపి, మళ్లీ ప్రారంభించే ముందు 2 సెకన్లు వేచి ఉండండి.';
  }

  @override
  String get manualExpired =>
      'చేతితో నియంత్రణ సమయం ముగిసింది; కంపనాలన్నీ ఆగాయి.';

  @override
  String get unstableReadings =>
      'కొలతలు ఎక్కువగా మారాయి. చేతిని స్థిరంగా ఉంచి మళ్లీ ప్రయత్నించండి.';

  @override
  String get invalidSpan =>
      'తెరిచిన, వంచిన కొలతలు చాలా దగ్గరగా ఉన్నాయి. కొలిచే భాగాల అమరిక తనిఖీ చేసి వంచిన కొలతను మళ్లీ నమోదు చేయండి.';

  @override
  String get communicationOverflow =>
      'తొడుగు సమాచారం పూర్తిగా అందలేదు. కంపన స్థితి తెలియదు; స్థితిని నవీకరించండి.';

  @override
  String get cannotSaveEmptySession => 'కొలతలు లేని సాధనను భద్రపరచలేము.';

  @override
  String get storageFailed => 'సాధన భద్రపరచడం విఫలమైంది.';

  @override
  String get commandRejected =>
      'తొడుగు ఆదేశం పూర్తి చేయలేదు. స్థితిని తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';
}
