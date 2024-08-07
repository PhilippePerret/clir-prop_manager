
LANG = 'fr'
require_relative 'errors_and_messages'

module Clir
module DataManager
  include ClirDataManagerConstants


  CHOIX_RENONCER  = {name: MSG[:cancel].orange, value:nil}
  CHOIX_CREATE    = {name: MSG[:create_new].bleu, value: :create}


  YAML_OPTIONS = {symbolize_names: true, permitted_classes: [Date, Integer, Symbol, Time]}

end #/module DataManager
end #/module Clir
