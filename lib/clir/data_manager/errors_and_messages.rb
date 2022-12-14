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
      require_relative_class: 'Pour la propriété "%s", la classe relative doit absolument exister, correspondant au nom de la propriété sans _id(s).',
      choice_unfound_in_choices_list: "Impossible de trouver la valeur (:value) '%s' dans la liste des valeurs de la propriété %s (%s)…",
      unknown_if_attribut: "Je ne sais pas traiter la valeur %s pour l'attribut :if…",
      unable_to_get_class_from_class_min: "Impossible de tirer la classe relative de '%s'%s",
      specs_undefined: "La propriété :%s doit définir ses :specs",
      value_doesnt_respond_to: "La valeur %s:%s ne répond pas à %s",
      no_name_for_property: "La propriété %s doit absolument définir son :name (si c'est une procédure, s'assurer qu'elle retourne bien une valeur).",

      required_property: "La propriété %s est absolument requise.",
      invalid_mail: "Le mail '%s' est invalide.",
      invalid_date: "La date '%s' est invalide (format requis : JJ/MM/AAAA)",
      invalid_url: "L'URL '%s' est invalide : %s.",
      invalid_people: "La donnée %s est invalide : %s…",
      too_long_name:  "Le nom '%s' contient trop de mots pour être un nom",
      bad_chars_in_name: "Le nom '%s' contient des caractères impossibles dans un nom",

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
      choice_unfound_in_choices_list: "Unfound value (:value) '%s' in values of %s property… (%s)",
      unknown_if_attribut: "Can't treat %s value for :if attribute…",
      unable_to_get_class_from_class_min: "Unable to get relative class from '%s'%s",
      specs_undefined: ":%s property should defined its :specs",
      value_doesnt_respond_to: "%s:%s value doesn't respond to %s",
      no_name_for_property: "%s property should defined its :name attribute (if it's a Proc, make sure it returns a value).",
    
      required_property: "Property %s is required.",
      invalid_mail: "Invalid email address '%s'.",
      invalid_date: "Invalid date '%s' (format: MM/DD/YYYY)",
      invalid_url: "Invalid URL '%s'. Reason: %s.",
      invalid_people: "Invalid data: %s (%s)…",
      too_long_name:  "The name '%s' contains too much word to be a real name",
      bad_chars_in_name: "The name '%s' contains unexpected characters",
    }

  }

  MESSAGES__ = {
    'fr' => {
      date_format:    '%d/%m/%Y',
      reg_date_format: /^[0-3]?[0-9]\/[0-1]?[0-9]\/2[0-5][0-9][0-9]$/,
      cancel:         'Renoncer',
      choose:         'Choisir',
      create_new:     'Créer nouvel item',
      define:         'Définir',
      define_thing:   'Définir %s',
      no:             'Non',
      not_treated:    '%s non traité',
      save:           'Enregistrer',
      yes:            'Oui',
      still_required_values: "valeurs requises à définir",
      all_required_data_must_be_defined: "Toutes les données requises doivent être définies.",
      q_confirm_data: 'Confirmez-vous ces données ?',
      data_not_saved_cancel: "Les données n'ont pas été sauvegardées. Voulez-vous vraiment renoncer et les perdre ?",
      item_created: "Nouveau %{element} créé avec succès !",
      item_created_fem: "Nouvelle %{element} créée avec succès !",
      item_updated: "%s #%s actualisé.",
      item_updated_fem: "%s #%s actualisée.",
      no_items_to_display: "Aucun élément à afficher.", 

    },
    'us' => {
      date_format:    '%m/%d/%Y',
      reg_date_format: /^[0-1]?[0-9]\/[0-3]?[0-9]\/2[0-5][0-9][0-9]$/,
      cancel:         'Cancel',
      choose:         'Choose',
      create_new:     'Create new item',
      define:         'Define',
      define_thing:   'Définir %s',
      no:             'No',
      not_treated:    '%s not traited',
      save:           'Save',
      yes:            'Yes',
      still_required_values: "still required values",
      all_required_data_must_be_defined: "All required data must be defined.",
      q_confirm_data: 'Confirm theses data?',
      data_not_saved_cancel: "Data not saved. Do you really want to cancel?",
      item_created: "New %{element} created with success!",
      item_created_fem: "New %{element} created with success!",
      item_updated: "%s #%s updated.",
      item_updated_fem: "%s #%s updated.",
      no_items_to_display: "No item to display.", 
    }
  }

  ERRORS   = ERRORS__[LANG]
  MESSAGES = MSG = MESSAGES__[LANG]

end #/module DataManager
end #/module Clir
