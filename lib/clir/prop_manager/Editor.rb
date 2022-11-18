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
    puts "Je dois apprendre à éditer l'instance #{instance.inspect} avec les options #{options.inspect}.".jaune    
    choices = set_choices_with(instance)
    case prop = Q.select((options[:question]||"Définir").jaune, choices, per_page:choices.count )
    when NilClass then return
    when :save
      puts "Je dois apprendre à sauver l'instance"
    else
      puts "Je dois apprendre à éditer #{prop.inspect}"
    end
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
    choix_save = {name:"Enregistrer".send(savable ? :bleu : :gris), value: :save}
    choix_save.merge!(disabled: '(required values)') if not(savable)
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
