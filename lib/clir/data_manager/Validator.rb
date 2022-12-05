=begin
  Clir::DataManager::Manager::Validator
  -------------------------------------
  To invalidate instance values

=end
module Clir
module DataManager
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
      return ERRORS[:invalid_mail] % new_value
    end

    #
    # Une date
    # 
    if property.type == :date && new_value && not(date_valid?(new_value))
      return ERRORS[:invalid_date] % new_value
    end

    #
    # Une propriété requise doit exister
    # 
    if property.required? && (!new_value || new_value.to_s.empty?)
      return ERRORS[:required_property] % property.name
    end

    return nil # OK
  end

  # @return true si le mail +mail+ est valide
  def mail_valid?(mail)
    mail.match?(/^(.{6,40})@([a-z\-_\.0-9]+)\.([a-z]{2,6})$/i)
  end

  def date_valid?(date)
    date.match?(MSG[:reg_date_format]) || return
    begin
      m, d, y = date.split('/').map {|n| n.to_i }
      if LANG == 'fr'
        Time.new(y, d, m)
      else
        Time.new(y, m, d)
      end
    rescue
      return false
    end
    return true
  end

end #/class Validator
end #/class Manager
end #/module DataManager
end #/module Clir
