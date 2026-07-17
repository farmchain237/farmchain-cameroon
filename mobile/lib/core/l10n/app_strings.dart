/// All UI strings in one place.
/// Every screen reads from here — never hardcodes text directly.
/// Adding a new language = add a new case below, nothing else changes.

enum AppLang { en, fr, pcm } // pcm = Cameroon Pidgin

class S {
  final AppLang lang;
  const S(this.lang);

  // ── Welcome / Language ──────────────────────────────────────────
  String get welcome => _t('Welcome', 'Bienvenue', 'Welcome');
  String get chooseLanguage => _t(
      'Choose your language',
      'Choisissez votre langue',
      'Pick de language wey yu want');
  String get continueBtn => _t('Continue', 'Continuer', 'Kontinu');
  String get english => 'English';
  String get french => 'Français';
  String get pidgin => 'Pidgin';

  // ── Auth ────────────────────────────────────────────────────────
  String get enterPhone => _t(
      'Enter your phone number',
      'Entrez votre numéro de téléphone',
      'Put ya fon numba');
  String get phoneNumber => _t('Phone number', 'Numéro de téléphone', 'Ya fon numba');
  String get sendCode => _t('Send code', 'Recevoir le code', 'Send de code');
  String get verifyCode => _t('Verify code', 'Vérifier le code', 'Check de code');
  String get codeSent => _t(
      'Code sent. Enter it below.',
      'Code envoyé. Entrez-le ci-dessous.',
      'Wi don send de code. Put am down.');
  String get confirm => _t('Confirm', 'Confirmer', 'Konfam');
  String get fullName => _t('Full name', 'Nom complet', 'Your name dem');
  String get login => _t('Login', 'Connexion', 'Enter');
  String get signUp => _t('Sign up', 'S\'inscrire', 'Make account');
  String get invalidCode => _t(
      'Invalid or expired code. Try again.',
      'Code invalide ou expiré. Réessayez.',
      'Di code no correct. Try again.');
  String get errorSendingCode => _t(
      'Error sending code. Check your connection.',
      'Impossible d\'envoyer le code. Vérifiez votre connexion.',
      'E nor work, check your net.');

  // ── Roles ───────────────────────────────────────────────────────
  String get whoAreYou => _t('Who are you?', 'Vous êtes...?', 'Who you be?');
  String get farmer => _t('Farmer (crops)', 'Agriculteur (cultures)', 'Farmer (farm tins)');
  String get animalRaiser => _t('Animal raiser', 'Éleveur d\'animaux', 'Animal dem person');
  String get fishFarmer => _t('Fish farmer', 'Pisciculteur', 'Fish person');
  String get buyer => _t('Buyer', 'Acheteur', 'Person wey de buy');
  String get transporter => _t('Transporter', 'Transporteur', 'Driver');
  String get employee => _t('Employee', 'Employé', 'Worker');

  // ── Profile / Signup ────────────────────────────────────────────
  String get city => _t('City', 'Ville', 'Which town');
  String get whatDoYouSell => _t('What do you sell mainly?', 'Que vendez-vous surtout?', 'Wetin you de sell?');
  String get crops => _t('Crops (cacao, coffee...)', 'Cultures (cacao, café...)', 'Things them for farm');
  String get animals => _t('Animals (chickens, goats...)', 'Animaux (poulets, chèvres...)', 'Animal dem');
  String get fish => _t('Fish (tilapia...)', 'Poissons (tilapia...)', 'Fish');
  String get companyCode => _t('Company code', 'Code de l\'entreprise', 'Company code');
  String get companyCodeHint => _t(
      'Given by your employer',
      'Donné par votre patron',
      'Wey your oga give you');
  String get jobTitle => _t('Job title', 'Poste', 'Wetin you do');
  String get createPin => _t('Create your 4-digit PIN', 'Créez votre code PIN (4 chiffres)', 'Make your 4-numba PIN');
  String get createProfile => _t('Create my profile', 'Créer mon profil', 'Make my profile');

  // ── Marketplace ─────────────────────────────────────────────────
  String get marketplace => _t('Marketplace', 'Marché', 'Market place');
  String get myListings => _t('My listings', 'Mes annonces', 'Ma tings wey a de sell');
  String get newListing => _t('+ New listing', '+ Nouvelle annonce', '+ Add wetin yu de sell');
  String get search => _t('Search', 'Rechercher', 'Search');
  String get filter => _t('Filter', 'Filtrer', 'Filter');
  String get pricePerKg => _t('Price per kg', 'Prix par kg', 'How mush for one kilo');
  String get availableQty => _t('Available quantity', 'Quantité disponible', 'How many remain');
  String get harvestDate => _t('Harvest date', 'Date de récolte', 'Wen dem cut am');
  String get grade => _t('Grade', 'Grade', 'Grade');
  String get buyNow => _t('Buy now', 'Acheter maintenant', 'Bai am now');
  String get contactSeller => _t('Contact seller', 'Contacter le vendeur', 'Tok to seller');

  // ── Orders / Payment ────────────────────────────────────────────
  String get payment => _t('Payment', 'Paiement', 'Payment');
  String get paymentProtected => _t(
      'Your MoMo payment is protected until delivery',
      'Votre paiement MoMo est protégé jusqu\'à la livraison',
      'Ya MoMo money safe til dem deliver am');
  String get deliveryConfirmed => _t(
      'Delivery confirmed',
      'Livraison confirmée',
      'Dem don deliver am');
  String get escrowInfo => _t(
      'Money is held safely until delivery is confirmed',
      'L\'argent est retenu jusqu\'à confirmation de livraison',
      'Di money dey safe til e reach you');

