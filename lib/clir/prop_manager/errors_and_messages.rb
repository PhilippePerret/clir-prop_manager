module Clir
module PropManager

  __ERRORS = {
    'fr' => {
      require_data_properties: 'La classe %s doit définir DATA_PROPERTIES.',
    },
    'us' => {
      require_data_properties: 'Class %s should define DATA_PROPERTIES.'
    }

  }

  __MESSAGES = {
    'fr' => {

    },
    'us' => {
      
    }
  }

  ERRORS = __ERRORS[LANG]
  MESSAGES = __MESSAGES[LANG]

end #/module PropManager
end #/module Clir
