=begin
  Clir::PropManager::Manager::Validator
  -------------------------------------
  To invalidate instance values

=end
module Clir
module PropManager
class Manager
class Validator

  attr_reader :manager
  
  def initialize(manager)
    @manager = manager    
  end

  # - main method -
  # 
  # Quand l'éditeur (Manager::Editor) reçoit une nouvelle valeur pour
  # la propriété +property+ ({Manager::Property}) il la checke ici
  # pour savoir si elle est valide pour l'instance +instance+
  # 
  # Noter que l'instance permet aussi de récupérer la classe de cette
  # instance pour obtenir certaines valeurs. La classe doit par ex.
  # répondre à la méthode ::get pour obtenir une autre instance.
  # 
  def valid?(property, new_value, instance)
    puts "New value: #{new_value.inspect}"
    if property.required? && (!new_value || new_value.empty? || new_value.nil?)
      return "Cette propriété est absolument requise."
    end

    return nil # OK
  end

end #/class Validator
end #/class Manager
end #/module PropManager
end #/module Clir
