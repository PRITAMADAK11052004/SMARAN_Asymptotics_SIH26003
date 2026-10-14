import '../../core/auth/auth_store.dart';
import 'app_languages.dart';
import 'translations.dart';

/// Simple translator.
///
/// Reads the currently-chosen language from [AuthStore]. Use:
///   final l = L.current;
///   Text(l.t('hello'));       // or
///   Text(l.hello);            // typed getter
///
/// Missing keys in a language fall back to English automatically.
class L {
  final AppLanguage lang;
  const L(this.lang);

  /// Reads the currently selected language from AuthStore.
  static L get current => L(AuthStore.instance.preferredLanguage);

  /// Direct lookup with English fallback.
  String t(String key) {
    final map = translations[lang.key];
    if (map != null && map.containsKey(key)) return map[key]!;
    return translations['english']?[key] ?? key;
  }

  // ── Greetings ─────────────────────────────────────────────
  String get hello => t('hello');
  String get goodMorning => t('good_morning');
  String get goodAfternoon => t('good_afternoon');
  String get goodEvening => t('good_evening');

  // ── Bottom nav ────────────────────────────────────────────
  String get home => t('home');
  String get family => t('family');
  String get photos => t('photos');
  String get music => t('music');
  String get relax => t('relax');

  // ── Home tiles ────────────────────────────────────────────
  String get yourDailyTask => t('your_daily_task');
  String get dailyTaskSub => t('daily_task_sub');
  String get memoryGarden => t('memory_garden');
  String get memoryGardenSub => t('memory_garden_sub');
  String get memoryLane => t('memory_lane');
  String get memoryLaneSub => t('memory_lane_sub');
  String get scheduled => t('scheduled');
  String get scheduledSub => t('scheduled_sub');

  String get greatJobPrefix => t('great_job_prefix');
  String get ofGamesToday => t('of_games_today');
  String get keepMindActive => t('keep_mind_active');

  String get todaysPlan => t('todays_plan');
  String get fullSchedule => t('full_schedule');
  String get remindMe => t('remind_me');
  String get imDone => t('im_done');
  String get nothingScheduled => t('nothing_scheduled');
  String get addReminderHint => t('add_reminder_hint');
  String get smaranReminder => t('smaran_reminder');

  String get aiReminder => t('ai_reminder');
  String get askReminders => t('ask_reminders');

  // ── Auth ──────────────────────────────────────────────────
  String get welcomeBack => t('welcome_back');
  String get signInContinue => t('sign_in_continue');
  String get emailOrPhone => t('email_or_phone');
  String get password => t('password');
  String get pin => t('pin');
  String get forgotPasswordQ => t('forgot_password_q');
  String get loginBtn => t('login_btn');
  String get newToSmaran => t('new_to_smaran');

  // ── Role ──────────────────────────────────────────────────
  String get howUseSmaran => t('how_use_smaran');
  String get chooseOptionBest => t('choose_option_best');
  String get patient => t('patient');
  String get caregiver => t('caregiver');
  String get familyMember => t('family_member');
  String get patientTagline => t('patient_tagline');
  String get caregiverTagline => t('caregiver_tagline');
  String get familyTagline => t('family_tagline');

  // ── Language / Continue ───────────────────────────────────
  String get welcomeToSmaran => t('welcome_to_smaran');
  String get chooseLanguage => t('choose_language');
  String get continueBtn => t('continue_btn');

  // ── Patient ID ────────────────────────────────────────────
  String get yourPatientId => t('your_patient_id');
  String get writeDownId => t('write_down_id');
  String get copyBtn => t('copy_btn');
  String get iveWrittenDown => t('ive_written_down');

  // ── Link patient ──────────────────────────────────────────
  String get linkAPatient => t('link_a_patient');
  String get enterPatientId => t('enter_patient_id');
  String get linkPatientBtn => t('link_patient_btn');
  String get linkedTo => t('linked_to');

