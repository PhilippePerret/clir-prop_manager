=begin
  Clir::PropManager::Manager::Editor
  -------------------------------------
  To edit a instance values

  2 editing system:

    1.  Property after property
    2.  [default] All properties are displayed and user chose which
        one to edit. When all required properties are defined, the
        user can save the values.


=end
module Clir
module PropManager
class Manager
class Editor

  attr_reader :manager
  
  def initialize(manager)
    @manager = manager    
  end

  def edit(instance, options)
    data_modified = false
    data_saved    = false
    error         = nil
    while true
      # 
      # Pour choisir la propriété à définir
      # 
      choices = set_choices_with(instance)
      clear unless debug?
      # 
      # Si une erreur a été rencontrée
      # 
      puts error.rouge unless error.nil?
      # 
      # L'user peut choisir la propriété à définir ou le choix
      # "Enregistrer" pour enregistrer l'instance
      # 
      case prop = Q.select((options[:question]||MSG[:define]).jaune, choices, per_page:choices.count )
      when NilClass 
        break
      when :save
        if not(all_required?(instance))
          error = MSG[:all_required_data_must_be_defined]
        elsif data_modified && confirmed?(instance)
          instance.save 
          data_saved = true
          break
        end
      else
        modified = prop.edit(instance, options)
        data_modified = true if modified
      end
    end
    # / while
    if data_modified && not(data_saved)
      unless Q.yes?(MSG[:data_not_saved_cancel].orange)
        instance.save # on sauve les données, finalement
      end
    end
  end

  # Confirmation (ou non) des données de l'instance
  def confirmed?(instance)
    clear unless debug?
    instance.show
    puts "\n\n"
    return Q.yes?(MSG[:q_confirm_data].jaune)
  end

  # @return TRUE si toutes les propriétés requises sont définies
  # pour l'instance donnée
  def all_required?(instance)
    manager.properties.each do |property|
      if property.required? && instance.send(property.prop).nil?
        return false
      end
    end
    return true
  end

  # Tty-prompt choices panel
  # Should be update after each user input
  def set_choices_with(instance)
    requirement_missing = false
    cs = manager.properties.map do |property|
      next if not(property.editable?)
      pvalue = property.formated_value_in(instance)
      [property.name, pvalue]
    end.compact

    cs = labelize(cs).split("\n")
    cs = manager.properties.map do |property|
      next if not(property.editable?)
      isdef = instance.send(property.prop) != nil
      # 
      # Si c'est une propriété requise et qu'elle n'est pas définie,
      # on indique qu'il manque des définitions avant d'avoir la
      # possibilité d'enregistrer
      # 
      if not(isdef) && property.required?
        requirement_missing = true
      end
      choix = cs.shift
      {name: choix.send(isdef ? :vert : :blanc), value: property}
    end.compact

    # 
    # Si toutes les valeurs requises sont définies, on peut ajouter
    # un menu pour enregistrer
    # 
    savable = not(requirement_missing)
    choix_save = {name: MSG[:save].send(savable ? :bleu : :gris), value: :save}
    choix_save.merge!(disabled: "(#{MESSAGES[:still_required_values]})") if not(savable)
    cs.unshift(choix_save)
    # 
    # On a toujours la possibilité d'annuler l'édition
    # 
    cs << CHOIX_RENONCER
    return cs
  end

end #/class Editor
end #/class Manager
end #/module PropManager
end #/module Clir
