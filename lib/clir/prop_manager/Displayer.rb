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

  def show(instance, options = nil)
    liste = []
    manager.each_property do |property|
      next if not(property.displayable?)
      # puts "Je dois afficher la propriété @#{property.prop} de specs #{property.specs}"
      liste << [property.name, formated_value_of(instance, property)]
    end
    puts labelize(liste)
  end

  def formated_value_of(instance, property)
    formate_method = "f_#{property.prop}".to_sym
    if property.format_method
      instance.send(property.format_method)
    elsif instance.respond_to?(formate_method)
      instance.send(formate_method)
    else
      instance.send(property.prop)
    end
  end

end #/class Displayer
end #/class Manager
end #/module PropManager
end #/module Clir
