module Clir
module PropManager

  ERRORS__ = {
    'fr' => {
      require_data_properties: 'La classe %s doit définir DATA_PROPERTIES.',
    },
    'us' => {
      require_data_properties: 'Class %s should define DATA_PROPERTIES.'
    }

  }

  MESSAGES__ = {
    'fr' => {
      cancel:     'Renoncer',
      define:     'Définir',
      no:         'Non',
      save:       'Enregistrer',
      yes:        'Oui',
      still_required_values: "valeurs requises à définir",
      all_required_data_must_be_defined: "Toutes les données requises doivent être définies.",
      q_confirm_data: 'Confirmez-vous ces données ?',
      data_not_saved_cancel: "Les données n'ont pas été sauvegardées. Voulez-vous vraiment renoncer et les perdre ?",
    },
    'us' => {
      cancel:       'Cancel',
      define:       'Define',
      no:           'No',
      save:         'Save',
      yes:          'Yes',
      still_required_values: "still required values",
      all_required_data_must_be_defined: "All required data must be defined.",
      q_confirm_data: 'Confirm theses data?',
      data_not_saved_cancel: "Data not saved. Do you really want to cancel?",
    }
  }

  ERRORS   = ERRORS__[LANG]
  MESSAGES = MSG = MESSAGES__[LANG]

end #/module PropManager
end #/module Clir
