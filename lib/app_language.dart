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
      'Technician Feed': 'Espace technicien',
      'Dashboard overview': 'Vue d’ensemble du tableau de bord',
      'Manage profile': 'Gérer le profil',
      'View wallet': 'Voir le portefeuille',
      'Profile': 'Profil',
      'My Profile': 'Mon profil',
      'Settings': 'Paramètres',
      'Messages': 'Messages',
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
      'Confirm new password': 'Confirmer le nouveau mot de passe',
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
