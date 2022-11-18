=begin
  Clir::PropManager::Manager::Displayer
  -------------------------------------
  To display a instance values
=end
module Clir
module PropManager
class Manager
class Displayer

  attr_reader :manager
  
  def initialize(manager)
    @manager = manager    
  end

  def show(instance, options)
    liste = []
    manager.each_property do |property|
      next if not(property.displayable?)
      # puts "Je dois afficher la propriété @#{property.prop} de specs #{property.specs}"
      liste << [property.name, property.formated_value_in(instance)]
    end
    puts labelize(liste)
  end

end #/class Displayer
end #/class Manager
end #/module PropManager
end #/module Clir