  // ── Chat ────────────────────────────────────────────────────────
  String get chat => _t('Chat', 'Discussions', 'Tok-tok');
  String get communityChat => _t('Community', 'Communauté', 'Community');
  String get chatComingSoon => _t(
      'Chat coming soon',
      'Messagerie bientôt disponible',
      'Tok-tok e dey come');
  String get voiceNote => _t('Voice note', 'Note vocale', 'Tok record');
  String get typeMessage => _t('Type a message...', 'Tapez un message...', 'Write sometin...');

  // ── Videos ──────────────────────────────────────────────────────
  String get videos => _t('Videos', 'Vidéos', 'Vidéo dem');
  String get recordVideo => _t('Record video', 'Enregistrer une vidéo', 'Record vidéo');
  String get videoType => _t('Video type', 'Type de vidéo', 'Which kain vidéo');
  String get maxSeconds => _t('Max 60 seconds', 'Max 60 secondes', 'Max 60 sekonds');
  String get videoSent => _t('Video sent', 'Vidéo envoyée', 'Dem don send di vidéo');
  String get videoFailed => _t(
      'Upload failed. Will retry when connected.',
      'Échec de l\'envoi. Nouvel essai dès connexion.',
      'E nor work. Wi go try again wen net come back.');

  // ── Security ────────────────────────────────────────────────────
  String get security => _t('Security', 'Sécurité', 'Security');
  String get addCamera => _t('Add camera', 'Ajouter une caméra', 'Add camera');
  String get cameraName => _t('Camera name', 'Nom de la caméra', 'Wetin you call di camera');
  String get rtspUrl => _t('RTSP URL', 'URL RTSP', 'Camera link (RTSP)');
  String get testConnection => _t('Test connection', 'Tester la connexion', 'Test am');
  String get motionDetected => _t('Motion detected', 'Mouvement détecté', 'Sometin dey move');
  String get cameraOffline => _t('Camera offline', 'Caméra hors ligne', 'Camera don go off');
  String get liveView => _t('Live view', 'Vue en direct', 'Watch am live');
  String get noEvents => _t('No recent events', 'Aucun événement récent', 'Notin happen yet');

  // ── Employee / Clock ────────────────────────────────────────────
  String get clockIn => _t('Clock in', 'Pointer l\'entrée', 'Mark ya time (enter)');
  String get clockOut => _t('Clock out', 'Pointer la sortie', 'Mark ya time (comot)');
  String get enterPin => _t('Enter your 4-digit PIN', 'Entrez votre PIN à 4 chiffres', 'Put your 4-numba PIN');
  String get clockInSuccess => _t('Clock-in recorded', 'Pointage entrée enregistré', 'Wi don mark your time');
  String get clockOutSuccess => _t('Clock-out recorded', 'Pointage sortie enregistré', 'Wi don mark your comot time');
  String get wrongPin => _t('Wrong PIN. Try again.', 'PIN incorrect. Réessayez.', 'Di PIN no correct. Try again.');
  String get noShiftOpen => _t('No active shift found.', 'Aucun pointage en cours.', 'You never clock in yet.');

  // ── Settings ────────────────────────────────────────────────────
  String get settings => _t('Settings', 'Paramètres', 'Settings');
  String get language => _t('Language', 'Langue', 'Language');
  String get switchLanguage => _t('Switch language', 'Changer de langue', 'Change language');
  String get profile => _t('My profile', 'Mon profil', 'My profile');
  String get logout => _t('Log out', 'Se déconnecter', 'Comot');

  // ── Admin ───────────────────────────────────────────────────────
  String get adminPanel => _t('Admin Panel', 'Panneau Admin', 'Admin Panel');
  String get users => _t('Users', 'Utilisateurs', 'People dem');
  String get auditUsers => _t('Audit users', 'Auditer les utilisateurs', 'Check people dem');
  String get suspendUser => _t('Suspend user', 'Suspendre l\'utilisateur', 'Block dis person');
  String get allOrders => _t('All orders', 'Toutes les commandes', 'All orders dem');
  String get revenue => _t('Revenue', 'Revenus', 'Money wey e come');
  String get platformFee => _t('Platform fee', 'Frais plateforme', 'Platform cut');
  String get appSettings => _t('App settings', 'Paramètres app', 'App settings');
  String get feePercent => _t('Fee percentage', 'Pourcentage de frais', 'How mush percent');
  String get totalUsers => _t('Total users', 'Utilisateurs total', 'All people');
  String get activeListings => _t('Active listings', 'Annonces actives', 'Tins wey dem de sell');
  String get disputes => _t('Disputes', 'Litiges', 'Problem dem');

  // ── General ─────────────────────────────────────────────────────
  String get success => _t('Success', 'Succès', 'E don work');
  String get error => _t('Error', 'Erreur', 'Problem');
  String get loading => _t('Loading...', 'Chargement...', 'E dey load...');
  String get retry => _t('Retry', 'Réessayer', 'Try again');
  String get cancel => _t('Cancel', 'Annuler', 'Comot');
  String get save => _t('Save', 'Enregistrer', 'Save am');
  String get delete => _t('Delete', 'Supprimer', 'Delete am');
  String get yes => _t('Yes', 'Oui', 'Yes');
  String get no => _t('No', 'Non', 'No');
  String get back => _t('Back', 'Retour', 'Go back');
  String get noConnection => _t(
      'No internet connection',
      'Pas de connexion internet',
      'Net nor dey');
  String get offlineMode => _t(
      'Offline mode — showing cached data',
      'Mode hors ligne — données en cache',
      'No net — na old data dis');

  // ── Helper ──────────────────────────────────────────────────────
  String _t(String en, String fr, String pcm) {
    switch (lang) {
      case AppLang.fr: return fr;
      case AppLang.pcm: return pcm;
      case AppLang.en: return en;
    }
  }
}
