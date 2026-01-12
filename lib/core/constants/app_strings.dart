import 'package:flutter/foundation.dart';
import 'strings/app_strings_base.dart';
import 'strings/app_strings_tr.dart';
import 'strings/app_strings_en.dart';
import 'strings/app_strings_it.dart';

enum AppLanguage {
  turkish,
  english,
  italian,
}

class AppStrings {
  static AppStringsBase _instance = AppStringsTr();
  static AppLanguage _currentLanguage = AppLanguage.turkish;
  static final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier(AppLanguage.turkish);

  static AppLanguage get currentLanguage => _currentLanguage;
  
  static void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    languageNotifier.value = language;
    switch (language) {
      case AppLanguage.turkish:
        _instance = AppStringsTr();
        break;
      case AppLanguage.english:
        _instance = AppStringsEn();
        break;
      case AppLanguage.italian:
        _instance = AppStringsIt();
        break;
    }
  }

  // Common
  static String get error => _instance.error;
  static String get cancel => _instance.cancel;
  static String get remove => _instance.remove;
  static String get signOut => _instance.signOut;
  
  // Profile Screen
  static String get enterEmail => _instance.enterEmail;
  static String get invalidEmail => _instance.invalidEmail;
  static String get partnerRequestSent => _instance.partnerRequestSent;
  static String get connectionEstablished => _instance.connectionEstablished;
  static String get requestRejected => _instance.requestRejected;
  static String get requestCancelled => _instance.requestCancelled;
  static String get removePartnerTitle => _instance.removePartnerTitle;
  static String get removePartnerContent => _instance.removePartnerContent;
  static String get partnerRemoved => _instance.partnerRemoved;
  static String get signOutTitle => _instance.signOutTitle;
  static String get signOutContent => _instance.signOutContent;
  static String get errorTitle => _instance.errorTitle;
  static String get ok => _instance.ok;
  
  static String get profileLoadError => _instance.profileLoadError;
  static String get teamNameTitle => _instance.teamNameTitle;
  static String get gameAppearance => _instance.gameAppearance;
  static String get teamNameDescription => _instance.teamNameDescription;
  static String get setTeamName => _instance.setTeamName;
  static String get teamCreated => _instance.teamCreated;
  static String get incomingRequests => _instance.incomingRequests;
  static String get accept => _instance.accept;
  static String get reject => _instance.reject;
  static String get outgoingRequests => _instance.outgoingRequests;
  static String get waitingForResponse => _instance.waitingForResponse;
  static String get yourPartner => _instance.yourPartner;
  static String get unlink => _instance.unlink;
  static String get addPartner => _instance.addPartner;
  static String get addPartnerDescription => _instance.addPartnerDescription;
  static String get partnerEmailLabel => _instance.partnerEmailLabel;
  static String get sendRequest => _instance.sendRequest;
  static String get devPanel => _instance.devPanel;
  static String get devPanelSubtitle => _instance.devPanelSubtitle;

  // Quiz Hub Screen
  static String get quizHubTitle => _instance.quizHubTitle;
  static String get quizHubSubtitle => _instance.quizHubSubtitle;
  static String get playNow => _instance.playNow;
  static String get comingSoonSuffix => _instance.comingSoonSuffix;
  static String get comingSoonBadge => _instance.comingSoonBadge;

  // Login Screen
  static String get appTitle => _instance.appTitle;
  static String get appSubtitle => _instance.appSubtitle;
  static String get signInWithGoogle => _instance.signInWithGoogle;
  static String get errorOccurred => _instance.errorOccurred;
  
  // Leaderboard Screen
  static String get leaderboardTitle => _instance.leaderboardTitle;
  static String get noTeam => _instance.noTeam;
  static String get total => _instance.total;
  static String get points => _instance.points;
  static String get thisWeek => _instance.thisWeek;
  static String get thisMonth => _instance.thisMonth;
  static String get weekly => _instance.weekly;
  static String get monthly => _instance.monthly;
  static String get allTime => _instance.allTime;
  static String get noPointsYet => _instance.noPointsYet;
  static String get playToWin => _instance.playToWin;

  // Home Screen
  static String get homeGames => _instance.homeGames;
  static String get homeProfile => _instance.homeProfile;

  // Games Screen
  static String get gamesTitle => _instance.gamesTitle;
  static String get gameHeartShooter => _instance.gameHeartShooter;
  static String get gameHeartShooterDesc => _instance.gameHeartShooterDesc;
  static String get gameQuizHubDesc => _instance.gameQuizHubDesc;
  static String get gameMarimo => _instance.gameMarimo;
  static String get gameMarimoDesc => _instance.gameMarimoDesc;
  static String get sectionComingSoon => _instance.sectionComingSoon;
  static String get gameCvC => _instance.gameCvC;
  static String get gameCvCDesc => _instance.gameCvCDesc;
  static String get gameRaffles => _instance.gameRaffles;
  static String get gameRafflesDesc => _instance.gameRafflesDesc;
  static String get gameEvents => _instance.gameEvents;
  static String get gameEventsDesc => _instance.gameEventsDesc;
  static String get badgeNew => _instance.badgeNew;
  static String get badgeComingSoon => _instance.badgeComingSoon;

  // Developer Options Screen
  static String get devWarning => _instance.devWarning;
  static String get debugPlayerHeader => _instance.debugPlayerHeader;
  static String get debugResetPoints => _instance.debugResetPoints;
  static String get debugResetPointsDesc => _instance.debugResetPointsDesc;
  static String get debugAddPoints => _instance.debugAddPoints;
  static String get debugAddPointsDesc => _instance.debugAddPointsDesc;
  static String get debugContentHeader => _instance.debugContentHeader;
  static String get debugQuestWizard => _instance.debugQuestWizard;
  static String get debugQuestWizardDesc => _instance.debugQuestWizardDesc;
  static String get debugQuestBank => _instance.debugQuestBank;
  static String get debugQuestBankDesc => _instance.debugQuestBankDesc;
  static String get debugDataHeader => _instance.debugDataHeader;
  static String get debugLoadDictionary => _instance.debugLoadDictionary;
  static String get debugLoadDictionaryDesc => _instance.debugLoadDictionaryDesc;
  static String get debugSystemHeader => _instance.debugSystemHeader;
  static String get debugUserId => _instance.debugUserId;
  static String get debugAppVersion => _instance.debugAppVersion;
  static String get debugPointsReset => _instance.debugPointsReset;
  static String get debugPointsAdded => _instance.debugPointsAdded;
  static String get debugReadingFile => _instance.debugReadingFile;
  static String get debugUploadStart => _instance.debugUploadStart;
  static String get debugUploading => _instance.debugUploading;
  static String get debugUploadComplete => _instance.debugUploadComplete;
  static String get debugWordsUploaded => _instance.debugWordsUploaded;
  static String get debugUploadSuccess => _instance.debugUploadSuccess;
  static String get none => _instance.none;

  // Admin - Question Bank
  static String get questionBankTitle => _instance.questionBankTitle;
  static String get noQuestionsYet => _instance.noQuestionsYet;
  static String get loadMore => _instance.loadMore;
  static String get questionDeleted => _instance.questionDeleted;
  static String get deleteError => _instance.deleteError;
  static String get filterByCategory => _instance.filterByCategory;
  static String get allCategories => _instance.allCategories;
  static String get questionDetail => _instance.questionDetail;
  static String get close => _instance.close;

  // Admin - Question Creator
  static String get adminTitle => _instance.adminTitle;
  static String get tabManual => _instance.tabManual;
  static String get tabAI => _instance.tabAI;
  static String get selectCategory => _instance.selectCategory;
  static String get enterSubCategory => _instance.enterSubCategory;
  static String get sessionNotFound => _instance.sessionNotFound;
  static String get questionSaved => _instance.questionSaved;
  static String get aiError => _instance.aiError;
  static String get selectQuestions => _instance.selectQuestions;
  static String get questionsSavedToDb => _instance.questionsSavedToDb;
  static String get saveError => _instance.saveError;
  static String get labelCategory => _instance.labelCategory;
  static String get labelDifficulty => _instance.labelDifficulty;
  static String get labelQuestionText => _instance.labelQuestionText;
  static String get labelSubCategory => _instance.labelSubCategory;
  static String get labelTopic => _instance.labelTopic;
  static String get labelQuestionCount => _instance.labelQuestionCount;
  static String get btnSaveManual => _instance.btnSaveManual;
  static String get btnGenerateAI => _instance.btnGenerateAI;
  static String get generating => _instance.generating;
  static String get preview => _instance.preview;
  static String get clear => _instance.clear;
  static String get selectAll => _instance.selectAll;
  static String get btnSaveSelected => _instance.btnSaveSelected;
  static String get optionC => _instance.optionC;
  static String get diffEasy => _instance.diffEasy;
  static String get diffMedium => _instance.diffMedium;
  static String get diffHard => _instance.diffHard;
  static String get requiredField => _instance.requiredField;
  static String get enterOption => _instance.enterOption;

  // Quiz Difficulty
  static String get diffDescriptionSeconds => _instance.diffDescriptionSeconds;
  static String get diffDescriptionQuestions => _instance.diffDescriptionQuestions;
  

  // Vocabulary Quiz
  static String get vocabQuizTitle => _instance.vocabQuizTitle;
  static String get vocabQuizDesc => _instance.vocabQuizDesc;
  static String get tusQuizTitle => _instance.tusQuizTitle;
  static String get tusQuizDesc => _instance.tusQuizDesc;
  static String get kpssQuizTitle => _instance.kpssQuizTitle;
  static String get kpssQuizDesc => _instance.kpssQuizDesc;
  static String get generalCultureQuizTitle => _instance.generalCultureQuizTitle;
  static String get generalCultureQuizDesc => _instance.generalCultureQuizDesc;
  static String get aytQuizTitle => _instance.aytQuizTitle;
  static String get aytQuizDesc => _instance.aytQuizDesc;
  static String get pdrQuizTitle => _instance.pdrQuizTitle;
  static String get pdrQuizDesc => _instance.pdrQuizDesc;
  
  static String get selectGameMode => _instance.selectGameMode;
  static String get selectDifficulty => _instance.selectDifficulty;
  static String get soloPractice => _instance.soloPractice;
  static String get soloPracticeSubtitle => _instance.soloPracticeSubtitle;
  static String get coupleVsCouple => _instance.coupleVsCouple;
  static String get coupleVsCoupleSubtitle => _instance.coupleVsCoupleSubtitle;
  static String get scoreBadge => _instance.scoreBadge;
  
  static String get waitingOpponent => _instance.waitingOpponent;
  static String get waitingOpponentSubtitle => _instance.waitingOpponentSubtitle;
  static String get scoreLabel => _instance.scoreLabel;
  static String get mainMenu => _instance.mainMenu;
  static String get matchResultDraw => _instance.matchResultDraw;
  static String get matchResultWin => _instance.matchResultWin;
  static String get matchResultGameOver => _instance.matchResultGameOver;
  static String get opponentPlaceholder => _instance.opponentPlaceholder;
  static String get bonusWin => _instance.bonusWin;
  static String get bonusDraw => _instance.bonusDraw;
  static String get correctCountSuffix => _instance.correctCountSuffix;
  static String get questionsPreparing => _instance.questionsPreparing;
  static String get selectTurkishMeaning => _instance.selectTurkishMeaning;
  
  static String get bonusDescWin => _instance.bonusDescWin;
  static String get bonusDescDraw => _instance.bonusDescDraw;
  static String get bonusDescCouple => _instance.bonusDescCouple;
  static String get questionProgress => _instance.questionProgress;
  
  static String get results => _instance.results;
  static String get yourAnswers => _instance.yourAnswers;
  static String get correctWrongFmt => _instance.correctWrongFmt;
  static String get msgPerfect => _instance.msgPerfect;
  static String get msgVeryGood => _instance.msgVeryGood;
  static String get msgGood => _instance.msgGood;
  static String get msgPractice => _instance.msgPractice;
  static String get statsScore => _instance.statsScore;
  static String get statsCorrect => _instance.statsCorrect;
  static String get statsWrong => _instance.statsWrong;
  static String get statsRate => _instance.statsRate;
  static String get answerHistory => _instance.answerHistory;
  static String get yourAnswerPrefix => _instance.yourAnswerPrefix;
  static String get correctAnswerPrefix => _instance.correctAnswerPrefix;
  static String get exit => _instance.exit;
  static String get retry => _instance.retry;
  static String get quitGameTitle => _instance.quitGameTitle;
  static String get quitGameContent => _instance.quitGameContent;
  static String get quit => _instance.quit;

  // Games & Modes
  static String get gameTypeHeartShooter => _instance.gameTypeHeartShooter;
  static String get gameTypeQuiz => _instance.gameTypeQuiz;
  static String get gameTypeUnknown => _instance.gameTypeUnknown;
  static String get gameModeCouplesVs => _instance.gameModeCouplesVs;
  static String get gameModePartners => _instance.gameModePartners;

  // Invitation Dialog
  static String get invitationTitle => _instance.invitationTitle;
  static String get invitationText => _instance.invitationText;
  static String get invitationAccept => _instance.invitationAccept;
  static String get invitationDecline => _instance.invitationDecline;

  // Matchmaking
  static String get matchTitle => _instance.matchTitle;
  static String get matchPartnerRequired => _instance.matchPartnerRequired;
  static String get matchPartnerRequiredDesc => _instance.matchPartnerRequiredDesc;
  static String get matchInviteFromProfile => _instance.matchInviteFromProfile;
  static String get matchBack => _instance.matchBack;
  static String get matchNoTeamTitle => _instance.matchNoTeamTitle;
  static String get matchSetTeamName => _instance.matchSetTeamName;
  static String get matchTeamNameLabel => _instance.matchTeamNameLabel;
  static String get matchSearchOpponent => _instance.matchSearchOpponent;
  static String get matchAutoMatch => _instance.matchAutoMatch;
  static String get matchCreateRoom => _instance.matchCreateRoom;
  static String get matchCreateRoomDesc => _instance.matchCreateRoomDesc;
  static String get matchJoinRoom => _instance.matchJoinRoom;
  static String get matchJoinRoomHint => _instance.matchJoinRoomHint;
  static String get matchJoin => _instance.matchJoin;
  static String get matchRoomNotFound => _instance.matchRoomNotFound;
  static String get matchSearching => _instance.matchSearching;
  static String get matchSearchingSubtitle => _instance.matchSearchingSubtitle;
  static String get matchCancel => _instance.matchCancel;
  static String get matchRoomCode => _instance.matchRoomCode;
  static String get matchCodeCopied => _instance.matchCodeCopied;
  static String get matchWaitingOpponent => _instance.matchWaitingOpponent;
  static String get matchRoomCreationFailed => _instance.matchRoomCreationFailed;

  // No Internet Widget
  static String get noInternetTitle => _instance.noInternetTitle;
  static String get noInternetDesc => _instance.noInternetDesc;
  static String get noInternetRetry => _instance.noInternetRetry;

  // Photo Gallery Viewer
  static String get photoLoadFailed => _instance.photoLoadFailed;

  // Points Display Widget
  static String get teamPoints => _instance.teamPoints;
  static String get pointsTotal => _instance.pointsTotal;
  static String get pointsThisWeek => _instance.pointsThisWeek;

  // Team Name Dialog
  static String get teamNameMinChars => _instance.teamNameMinChars;
  static String get teamNameTaken => _instance.teamNameTaken;
  static String get teamNameConfirmTitle => _instance.teamNameConfirmTitle;
  static String get teamNameConfirmDesc => _instance.teamNameConfirmDesc;
  static String get teamNameDialogTitle => _instance.teamNameDialogTitle;
  static String get teamNameDialogDesc => _instance.teamNameDialogDesc;
  static String get teamNameHint => _instance.teamNameHint;
  static String get teamNameCreateFailed => _instance.teamNameCreateFailed;
  static String get teamNameCreate => _instance.teamNameCreate;
  static String get confirm => _instance.confirm;

  // Heart Shooter Game
  static String get hsTitle => _instance.hsTitle;
  static String get hsSelectMode => _instance.hsSelectMode;
  static String get hsModeSolo => _instance.hsModeSolo;
  static String get hsModeSoloDesc => _instance.hsModeSoloDesc;
  static String get hsModeSoloDetail => _instance.hsModeSoloDetail;
  static String get hsModePartners => _instance.hsModePartners;
  static String get hsModePartnersDesc => _instance.hsModePartnersDesc;
  static String get hsModePartnersDetail => _instance.hsModePartnersDetail;
  static String get hsInviteFailed => _instance.hsInviteFailed;
  static String get hsWaitingPartner => _instance.hsWaitingPartner;
  static String get hsWaitingPartnerDesc => _instance.hsWaitingPartnerDesc;
  static String get hsInviteDeclined => _instance.hsInviteDeclined;
  static String get hsStart => _instance.hsStart;
  static String get hsBack => _instance.hsBack;
  static String get hsPaused => _instance.hsPaused;
  static String get hsResume => _instance.hsResume;
  static String get hsRestart => _instance.hsRestart;
  static String get hsExit => _instance.hsExit;

  // Admin Panel
  static String get adminPanelTitle => _instance.adminPanelTitle;
  static String get adminDashboard => _instance.adminDashboard;
  static String get sysManagement => _instance.sysManagement;
  static String get dashboard => _instance.dashboard;
  static String get users => _instance.users;
  static String get couples => _instance.couples;
  static String get overview => _instance.overview;
  static String get totalUsers => _instance.totalUsers;
  static String get matchedCouples => _instance.matchedCouples;
  static String get totalQuestions => _instance.totalQuestions;
  static String get adminCount => _instance.adminCount;
  static String get userNotFound => _instance.userNotFound;
  static String get noCouplesYet => _instance.noCouplesYet;
  static String get searchPlaceholder => _instance.searchPlaceholder;
  static String get filterAll => _instance.filterAll;
  
  // Roles
  static String get roleUser => _instance.roleUser;
  static String get roleAdmin => _instance.roleAdmin;
  static String get roleEditor => _instance.roleEditor;
  static String get roleUnknown => _instance.roleUnknown;
  
  // Permissions
  // Permissions
  static String get adminPermissions => _instance.adminPermissions;
  static String get editorPermissions => _instance.editorPermissions;
  
  // User Management
  static String get userDetails => _instance.userDetails;
  static String get blockUser => _instance.blockUser;
  static String get unblockUser => _instance.unblockUser;
  static String get blockConfirm => _instance.blockConfirm;
  static String get unblockConfirm => _instance.unblockConfirm;
  static String get userBlocked => _instance.userBlocked;
  static String get userUnblocked => _instance.userUnblocked;
  static String get statusActive => _instance.statusActive;
  static String get statusBlocked => _instance.statusBlocked;
  static String get labelId => _instance.labelId;
  static String get labelSignupDate => _instance.labelSignupDate;
  static String get labelLastActive => _instance.labelLastActive;
  static String get labelMatchStatus => _instance.labelMatchStatus;
  static String get viewDetails => _instance.viewDetails;
  static String get labelRole => _instance.labelRole;
  static String get labelStatus => _instance.labelStatus;
  static String get statusOffline => _instance.statusOffline;

  // Actions
  static String get makeAdmin => _instance.makeAdmin;
  static String get removeAdmin => _instance.removeAdmin;
  static String get makeEditor => _instance.makeEditor;
  static String get removeRole => _instance.removeRole;
  static String get unlinkCouple => _instance.unlinkCouple;
  static String get unlinkConfirm => _instance.unlinkConfirm;
  static String get partnerUnlinked => _instance.partnerUnlinked;
  
  // Editor Panel
  static String get editorPanelTitle => _instance.editorPanelTitle;
  static String get editorPanelSubtitle => _instance.editorPanelSubtitle;
  
  // Status
  static String get statusMatched => _instance.statusMatched;
  static String get statusSingle => _instance.statusSingle;
  static String get labelUnknown => _instance.labelUnknown;

  // Auth - Multi Provider
  static String get signInWithApple => _instance.signInWithApple;
  static String get signInWithEmail => _instance.signInWithEmail;
  static String get email => _instance.email;
  static String get password => _instance.password;
  static String get confirmPassword => _instance.confirmPassword;
  static String get displayName => _instance.displayName;
  static String get forgotPassword => _instance.forgotPassword;
  static String get resetPasswordSent => _instance.resetPasswordSent;
  static String get createAccount => _instance.createAccount;
  static String get alreadyHaveAccount => _instance.alreadyHaveAccount;
  static String get dontHaveAccount => _instance.dontHaveAccount;
  static String get register => _instance.register;
  static String get login => _instance.login;
  static String get orContinueWith => _instance.orContinueWith;
  static String get emailVerificationRequired => _instance.emailVerificationRequired;
  static String get emailVerificationSent => _instance.emailVerificationSent;
  static String get resendVerification => _instance.resendVerification;
  static String get passwordMinLength => _instance.passwordMinLength;
  static String get passwordsDoNotMatch => _instance.passwordsDoNotMatch;
  static String get nameRequired => _instance.nameRequired;
  
  // Auth - Error Messages
  static String get authErrorGeneric => _instance.authErrorGeneric;
  static String get authErrorNetwork => _instance.authErrorNetwork;
  static String get authErrorTooManyRequests => _instance.authErrorTooManyRequests;
  static String get authErrorEmailInUse => _instance.authErrorEmailInUse;
  static String get authErrorUserNotFound => _instance.authErrorUserNotFound;
  static String get authErrorWrongPassword => _instance.authErrorWrongPassword;
  static String get authErrorWeakPassword => _instance.authErrorWeakPassword;
  static String get authErrorInvalidEmail => _instance.authErrorInvalidEmail;
  static String get authErrorAccountDisabled => _instance.authErrorAccountDisabled;
  static String get authErrorOperationNotAllowed => _instance.authErrorOperationNotAllowed;
  static String get authErrorInvalidCredential => _instance.authErrorInvalidCredential;
  
  // Auth - Email Verification
  static String get verifyEmailTitle => _instance.verifyEmailTitle;
  static String get verifyEmailDesc => _instance.verifyEmailDesc;
  static String get verifyEmailCheckInbox => _instance.verifyEmailCheckInbox;
  static String get verifyEmailResendIn => _instance.verifyEmailResendIn;
  static String get verifyEmailResent => _instance.verifyEmailResent;
  static String get verifyEmailIVerified => _instance.verifyEmailIVerified;
  static String get verifyEmailSeconds => _instance.verifyEmailSeconds;
  
  // Privacy Policy
  static String get privacyPolicyTitle => _instance.privacyPolicyTitle;
  static String get privacyPolicyLastUpdated => _instance.privacyPolicyLastUpdated;
  static String get privacyPolicyIntro => _instance.privacyPolicyIntro;
  static String get privacyPolicySection1Title => _instance.privacyPolicySection1Title;
  static String get privacyPolicySection1Content => _instance.privacyPolicySection1Content;
  static String get privacyPolicySection2Title => _instance.privacyPolicySection2Title;
  static String get privacyPolicySection2Content => _instance.privacyPolicySection2Content;
  static String get privacyPolicyAdmobTitle => _instance.privacyPolicyAdmobTitle;
  static String get privacyPolicyAdmobContent => _instance.privacyPolicyAdmobContent;
  static String get privacyPolicyAdmobLink => _instance.privacyPolicyAdmobLink;
  static String get privacyPolicySection3Title => _instance.privacyPolicySection3Title;
  static String get privacyPolicySection3Content => _instance.privacyPolicySection3Content;
  static String get privacyPolicySection4Title => _instance.privacyPolicySection4Title;
  static String get privacyPolicySection4Content => _instance.privacyPolicySection4Content;
  static String get privacyPolicySection5Title => _instance.privacyPolicySection5Title;
  static String get privacyPolicySection5Content => _instance.privacyPolicySection5Content;
  static String get privacyPolicySection6Title => _instance.privacyPolicySection6Title;
  static String get privacyPolicySection6Content => _instance.privacyPolicySection6Content;
  static String get privacyPolicyContactTitle => _instance.privacyPolicyContactTitle;
  static String get privacyPolicyContactDesc => _instance.privacyPolicyContactDesc;
  static String get privacyPolicyCopyright => _instance.privacyPolicyCopyright;

  // Quiz Configuration
  static String get quizConfigTitle => _instance.quizConfigTitle;
  static String get minSuccessRate => _instance.minSuccessRate;
  static String get saveSuccess => _instance.saveSuccess;
  static String get msgSuccessRateTooLow => _instance.msgSuccessRateTooLow;
}

