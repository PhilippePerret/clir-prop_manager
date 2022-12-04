
LANG = 'fr'
require_relative 'errors_and_messages'

module Clir
module DataManager
  include ClirDataManagerConstants


  CHOIX_RENONCER  = {name: MSG[:cancel], value:nil}
  CHOIX_CREATE    = {name: MSG[:create_new], value: :create}

end #/module DataManager
end #/module Clir
