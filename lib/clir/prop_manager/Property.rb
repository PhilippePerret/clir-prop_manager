module Clir
module PropManager
class Property
  include ClirPropManagerConstants

  attr_reader :manager
  attr_reader :data

  # @param manager {Clir::PropManager::Manager} The manager
  # @param data {Hash} Property data table
  def initialize(manager, data = nil)
    @manager  = manager
    @data     = data
  end

  # --- Edition Methods ---

  ##
  # Méthode principale de l'édition de la propriété pour l'instance
  # +instance+ avec les options éventuelles +options+
  # 
  # @return TRUE si la donnée a été modifiée, FALSE dans le cas
  # contraire.
  # 
  def edit(instance, options = nil)
    # 
    # La valeur par défaut
    # Soit la valeur actuelle de l'instance, soit la valeur définie
    # par :default dans les propriétés, qui peut être soit une procé-
    # dure soit une méthode de classe ou d'instance.
    # 
    defvalue = instance.send(prop) || default(instance)
    # 
    # On utilise une édition différente en fonction du type de la
    # donnée
    # 
    error = nil
    while true
      puts error.rouge if error
      new_value =
        case type
        when :string
          # FIXED: Noter que pour le moment, on ne peut pas mettre
          # à nil (vide) on une valeur est déjà définie.
          Q.ask(question(instance).jaune, {default: defvalue})&.strip
        else
          puts "Je ne sais pas encore éditer une donnée de type #{type.inspect}.".orange
        end
      #
      # On vérifie la validité de la donnée, si une méthode de 
      # validation a été définie. Si la donnée est valide, on la 
      # consigne, sinon non demande à la modifier.
      # 
      error = valid?(new_value, instance)
      break if error.nil?

    end #/while invalid
    # 
    # La donnée a-t-elle changée ?
    # 
    modified = new_value != current_value(instance)
    #
    # S'il y a eu modification, on affecte la nouvelle valeur
    # 
    instance.send("#{prop}=".to_sym, new_value) if modified
    # 
    # On indique si la donnée a été modifiée
    # 
    return modified
  end

  # --- Méthodes de check ---

  # @return Nil si OK ou le message d'erreur à afficher
  def valid?(new_value, instance)
    return if new_value && (new_value == current_value(instance))
    return manager.validator.valid?(self, new_value, instance)
  end

  # --- Helpers Methods ---

  def formated_value_in(instance)
    return '---' if instance.send(prop).nil?
    formate_method = "f_#{prop}".to_sym
    if format_method
      instance.send(format_method)
    elsif instance.respond_to?(formate_method)
      instance.send(formate_method)
    else
      instance.send(prop)
    end
  end


  # @prop La valeur actuelle de cette propriété
  # 
  def current_value(instance)
    instance.send(prop)
  end

  # @prop La question à poser pour cette propriété
  # 
  # 
  def question(instance)
    if quest
      quest % instance.data
    else
      "Nouvelle valeur pour #{name.inspect} : "
    end
  end

  # --- Predicate Methods ---

  def required?
    :TRUE == @isrequired ||= true_or_false(specs & REQUIRED > 0)
  end

  def displayable?
    :TRUE == @isdisplayable ||= true_or_false(specs & DISPLAYABLE > 0)
  end

  def editable?
    :TRUE == @iseditable ||= true_or_false(specs & EDITABLE > 0)
  end

  def removable?
    :TRUE == @isremovable ||= true_or_false(specs & REMOVABLE > 0)
  end

  # --- Hard Coded Properties ---

  def name;     @name     ||= data[:name]     end
  def specs;    @specs    ||= data[:specs]    end
  def prop;     @prop     ||= data[:prop]     end
  def type;     @type     ||= data[:type]     end
  def quest;    @quest    ||= data[:quest]    end
  def default(instance)
    d = data[:default]
    d = d.call(instance) if d.is_a?(Proc)
    if d.is_a?(Symbol)
      if instance.respond_to?(d)
        instance.send(d)
      elsif instance.class.respond_to?(d)
        d = instance.class.send(d)
      else
        # La garder telle quelle
      end
    end
    d
  end
  def format_method; @format_method ||= data[:mformate] end

end #/class Property
end #/module PropManager
end #/module Clir
