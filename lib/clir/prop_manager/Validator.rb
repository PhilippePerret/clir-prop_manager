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
    if property.type == :email && new_value && not(mail_valid?(new_value))
      return "Ce mail est invalide."
    end

    #
    # Une propriété requise doit exister
    # 
    if property.required? && (!new_value || new_value.empty? || new_value.nil?)
      return "Cette propriété est absolument requise."
    end

    return nil # OK
  end

  # @return true si le mail +mail+ est valide
  def mail_valid?(mail)
    mail.match?(/^(.{6,40})@([a-z\-_\.0-9]+)\.([a-z]{2,6})$/i)
  end

end #/class Validator
end #/class Manager
end #/module PropManager
end #/module Clir
