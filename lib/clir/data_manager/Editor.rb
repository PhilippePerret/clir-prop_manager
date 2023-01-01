=begin
  Clir::DataManager::Manager::Editor
  -------------------------------------
  To edit a instance values (i.e. a proprerty)

  2 editing system:

    1.  Property after property
    2.  [default] All properties are displayed and user chose which
        one to edit. When all required properties are defined, the
        user can save the values.


=end
module Clir
module DataManager
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
      # Pour choisir la propriété à définir (et l'index par défaut)
      # 
      choices, index_default = set_choices_with(instance)
      clear unless debug?
      # 
      # Si une erreur a été rencontrée
      # 
      puts error.rouge unless error.nil?
      # 
      # L'user peut choisir la propriété à définir ou le choix
      # "Enregistrer" pour enregistrer l'instance
      # 
      case prop = Q.select((options[:question]||(MSG[:define_thing] % instance.class.class_name)).jaune, choices, { per_page:choices.count, default: (index_default unless choices.empty?), filter:true, show_help:false, echo:false} )
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
      if property.required?(instance) && instance.send(property.prop).nil?
        return false
      end
    end
    return true
  end

  # Tty-prompt choices panel
  # Should be update after each user input
  # 
  # @return [choices, index_default]
  # At creation, index_default is the first required property which
  # is undefined (1-start)
  # 
  def set_choices_with(instance)
    requirement_missing = false
    max_label_width = 0
    cs = manager.properties.map do |property|
      next if not(property.editable?(instance))
      pvalue = property.formated_value_in(instance)
      pname  = property.name(instance)
      pname || raise(ERRORS[:no_name_for_property] % property.prop.inspect)
      max_label_width = pname.length if pname.length > max_label_width
      [pname, pvalue]
    end.compact

    # Ajout de la gouttière entre label et valeur
    max_label_width += 4

    #
    # Le menu qui devra être sélectionné
    # 
    index_default = nil
    #
    # Index courant réel
    #
    # Avant qu'il existe des propriétés conditionnelles (:if) on
    # pouvait prendre l'index de la propriété pour savoir quel menu
    # sélectionner. Maintenant, on doit utiliser cette variable
    # +real_current_index+ pour connaitre l'index réel du menu  à
    # sélectionner ensuite.
    # 
    # On commence à 1 pour avoir le premier choix à 2 car le 
    # premier item est toujours l'item "Enregistrer"
    # 
    real_current_index = 1

    # 
    # Boucle pour récupérer tous les menus à afficher
    # 
    cs = manager.properties.map do |property|
      next if not(property.editable?(instance))
      # 
      # Est-ce une propriété requise ? (en fonction ou non de l'instance)
      # 
      is_required = property.required?(instance)

      real_current_index += 1 if index_default.nil?
      curval = instance.send(property.prop)
      isdef  = curval != nil
      #
      # Si c'est une création d'instance, on se placera automati-
      # quement sur le premier champ (property) qui n'est pas définie
      # 
      if index_default.nil? && instance.new? && not(isdef)
        index_default = real_current_index
      end
      # 
      # Si c'est une propriété requise et qu'elle n'est pas définie,
      # on indique qu'il manque des définitions avant d'avoir la
      # possibilité d'enregistrer. On en profite aussi, si c'est la
      # première, pour définir l'index par défaut
      # 
      if is_required && not(isdef)
        requirement_missing = true
        index_default = real_current_index if index_default.nil?
      end
      # choix = cs.shift
      # choix = "#{property.name(instance).ljust(max_label_width)}#{curval}"
      # 
      # Faut-il utiliser une méthode de formatage d'affichage
      # 
      fvalue  = property.formated_value_in(instance)
      choix   = "#{property.name(instance).ljust(max_label_width)}#{fvalue}"
      # 
      # Couleur en fonction de propriété requise ou non
      # 
      choix = choix.send(isdef ? :bleu : :orange) if is_required
      #
      # Marque de propriété requise
      # 
      choix = (is_required ? '* '.rouge : '  ') + choix        
      # 
      # Le choice à utiliser
      # 
      {name: choix, value: property}
    end.compact

    # 
    # Si toutes les valeurs requises sont définies, on peut ajouter
    # un menu pour enregistrer
    # 
    savable = not(requirement_missing)
    choix_save = {name: MSG[:save].send(savable ? :bleu : :gris), value: :save}
    choix_save.merge!(disabled: "(#{MESSAGES[:still_required_values]})".gris) if not(savable)
    cs.unshift(choix_save)
    # 
    # On a toujours la possibilité d'annuler l'édition
    # 
    cs << CHOIX_RENONCER
    #
    # Si l'index par défaut n'a pas pu être déterminé, on prend le
    # milieu de la liste de propriétés
    # 
    index_default = cs.count / 2 if index_default.nil?
    # 
    # On retourne la liste des choix et l'item sélectionné
    # 
    return [cs, index_default]
  end

end #/class Editor
end #/class Manager
end #/module DataManager
end #/module Clir
