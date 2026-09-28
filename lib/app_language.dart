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
      'Dashboard overview': 'Vue d’ensemble du tableau de bord',
      'Manage profile': 'Gérer le profil',
      'View wallet': 'Voir le portefeuille',
      'Profile': 'Profil',
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
      'Search for tasks or pros...':
          'Rechercher des tâches ou des professionnels...',
      'Type a message...': 'Écrivez un message...',
      'Write a message': 'Écrivez un message',
      'Send': 'Envoyer',
      'Message client': 'Contacter le client',
      'Message Tech': 'Contacter le technicien',
      'Message Company': 'Contacter l’entreprise',
      'Retry': 'Réessayer',
      'No results found.': 'Aucun résultat trouvé.',
      'No questions yet.': 'Aucune question pour le moment.',
      'Nothing to display yet.': 'Rien à afficher pour le moment.',
      'Post a Task': 'Publier une tâche',
      'Post a New Task': 'Publier une nouvelle tâche',
      'Browse Tasks': 'Parcourir les tâches',
      'Browse Open Tasks': 'Parcourir les tâches ouvertes',
      'Browse Services': 'Parcourir les services',
      'Open Task': 'Ouvrir la tâche',
      'View Profile': 'Voir le profil',
      'View Bids': 'Voir les offres',
      'Submit bid': 'Soumettre une offre',
      'Bid submitted successfully.': 'Offre soumise avec succès.',
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
      'Manage Services': 'Gérer les services',
      'Publish the services your company offers. Clients will see these on your public profile.':
          'Publiez les services proposés par votre entreprise. Les clients les verront sur votre profil public.',
      'Your company registration documents are under administrative review. Publishing and managing services will unlock upon admin verification.':
          'Les documents d’enregistrement de votre entreprise sont en cours d’examen administratif. La publication et la gestion des services seront disponibles après vérification.',
      'Company profile': 'Profil de l’entreprise',
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
      'First Name': 'Prénom',
      'John': 'Jean',
      'Last Name': 'Nom',
      'Doe': 'Dupont',
      'Email Address': 'Adresse e-mail',
      'Phone Number': 'Numéro de téléphone',
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
    final title = raw[0].toUpperCase() + raw.substring(1).toLowerCase();
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
      decoration: const InputDecoration(labelText: 'Language'),
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
