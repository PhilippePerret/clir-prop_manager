module Clir
module DataManager

  ERRORS__ = {
    'fr' => {
      undefined_class: 'La classe %s est indéfinie…',
      require_data_properties: 'La classe %s doit définir DATA_PROPERTIES.',
      require_save_system: 'La class %s doit définir @@save_system dans la classe propriétaire du manager pour définir le système d’enregistrement à utiliser (:card, :file ou :conf — cf. manuel)',
      require_save_format: 'La class %s doit définir @@save_format, le format de sauvegarde, entre :yaml et :csv',
      require_save_location:'La class %s doit définir @@save_location, le lieu de sauvegarde des données (fichier ou dossier)',
      bad_save_system: '%s@@save_system doit valoir :card (enregistrement par fiche) :file (enregistrement dans un unique fichier) ou :conf (par configuration)',
      require_save_location_folder: '%s@@save_location devrait être un dossier (pour enregistrer les fiches de données)',
      require_save_location_file: '%s@@save_location doit être un fichier, pas un dossier, pour :file et :conf.',
      bas_save_format: '%s@@save_format doit être :csv ou :yaml exclusivement.',
      no_csv_format_with_card: 'L’enregistrement par fiche (:card) ne permet pas le format :csv.',
      require_relative_class: 'Pour la propriété "%s", la classe relative doit absolument existée, correspondant au nom de la propriété sans _id(s).',

      required_property: "La propriété %s est absolument requise.",
      invalid_mail: "Le mail '%s' est invalide.",
      invalid_date: "La date '%s' est invalide (format requis : JJ/MM/AAAA)",
    },
    'us' => {
      undefined_class: 'Class %s is undefined…',
      require_data_properties: 'Class %s should define DATA_PROPERTIES.',
      require_save_system: 'Owner class %s should define @@save_system, the save system to use (:card, :file ou :conf — see manual)',
      require_save_format: 'Owner class %s should define @@save_format, among :yaml and :csv',
      require_save_location:'Owner class %s should define @@save_location, this file or the folder where save data.',
      bad_save_system: '%s@@save_system should equal :card (save in card) :file (save in a one file) or :conf (configuration)',
      require_save_location_folder: '%s@@save_location should be a folder (where save cards)',
      require_save_location_file: '%s@@save_location should be a file, not a folder, for :file et :conf save_system.',
      bas_save_format: '%s@@save_format should be exclusively :csv or :yaml.',
      no_csv_format_with_card: 'Save system by card (:card) does not allow :csv format.',
      require_relative_class: 'For property "%s", a relative class should be defined, corresponding to property name.',
    
      required_property: "Property %s is required.",
      invalid_mail: "Invalid email address '%s'.",
      invalid_date: "Invalid date '%s' (format: MM/DD/YYYY)",
    }

  }

  MESSAGES__ = {
    'fr' => {
      date_format:    '%d/%m/%Y',
      reg_date_format: /^[0-3]?[0-9]\/[0-1]?[0-9]\/2[0-5][0-9][0-9]$/,
      cancel:         'Renoncer',
      create_new:     'Créer nouvel item',
      define:         'Définir',
      no:             'Non',
      save:           'Enregistrer',
      yes:            'Oui',
      still_required_values: "valeurs requises à définir",
      all_required_data_must_be_defined: "Toutes les données requises doivent être définies.",
      q_confirm_data: 'Confirmez-vous ces données ?',
      data_not_saved_cancel: "Les données n'ont pas été sauvegardées. Voulez-vous vraiment renoncer et les perdre ?",
      item_created: "Nouveau %{element} créé avec succès !",
      item_created_fem: "Nouvelle %{element} créée avec succès !",
    },
    'us' => {
      date_format:    '%m/%d/%Y',
      reg_date_format: /^[0-1]?[0-9]\/[0-3]?[0-9]\/2[0-5][0-9][0-9]$/,
      cancel:         'Cancel',
      create_new:     'Create new item',
      define:         'Define',
      no:             'No',
      save:           'Save',
      yes:            'Yes',
      still_required_values: "still required values",
      all_required_data_must_be_defined: "All required data must be defined.",
      q_confirm_data: 'Confirm theses data?',
      data_not_saved_cancel: "Data not saved. Do you really want to cancel?",
      item_created: "New %{element} created with success!",
      item_created_fem: "New %{element} created with success!",
    }
  }

  ERRORS   = ERRORS__[LANG]
  MESSAGES = MSG = MESSAGES__[LANG]

end #/module DataManager
end #/module Clir