  // ── Profile ───────────────────────────────────────────────
  String get profile => t('profile');
  String get account => t('account');
  String get linkedPatients => t('linked_patients');
  String get logoutBtn => t('logout_btn');
  String get requestLogoutBtn => t('request_logout_btn');
  String get logoutNeedsApproval => t('logout_needs_approval');
  String get addAnotherPatient => t('add_another_patient');
  String get noPatientsLinked => t('no_patients_linked');

  // ── Reminders ─────────────────────────────────────────────
  String get dailyRoutine => t('daily_routine');
  String get dailyRoutineSub => t('daily_routine_sub');
  String get newReminderBtn => t('new_reminder_btn');
  String get noAlarms => t('no_alarms');
  String get noAlarmsHint => t('no_alarms_hint');
  String get editAlarm => t('edit_alarm');
  String get setAlarm => t('set_alarm');
  String get repeat => t('repeat');
  String get daily => t('daily');
  String get once => t('once');
  String get specificDate => t('specific_date');
  String get alarmType => t('alarm_type');
  String get medicine => t('medicine');
  String get food => t('food');
  String get memoryActivity => t('memory_activity');
  String get specificTask => t('specific_task');
  String get whenQ => t('when_q');
  String get beforeFood => t('before_food');
  String get afterFood => t('after_food');
  String get timeLabel => t('time_label');
  String get notesLabel => t('notes_label');
  String get taskTitle => t('task_title');
  String get saveAlarm => t('save_alarm');
  String get updateAlarm => t('update_alarm');
  String get deleteReminder => t('delete_reminder');
  String get everyDay => t('every_day');

  // ── Games ─────────────────────────────────────────────────
  String get cognitiveGames => t('cognitive_games');
  String get chooseActivity => t('choose_activity');
  String get todayPrefix => t('today_prefix');
  String get gamesTodaySub => t('games_today_sub');
  String get memoryMatch => t('memory_match');
  String get sequenceRecall => t('sequence_recall');
  String get patternTap => t('pattern_tap');
  String get wordPicture => t('word_picture');
  String get soundMatch => t('sound_match');
  String get memoryMatchTagline => t('memory_match_tagline');
  String get sequenceRecallTagline => t('sequence_recall_tagline');
  String get patternTapTagline => t('pattern_tap_tagline');
  String get wordPictureTagline => t('word_picture_tagline');
  String get soundMatchTagline => t('sound_match_tagline');
  String get recall => t('recall');
  String get workingMemory => t('working_memory');
  String get attention => t('attention');
  String get semanticMemory => t('semantic_memory');
  String get sensoryRecall => t('sensory_recall');
  String get comingSoon => t('coming_soon');
  String get startGame => t('start_game');
  String get playAgain => t('play_again');
  String get backToGames => t('back_to_games');
  String get cardsLabel => t('cards_label');
  String get levelLabel => t('level_label');
  String get movesLabel => t('moves_label');
  String get matchedLabel => t('matched_label');
  String get timeTaken => t('time_taken');
  String get pairsMatched => t('pairs_matched');
  String get wonderful => t('wonderful');
  String get foundEveryPair => t('found_every_pair');
  String get tapTwoCards => t('tap_two_cards');

  // ── Radio ─────────────────────────────────────────────────
  String get smaranRadio => t('smaran_radio');
  String get availableStations => t('available_stations');
  String get chooseStation => t('choose_station');
  String get tapAnyStation => t('tap_any_station');
  String get stopRadio => t('stop_radio');

  // ── Voice ─────────────────────────────────────────────────
  String get voiceReminder => t('voice_reminder');
  String get tapMic => t('tap_mic');
  String get listeningSpeak => t('listening_speak');
  String get youSaid => t('you_said');
  String get smaranSays => t('smaran_says');
  String get addThisAlarm => t('add_this_alarm');
  String get waitingReminder => t('waiting_reminder');
  String get orTypeHere => t('or_type_here');
  String get hearAgain => t('hear_again');

  // ── Alarm screen ──────────────────────────────────────────
  String get iUnderstand => t('i_understand');
  String get smaranReminderHeader => t('smaran_reminder_header');
}