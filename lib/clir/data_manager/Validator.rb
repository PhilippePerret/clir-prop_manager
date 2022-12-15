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
    #
    # Une propriété requise doit exister
    # 
    if property.required?(instance) && (!new_value || new_value.to_s.empty?)
      return ERRORS[:required_property] % property.name
    end

    if new_value

      case property.type

      when :email
        # 
        # Un email
        # 
        if not(mail_valid?(new_value))
          return ERRORS[:invalid_mail] % new_value
        end
      when :date
        #
        # Une date
        # 
        if not(date_valid?(new_value))
          return ERRORS[:invalid_date] % new_value
        end
      when :url
        #
        # Une URL
        #
        if (err = url_invalid?(new_value))
          return ERRORS[:invalid_url] % [new_value, err]
        end
      when :people
        #
        # Un ou des people
        # 
        if (err = people_invalid?(new_value))
          return ERRORS[:invalid_people] % [property.name, err]
        end
      end # suivant property.type

      if property.valid_if
        if (err = proceed_validation_propre(property, new_value, instance))
          return ERRORS[:invalid_property] % [property.name, err]
        end
      end

    end #/si la nouvelle valeur est défini

    return nil # OK
  end

  # Quand les attributs de la propriété définissent :valid_if qui
  # permet de procéder à une validation de la donnée +new_value+
  # 
  # @return [NilClass|String] Return nil si aucune erreur n'est 
  # trouvée, sinon, retourne l'erreur rencontrée.
  def proceed_validation_propre(property, new_value, instance)
    meth = property.valid_if
    case meth 
      when Symbol
        if new_value.respond_to?(meth)
          new_value.send(meth)
        elsif instance.respond_to?(meth)
          instance.send(meth, new_value)
        elsif instance.class.respond_to?(meth)
          instance.class.send(meth, new_value, instance)
        end
      when Proc
        property.valid_if.call(new_value, instance)
      else
        raise ERRORS[:unknow_validate_method] % meth.inspect
      end
    end
  end

  # @return true si la donnée +people+ est une donnée de personne
  # valide. Une donnée de personne valide correspond à 
  def people_invalid?(people)
    people.split(',').each do |patro|
      dpatro = patro.split(' ')
      dpatro.count < 6 || raise(ERRORS[:too_long_name] % patro)
      patro.match?(/[0-9?!_,;.…\/\\"]/) && raise(ERRORS[:bad_chars_in_name] % patro)
    end
    return nil # ok
  rescue Exception => e
    return e.message
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

  # Noter que cette méthode fonctionne à l'inverse des autres : elle
  # retourne un message d'erreur en cas d'invalidité et elle ne
  # retourne rien si tout est OK
  # 
  def url_invalid?(url)
    require 'net/http'
    uri = URI(url)
    Net::HTTP.get(uri)
    return nil # ok
  rescue Exception => e
    return e.message
  # ensure
  #   puts "request: #{request.inspect}"
  #   sleep 10
  #   exit
  end

end #/class Validator
end #/class Manager
end #/module DataManager
end #/module Clir
