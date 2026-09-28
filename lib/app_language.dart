import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  AppLanguage._();

  static const supported = <String>['en', 'fr'];
  static const labels = <String, String>{'en': 'English', 'fr': 'Français'};
  static const _key = 'language_preference';
  static final ValueNotifier<String> current = ValueNotifier<String>('en');

  static const _translations = <String, Map<String, String>>{
    'fr': {
      'Dashboard': 'Tableau de bord',
      'Dashboard refreshed successfully!':
          'Tableau de bord actualisé avec succès !',
      'Refresh failed': 'Actualisation échouée',
      'Track your active projects, team size, and total revenue.':
          'Suivez vos projets actifs, la taille de votre équipe et vos revenus totaux.',
      'Active Projects': 'Projets actifs',
      'Manage': 'Gérer',
      'Monitor your ongoing company projects and milestones.':
          'Suivez vos projets d’entreprise et leurs étapes.',
      'Your Team': 'Votre équipe',
      'Open': 'Ouvrir',
      'Service Catalog': 'Catalogue de services',
      'Add and edit the services your company offers.':
          'Ajoutez et modifiez les services proposés par votre entreprise.',
      'Track your earnings, pending escrow, and withdraw funds.':
          'Suivez vos revenus, votre séquestre en attente et retirez vos fonds.',
      'Find open jobs and submit your bids to get hired.':
          'Trouvez des missions ouvertes et soumettez vos offres.',
      'Your Active Tasks': 'Vos tâches actives',
      'Saved Professionals': 'Professionnels enregistrés',
      'Browse All': 'Tout parcourir',
      'Top Rated Professionals': 'Professionnels les mieux notés',
      'See all': 'Tout voir',
      'See how you rank against top professionals in your area.':
          'Découvrez votre classement par rapport aux meilleurs professionnels de votre région.',
      'Need something done? Start by posting a task for professionals to see.':
          'Besoin de quelque chose ? Publiez une tâche pour les professionnels.',
      'Manage all your open and ongoing tasks right here.':
          'Gérez ici toutes vos tâches ouvertes et en cours.',
      'Keep track of the professionals you love working with.':
          'Suivez les professionnels avec lesquels vous aimez travailler.',
      'Get the most out of Buolot by adding your required details.':
          'Profitez pleinement de Boulot Man en ajoutant les informations requises.',
      'Welcome back': 'Bon retour',
      'What service do you need?': 'De quel service avez-vous besoin ?',
      'Need something done?': 'Besoin de quelque chose ?',
      'Post a task & get bids fast':
          'Publiez une tâche et recevez vite des offres',
      'Ready to work?': 'Prêt à travailler ?',
      'Browse active tasks in your area':
          'Parcourez les tâches actives de votre région',
      'Find Tasks': 'Trouver des tâches',
      'Manage your team': 'Gérez votre équipe',
      'Track milestones and escrow payments':
          'Suivez les étapes et les paiements sous séquestre',
      'Complete Your Profile': 'Complétez votre profil',
      'Almost there!': 'Presque terminé !',
      'Please provide the required details to activate your account.':
          'Veuillez fournir les informations requises pour activer votre compte.',
      'Education Level': 'Niveau d’études',
      'Expertise Level': 'Niveau d’expertise',
      'Hourly Rate (\$)': 'Tarif horaire (\$)',
      'Daily Rate (\$)': 'Tarif journalier (\$)',
      'Fixed Starting Price (\$)': 'Prix fixe de départ (\$)',
      'Inspection/Call-out Fee (\$)': 'Frais d’inspection / déplacement (\$)',
      'Work Preferences': 'Préférences de travail',
      'Available for On-site jobs': 'Disponible pour les missions sur site',
      'Available for Remote jobs': 'Disponible pour les missions à distance',
      'Available on Weekends': 'Disponible le week-end',
      'Available for Emergency/Urgent jobs':
          'Disponible pour les missions urgentes',
      'I own the necessary tools (including PPE)':
          'Je possède les outils nécessaires (EPI inclus)',
      'I have a reliable vehicle for transit':
          'Je possède un véhicule fiable pour les déplacements',
      'Professional Bio': 'Biographie professionnelle',
      'Identity Verification Documents': 'Documents de vérification d’identité',
      'National ID (Front)': 'Pièce d’identité nationale (recto)',
      'National ID (Back)': 'Pièce d’identité nationale (verso)',
      'Live Selfie': 'Selfie en direct',
      'Company Name': 'Nom de l’entreprise',
      'Headquarters / Industry': 'Siège social / secteur',
      'Company Size (e.g., 10-50 employees)':
          'Taille de l’entreprise (ex. 10 à 50 employés)',
      'Max Project Capacity (e.g., \$1M+)':
          'Capacité maximale de projet (ex. \$1M+)',
      'Company About': 'À propos de l’entreprise',
      'Verification Documents': 'Documents de vérification',
      'Business Registration Document':
          'Document d’enregistrement de l’entreprise',
      'Tax ID Certificate': 'Certificat d’identification fiscale',
      'Operating Licence': 'Licence d’exploitation',
      'Save Profile': 'Enregistrer le profil',
      'Document Uploaded': 'Document téléversé',
      'Tap to Upload': 'Appuyez pour téléverser',
      'Tap to upload document': 'Appuyez pour téléverser un document',
      'Enter a valid number.': 'Saisissez un nombre valide.',
      'Required field': 'Champ obligatoire',
      'Company Verification': 'Vérification de l’entreprise',
      'Get Verified': 'Obtenir la vérification',
      'Business Registration': 'Enregistrement de l’entreprise',
      'Upload your official business registration documents and trade license to verify your company.':
          'Téléversez les documents officiels d’enregistrement et la licence commerciale de votre entreprise.',
      'Compliance Review': 'Examen de conformité',
      'Provide additional compliance details. This helps us ensure your company meets platform standards.':
          'Fournissez des informations de conformité supplémentaires pour nous aider à vérifier votre entreprise.',
      'Identity Verification': 'Vérification d’identité',
      'Upload a valid government-issued ID to confirm your identity.':
          'Téléversez une pièce d’identité officielle valide pour confirmer votre identité.',
      'Skill Screening': 'Évaluation des compétences',
      'Tell us more about your professional background and skills.':
          'Parlez-nous de votre parcours professionnel et de vos compétences.',
      'Certifications': 'Certifications',
      'Add any relevant licenses or professional certifications.':
          'Ajoutez les licences ou certifications professionnelles pertinentes.',
      'PNG, JPG or PDF (Max 5MB)': 'PNG, JPG ou PDF (5 Mo maximum)',
      'Tap to upload': 'Appuyez pour téléverser',
      'Submit for Review': 'Soumettre pour examen',
      'Under Review': 'En cours d’examen',
      "Your verification documents have been submitted. We'll notify you once our team has reviewed them (usually within 24-48 hours).":
          'Vos documents de vérification ont été soumis. Nous vous informerons après examen par notre équipe (généralement sous 24 à 48 heures).',
      'Feed': 'Fil',
      'Expert': 'Expert',
      'Business': 'Entreprise',
      'Inbox': 'Boîte de réception',
      'Admin': 'Administration',
      'Escrow': 'Séquestre',
      'Dashboard overview': 'Vue d’ensemble du tableau de bord',
      'Manage profile': 'Gérer le profil',
      'View wallet': 'Voir le portefeuille',
      'Profile': 'Profil',
      'Personal Details': 'Informations personnelles',
      'First Name': 'Prénom',
      'Last Name': 'Nom',
      'Phone Number': 'Numéro de téléphone',
      'City / Town': 'Ville',
      'Occupation': 'Profession',
      'Languages': 'Langues',
      'Bio': 'Biographie',
      'Verification': 'Vérification',
      'Skills & Categories': 'Compétences et catégories',
      'No skills added yet.': 'Aucune compétence ajoutée.',
      'Experience': 'Expérience',
      'No experience details added yet.': 'Aucune expérience ajoutée.',
      'Certifications & Licences': 'Certifications et licences',
      'No certifications or licences added yet.':
          'Aucune certification ou licence ajoutée.',
      'Availability': 'Disponibilité',
      'Pricing': 'Tarification',
      'No pricing added yet.': 'Aucune tarification ajoutée.',
      'No work preferences added yet.': 'Aucune préférence de travail ajoutée.',
      'Tools & Equipment': 'Outils et équipement',
      'Boulot Man Eligibility': 'Éligibilité Boulot Man',
      'Account Actions': 'Actions du compte',
      'Profile Actions': 'Actions du profil',
      'Post a Task': 'Publier une tâche',
      'Create a new job request': 'Créer une nouvelle demande de mission',
      'Manage Services': 'Gérer les services',
      'Link or unlink your verified skills':
          'Associer ou dissocier vos compétences vérifiées',
      'Inbox / Messages': 'Boîte de réception / Messages',
      'Chat with clients and manage tasks':
          'Discutez avec les clients et gérez les tâches',
      'Manage Portfolio': 'Gérer le portfolio',
      'Add or edit your past projects':
          'Ajoutez ou modifiez vos anciens projets',
      'Professional References': 'Références professionnelles',
      'Provide private verification references':
          'Fournissez des références privées de vérification',
      'Payout Settings': 'Paramètres de paiement',
      'Manage preferred payment methods securely':
          'Gérez vos modes de paiement en toute sécurité',
      'Company Registration': 'Enregistrement de l’entreprise',
      'Update legal and verification details':
          'Mettez à jour les informations légales et de vérification',
      'Support & Trust': 'Assistance et confiance',
      'Track balance, payouts, and transactions':
          'Suivez le solde, les paiements et les transactions',
      'Manage identity and compliance review':
          'Gérez la vérification d’identité et de conformité',
      'Open a Dispute': 'Ouvrir un litige',
      'Report a task issue or resolution request':
          'Signalez un problème de tâche ou demandez une résolution',
      'Help Center': 'Centre d’aide',
      'FAQs, support, and platform guidance':
          'FAQ, assistance et guide de la plateforme',
      'Not provided': 'Non renseigné',
      'My Profile': 'Mon profil',
      'Settings': 'Paramètres',
      'Messages': 'Messages',
      'Notifications': 'Notifications',
      'No messages yet': 'Aucun message pour le moment',
      'Delete Conversation': 'Supprimer la conversation',
      'Are you sure you want to delete this chat? All messages will be permanently removed.':
          'Voulez-vous vraiment supprimer cette conversation ? Tous les messages seront supprimés définitivement.',
      'Error deleting chat': 'Erreur lors de la suppression de la conversation',
      'No notifications yet.': 'Aucune notification pour le moment.',
      'Notification': 'Notification',
      'New task available': 'Nouvelle tâche disponible',
      'A new task matching your category will appear here.':
          'Une nouvelle tâche correspondant à votre catégorie apparaîtra ici.',
      'New message': 'Nouveau message',
      'No unread conversations.': 'Aucune conversation non lue.',
      'You have a message from': 'Vous avez un message de',
      'Project update': 'Mise à jour du projet',
      'Your project activity will appear here.':
          'L’activité de votre projet apparaîtra ici.',
      'Verification reminder': 'Rappel de vérification',
      'Upload compliance documents to keep your company verified.':
          'Téléversez les documents de conformité pour garder votre entreprise vérifiée.',
      'You have an active chat thread with':
          'Vous avez une conversation active avec',
      'Task completed': 'Tâche terminée',
      'Task in progress': 'Tâche en cours',
      'Bids received': 'Offres reçues',
      'Welcome to Boulot Man': 'Bienvenue sur Boulot Man',
      'Post a task or browse professionals to get started!':
          'Publiez une tâche ou consultez les professionnels pour commencer !',
      'Just now': "À l'instant",
      'Today': "Aujourd'hui",
      'Yesterday': 'Hier',
      '5 min ago': 'Il y a 5 min',
      'Payments': 'Paiements',
      'Recent Transactions': 'Transactions récentes',
      'No transactions recorded.': 'Aucune transaction enregistrée.',
      'Available Balance': 'Solde disponible',
      'Withdraw Funds': 'Retirer des fonds',
      'Transactions': 'Transactions',
      'Wallet': 'Portefeuille',
      'Projects': 'Projets',
      'My Projects': 'Mes projets',
      'My Tasks': 'Mes tâches',
      'Tasks': 'Tâches',
      'Bids': 'Offres',
      'Save': 'Enregistrer',
      'Save settings': 'Enregistrer les paramètres',
      'Save all changes': 'Enregistrer toutes les modifications',
      'Cancel': 'Annuler',
      'Delete account': 'Supprimer le compte',
      'Log Out': 'Se déconnecter',
      'Delete Account': 'Supprimer le compte',
      'Delete Account?': 'Supprimer le compte ?',
      'This permanently deletes your profile, documents, tasks, bids, and account data. This action cannot be undone.':
          'Cette action supprime définitivement votre profil, vos documents, tâches, offres et données. Elle est irréversible.',
      'Type DELETE to confirm': 'Saisissez DELETE pour confirmer',
      'DELETE': 'DELETE',
      'Delete permanently': 'Supprimer définitivement',
      'Logout': 'Se déconnecter',
      'Log out': 'Se déconnecter',
      'Language': 'Langue',
      'English': 'English',
      'Français': 'Français',
      'Change password': 'Modifier le mot de passe',
      'Current password': 'Mot de passe actuel',
      'New password': 'Nouveau mot de passe',
      'First name': 'Prénom',
      'Last name': 'Nom',
      'Email': 'E-mail',
      'Phone': 'Téléphone',
      'Country': 'Pays',
      'City': 'Ville',
      'Save Changes': 'Enregistrer les modifications',
      'Saving...': 'Enregistrement...',
      'Settings saved successfully.': 'Paramètres enregistrés avec succès.',
      'Password changed successfully.': 'Mot de passe modifié avec succès.',
      'Available': 'Disponible',
      'Available now': 'Disponible maintenant',
      'Busy': 'Occupé',
      'Offline': 'Hors ligne',
      'Pending': 'En attente',
      'Accepted': 'Accepté',
      'Rejected': 'Refusé',
      'Active': 'Actif',
      'Inactive': 'Inactif',
      'Completed': 'Terminé',
      'Cancelled': 'Annulé',
      'Search': 'Rechercher',
      'Refresh': 'Actualiser',
      'Submit': 'Soumettre',
      'Create': 'Créer',
      'Edit': 'Modifier',
      'Delete': 'Supprimer',
      'Close': 'Fermer',
      'Back': 'Retour',
      'Next': 'Suivant',
      'Done': 'Terminé',
      'New Password': 'Nouveau mot de passe',
      'Enter new password': 'Saisissez le nouveau mot de passe',
      'Confirm New Password': 'Confirmer le nouveau mot de passe',
      'Confirm new password': 'Confirmer le nouveau mot de passe',
      'Please enter the 6-digit code.': 'Saisissez le code à 6 chiffres.',
      'Please enter a new password.': 'Saisissez un nouveau mot de passe.',
      'Passwords do not match.': 'Les mots de passe ne correspondent pas.',
      'A new verification code was sent.':
          'Un nouveau code de vérification a été envoyé.',
      'Resend Code': 'Renvoyer le code',
      'Continue': 'Continuer',
      'Please enter your email.': 'Saisissez votre e-mail.',
      'Please enter a valid email address.':
          'Saisissez une adresse e-mail valide.',
      'Search tasks...': 'Rechercher des tâches...',
      'Search your bids...': 'Rechercher dans vos offres...',
      'Search services and tasks...':
          'Rechercher des services et des tâches...',
      'Search by name or skills...': 'Rechercher par nom ou compétence...',
      'Browse Professionals': 'Parcourir les professionnels',
      'We could not load professionals right now.':
          'Impossible de charger les professionnels pour le moment.',
      'No professionals found': 'Aucun professionnel trouvé',
      'Try searching for another skill category or adjust your keyword query.':
          'Essayez une autre catégorie de compétence ou modifiez votre recherche.',
      'Search for tasks or pros...':
          'Rechercher des tâches ou des professionnels...',
      'Type a message...': 'Écrivez un message...',
      'Attachment': 'Pièce jointe',
      'Attachment Preview': 'Aperçu de la pièce jointe',
      'Download': 'Télécharger',
      'Share a File': 'Partager un fichier',
      'Photo': 'Photo',
      'Document': 'Document',
      'Video': 'Vidéo',
      'Files': 'Fichiers',
      'Write a message': 'Écrivez un message',
      'Send': 'Envoyer',
      'Message client': 'Contacter le client',
      'Message Tech': 'Contacter le technicien',
      'Message Company': 'Contacter l’entreprise',
      'Retry': 'Réessayer',
      'No results found.': 'Aucun résultat trouvé.',
      'No questions yet.': 'Aucune question pour le moment.',
      'Nothing to display yet.': 'Rien à afficher pour le moment.',
      'Post a New Task': 'Publier une nouvelle tâche',
      'Browse Tasks': 'Parcourir les tâches',
      'Browse Open Tasks': 'Parcourir les tâches ouvertes',
      'Browse Services': 'Parcourir les services',
      'Task details': 'Détails de la tâche',
      'Contract Terminated / Deleted': 'Contrat terminé / supprimé',
      'This task has been cancelled and deleted by the client. Any escrow hold funds have been refunded to the client\'s wallet.':
          'Cette tâche a été annulée et supprimée par le client. Les fonds retenus sous séquestre ont été remboursés au portefeuille du client.',
      'Contract Terminated': 'Contrat terminé',
      'Submit Work': 'Soumettre le travail',
      'Are you sure you want to mark this task as done and submit it for client review?':
          'Voulez-vous vraiment marquer cette tâche comme terminée et la soumettre à l’examen du client ?',
      'Work submitted successfully! Client has been notified.':
          'Travail soumis avec succès ! Le client a été informé.',
      'Failed to submit work': 'Échec de la soumission du travail',
      'Work Submitted': 'Travail soumis',
      'Clients cannot bid': 'Les clients ne peuvent pas faire d’offre',
      'Bid Submitted': 'Offre soumise',
      'Submit a Bid': 'Soumettre une offre',
      'Update Bid': 'Modifier l’offre',
      'Send Bid': 'Envoyer l’offre',
      'Your bid amount': 'Montant de votre offre',
      'Task budget: up to': 'Budget de la tâche : jusqu’à',
      'Estimated completion': 'Délai estimé',
      'Cover message': 'Message de présentation',
      'Message Client': 'Contacter le client',
      'Submitting a bid lets the client review your timeline, price, and experience before hiring.':
          'Une offre permet au client d’examiner votre délai, votre prix et votre expérience avant de vous engager.',
      'Open Task': 'Ouvrir la tâche',
      'View Profile': 'Voir le profil',
      'View Bids': 'Voir les offres',
      'Submit bid': 'Soumettre une offre',
      'Bid submitted successfully.': 'Offre soumise avec succès.',
      'Bids Received': 'Offres reçues',
      'Error loading bids': 'Erreur lors du chargement des offres',
      'No bids received yet for this task.':
          'Aucune offre reçue pour cette tâche.',
      'ACCEPTED': 'ACCEPTÉE',
      'BEST VALUE': 'MEILLEUR RAPPORT QUALITÉ-PRIX',
      'Bid accepted and task moved to In Progress.':
          'Offre acceptée et tâche passée en cours.',
      'Accept Bid': 'Accepter l’offre',
      'Please enter a valid bid amount.':
          'Saisissez un montant d’offre valide.',
      'Please write a pitch or message.':
          'Rédigez une présentation ou un message.',
      'Task title is required.': 'Le titre de la tâche est obligatoire.',
      'Location address is required.': 'L’adresse du lieu est obligatoire.',
      'Please specify a valid budget.': 'Indiquez un budget valide.',
      'Task updated successfully!': 'Tâche mise à jour avec succès !',
      'Task deleted successfully.': 'Tâche supprimée avec succès.',
      'Complete Task': 'Terminer la tâche',
      'Complete Now': 'Terminer maintenant',
      'Edit Details': 'Modifier les détails',
      'Remove Saved': 'Retirer des favoris',
      'Add a Service': 'Ajouter un service',
      'Post a Service': 'Publier un service',
      'Service name': 'Nom du service',
      'New service': 'Nouveau service',
      'Edit service': 'Modifier le service',
      'Service title': 'Titre du service',
      'Loading service categories...':
          'Chargement des catégories de services...',
      'Service type': 'Type de service',
      'On-site': 'Sur site',
      'Remote': 'À distance',
      'Fixed': 'Fixe',
      'Hourly': 'Horaire',
      'Range': 'Fourchette',
      'Active / visible listing': 'Annonce active / visible',
      'Add images, videos, or documents':
          'Ajouter des images, vidéos ou documents',
      'Please enter a service title.': 'Saisissez le titre du service.',
      'My Services': 'Mes services',
      'Deactivate service?': 'Désactiver le service ?',
      'This will remove the service from your active profile.':
          'Ce service sera retiré de votre profil actif.',
      'Deactivate': 'Désactiver',
      'Service deactivated.': 'Service désactivé.',
      'Manage services': 'Gérer les services',
      'Services Management': 'Gestion des services',
      'Publish the services your company offers. Clients will see these on your public profile.':
          'Publiez les services proposés par votre entreprise. Les clients les verront sur votre profil public.',
      'Your company registration documents are under administrative review. Publishing and managing services will unlock upon admin verification.':
          'Les documents d’enregistrement de votre entreprise sont en cours d’examen administratif. La publication et la gestion des services seront disponibles après vérification.',
      'Company profile': 'Profil de l’entreprise',
      'Registration Status': 'Statut d’enregistrement',
      'Verified': 'Vérifié',
      'Pending Review': 'Vérification en attente',
      'Registration pending review.':
          'Enregistrement en attente de vérification.',
      'Verification Status': 'Statut de vérification',
      'Verification pending review.': 'Vérification en attente d’examen.',
      'About Company': 'À propos de l’entreprise',
      'Services': 'Services',
      'Team': 'Équipe',
      'Ratings & Reviews': 'Évaluations et avis',
      'Rating': 'Évaluation',
      'Team Size': 'Taille de l’équipe',
      'No company description provided yet.':
          'Aucune description de l’entreprise pour le moment.',
      'Registered contractor profile with services, project tracking, and compliance flows.':
          'Profil d’entreprise enregistrée avec services, suivi de projets et conformité.',
      'Industry': 'Secteur',
      'Company Size': 'Taille de l’entreprise',
      'Registration No.': 'N° d’enregistrement',
      'Headquarters': 'Siège social',
      'Capabilities & Infrastructure': 'Capacités et infrastructure',
      'No services listed yet.': 'Aucun service répertorié.',
      'Description': 'Description',
      'Category': 'Catégorie',
      'Select Category': 'Sélectionner une catégorie',
      'Select Subcategory': 'Sélectionner une sous-catégorie',
      'Select Service': 'Sélectionner un service',
      'Pricing model': 'Modèle de tarification',
      'Fixed price': 'Prix fixe',
      'Hourly rate': 'Tarif horaire',
      'Daily rate': 'Tarif journalier',
      'Budget': 'Budget',
      'Deadline': 'Date limite',
      'Project Title': 'Titre du projet',
      'Project summary': 'Résumé du projet',
      'Requested service': 'Service demandé',
      'Save service': 'Enregistrer le service',
      'Service added successfully!': 'Service ajouté avec succès !',
      'Service removed.': 'Service supprimé.',
      'Define your service offering': 'Définissez votre offre de services',
      'Service Title *': 'Titre du service *',
      'e.g. Professional Office Deep Cleaning':
          'ex. Nettoyage professionnel de bureaux',
      'Category *': 'Catégorie *',
      'Service Description *': 'Description du service *',
      'Describe what you offer, your process, and what clients can expect...':
          'Décrivez votre offre, votre processus et ce que les clients peuvent attendre...',
      'Pricing Model': 'Modèle de tarification',
      'How do you charge for this service?':
          'Comment facturez-vous ce service ?',
      'Pricing Model *': 'Modèle de tarification *',
      'Custom Price Label (optional)':
          'Libellé de prix personnalisé (facultatif)',
      'Leave empty to auto-generate from the amounts above.':
          'Laissez vide pour générer automatiquement à partir des montants ci-dessus.',
      'Fixed Price': 'Prix fixe',
      'Hourly Rate': 'Tarif horaire',
      'Project-Based': 'Par projet',
      'One set price for the whole service':
          'Un prix fixe pour tout le service',
      'Charge per hour of work': 'Facturation à l’heure',
      'Quote per project scope': 'Devis selon l’étendue du projet',
      'Price Preview': 'Aperçu du prix',
      'When and where is your service available?':
          'Quand et où votre service est-il disponible ?',
      'Service Delivery Type *': 'Type de prestation *',
      'Coverage Area': 'Zone couverte',
      'Working Days': 'Jours ouvrés',
      'Working Hours': 'Heures de travail',
      'On-Site': 'Sur site',
      'You visit the client': 'Vous vous rendez chez le client',
      'Service provided remotely': 'Service fourni à distance',
      'Both': 'Les deux',
      'On-site and remote available': 'Sur site et à distance disponibles',
      'Publish Service': 'Publier le service',
      'Please add a description for your service.':
          'Ajoutez une description de votre service.',
      'Please enter a price or a custom price label.':
          'Saisissez un prix ou un libellé de prix personnalisé.',
      'Please select at least one working day.':
          'Sélectionnez au moins un jour ouvré.',
      'Service Published': 'Service publié',
      'Remove Service': 'Supprimer le service',
      'Delete account permanently?': 'Supprimer définitivement le compte ?',
      'Keep editing': 'Continuer la modification',
      'Discard changes': 'Abandonner les modifications',
      'New support ticket': 'Nouveau ticket d’assistance',
      'Reply to support': 'Répondre à l’assistance',
      'New ticket': 'Nouveau ticket',
      'Subject': 'Sujet',
      'Describe the issue': 'Décrivez le problème',
      'Support ticket submitted.': 'Ticket d’assistance envoyé.',
      'Reply sent.': 'Réponse envoyée.',
      'Change Cover': 'Modifier la couverture',
      'Choose from gallery': 'Choisir dans la galerie',
      'Take a photo': 'Prendre une photo',
      'Retake': 'Reprendre',
      'Use photo': 'Utiliser la photo',
      'Cancel Task?': 'Annuler la tâche ?',
      'Reject quote': 'Refuser le devis',
      'Accept': 'Accepter',
      'Reject': 'Refuser',
      'Remove': 'Retirer',
      'Complete': 'Terminer',
      'Add Milestone': 'Ajouter un jalon',
      'Release Funds': 'Libérer les fonds',
      'Funds secured in escrow!': 'Fonds sécurisés sous séquestre !',
      'Payment released successfully!': 'Paiement libéré avec succès !',
      'Escrow released!': 'Séquestre libéré !',
      'Client dashboard': 'Tableau de bord client',
      'Company dashboard': 'Tableau de bord entreprise',
      'Welcome': 'Bienvenue',
      'Find trusted professionals and manage your projects.':
          'Trouvez des professionnels fiables et gérez vos projets.',
      'Projects & Contracts': 'Projets et contrats',
      'On Hold': 'En pause',
      'New Contract': 'Nouveau contrat',
      'No contracts here': 'Aucun contrat ici',
      'Tap "New Contract" to create one':
          'Appuyez sur « Nouveau contrat » pour en créer un',
      'Released': 'Libéré',
      'In Escrow': 'Sous séquestre',
      'Awaiting': 'En attente',
      "You haven't posted any tasks yet":
          "Vous n’avez encore publié aucune tâche",
      'No active contracts yet. Browse tasks to bid.':
          'Aucun contrat actif. Parcourez les tâches pour faire une offre.',
      'No active projects assigned yet':
          'Aucun projet actif ne vous est attribué',
      'Browse live work near you':
          'Parcourez les missions disponibles près de chez vous',
      'Task Title': 'Titre de la tâche',
      'Enter task title': 'Saisissez le titre de la tâche',
      'Category & Subcategory': 'Catégorie et sous-catégorie',
      'Select subcategory': 'Sélectionner une sous-catégorie',
      'Provide as much detail as possible...':
          'Décrivez la tâche avec le plus de détails possible...',
      'Please provide as much detail as possible. Minimum 50 characters.':
          'Veuillez fournir autant de détails que possible. Minimum 50 caractères.',
      'Attachments (Optional)': 'Pièces jointes (facultatif)',
      'Location': 'Lieu',
      'Enter address': 'Saisissez l’adresse',
      'Location detected': 'Lieu détecté',
      'Detect My Location (IP-based)': 'Détecter ma position (par IP)',
      'Estimated Budget': 'Budget estimé',
      'When do you need this done?':
          'Quand souhaitez-vous que ce soit terminé ?',
      'Urgency': 'Urgence',
      'Preferred Payment Method': 'Mode de paiement préféré',
      'Step 1 of 2': 'Étape 1 sur 2',
      'Task Details (Draft)': 'Détails de la tâche (brouillon)',
      'File attached successfully': 'Fichier joint avec succès',
      'Max file size 10MB': 'Taille maximale du fichier : 10 Mo',
      'Remove Attachment': 'Supprimer la pièce jointe',
      'Unable to open the legal page.':
          'Impossible d’ouvrir la page juridique.',
      'Please fill all required fields.':
          'Veuillez remplir tous les champs obligatoires.',
      'Please accept the Terms of Service.':
          'Veuillez accepter les conditions d’utilisation.',
      'Please enter your city.': 'Veuillez saisir votre ville.',
      'Create Account': 'Créer un compte',
      "Let's get started. Enter your basic information.":
          'Commençons. Saisissez vos informations de base.',
      'John': 'Jean',
      'Doe': 'Dupont',
      'Email Address': 'Adresse e-mail',
      'Password': 'Mot de passe',
      'Select Country': 'Sélectionner un pays',
      'Already have an account?': 'Vous avez déjà un compte ?',
      'Log In': 'Se connecter',
      'What are you looking for?': 'Que recherchez-vous ?',
      'Select how you intend to use Boulot Man.':
          'Indiquez comment vous comptez utiliser Boulot Man.',
      'Where are you located?': 'Où êtes-vous situé(e) ?',
      'e.g. Douala': 'ex. Douala',
      'Service Location / Address (Optional)':
          'Lieu / adresse du service (facultatif)',
      'e.g. Akwa': 'ex. Akwa',
      "I agree to Boulot Man's ": "J’accepte les ",
      'Terms of Service': 'conditions d’utilisation',
      ' and ': ' et la ',
      'Privacy Policy': 'politique de confidentialité',
      'Posting locked': 'Publication verrouillée',
      'Task': 'Tâche',
      'draft': 'Brouillon',
      'Location not specified': 'Lieu non indiqué',
      'bids': 'offres',
      'Home': 'Accueil',
      'Search tasks or cities': 'Rechercher des tâches ou des villes',
      'This notification has no linked page.':
          'Cette notification n’a aucune page associée.',
      'Task posting is locked until an administrator verifies your account.':
          'La publication de tâches est verrouillée jusqu’à la vérification de votre compte.',
      'Dashboard data unavailable': 'Données du tableau de bord indisponibles',
      'Check your connection and try again.':
          'Vérifiez votre connexion et réessayez.',
      'Your company account is verified.':
          'Votre compte entreprise est vérifié.',
      'Your company account is pending admin verification.':
          'Votre compte entreprise est en attente de vérification administrative.',
      'New project': 'Nouveau projet',
      'Create project': 'Créer un projet',
      'Project publishing unlocks after admin verification.':
          'La publication de projets sera disponible après vérification administrative.',
      'Technician Feed': 'Espace technicien',
    },
  };

  static String text(String value) =>
      _translations[current.value]?[value] ?? value;

  static String status(dynamic value) {
    final raw = '$value'.trim();
    if (raw.isEmpty) return raw;
    final normalized = raw.replaceAll('_', ' ').replaceAll('-', ' ');
    final title = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
    return text(title);
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? prefs.getString('lang');
    if (saved != null && supported.contains(saved)) current.value = saved;
  }

  static Future<void> setLocal(String code) async {
    if (!supported.contains(code)) return;
    current.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    await prefs.setString('lang', code);
  }
}

class AppLanguagePicker extends StatelessWidget {
  const AppLanguagePicker({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: AppLanguage.current,
    builder: (context, value, _) => DropdownButtonFormField<String>(
      initialValue: AppLanguage.supported.contains(value) ? value : 'en',
      decoration: InputDecoration(labelText: AppLanguage.text('Language')),
      items: [
        for (final code in AppLanguage.supported)
          DropdownMenuItem(
            value: code,
            child: Text(AppLanguage.text(AppLanguage.labels[code]!)),
          ),
      ],
      onChanged: (code) {
        if (code != null) AppLanguage.setLocal(code);
      },
    ),
  );
}
