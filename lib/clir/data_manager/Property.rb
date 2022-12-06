module Clir
module DataManager
class Property
  include ClirDataManagerConstants

  attr_reader :manager
  attr_reader :data

  # @param manager {Clir::DataManager::Manager} The manager
  # @param data {Hash} Property data table
  def initialize(manager, data = nil)
    @manager  = manager
    @data     = data || {}
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
    error     = nil
    question  = question(instance).jaune
    while true
      puts error.rouge if error
      new_value =
        case type
        when :id
          # [N0001]
          # Cas spécial d'une propriété <>_id. Si tout a bien été
          # défini, DataManager a mis dans l'attribut other_class la
          # classe de l'élément.
          if relative_class
            item = relative_class.choose({create: true, filter: values_filter})
            item&.id
          else
            raise ERRORS[:require_relative_class] % [prop.to_s, relative_class.to_s]
          end
        when :ids
          # Cf. [N0001] ci-dessus
          if relative_class
            multi_choose(instance, options)
          else
            raise ERRORS[:require_relative_class] % [prop.to_s, relative_class.to_s]
          end
        when :date
          defvalue ||= Time.now.strftime(MSG[:date_format])
          new_date = Q.ask(question, {default: defvalue})&.strip
          
        when :string, :email, :date, :prix
          # FIXED: Noter que pour le moment, on ne peut pas mettre
          # à nil (vide) quand une valeur est déjà définie.
          Q.ask(question, {default: defvalue})&.strip
        when :select
          choices = select_values_with_precedences(instance)
          value = Q.select(question, choices, {default:default_select_value(instance, choices), per_page:values.count})
          values.set_last(value)
          value
        when :bool
          Q.select(question, BOOLEAN_VALUES, {default: boolean_default_value(instance), per_page:BOOLEAN_VALUES.count})
        else
          puts "Je ne sais pas encore éditer une donnée de type #{type.inspect}.".orange
          sleep 3
          break
        end
      #
      # Si la propriété définit une méthode de transformation de
      # l'entrée, on l'utilise
      if new_value && itransform
        new_value = transform_new_value(instance, new_value)
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
    formatage_method = "f_#{prop}".to_sym
    if format_method # :mformat dans la définition de la propriété
      if format_method.is_a?(Proc)
        format_method.call(current_value(instance), instance)
      else
        instance.send(format_method)
      end
    elsif instance.respond_to?(formatage_method)
      instance.send(formatage_method)
    else
      instance.send(prop)
    end
  end

  # --- Functional Methods ---

  ##
  # Permet de choisir des valeurs multiples, pour le moment plusieurs
  # identifiants d'une classe relative.
  # 
  # La méthode doit être appelée après avoir vérifié que la 
  # relative_class existait bien.
  # 
  def multi_choose(instance, options)
    curvalue = current_value(instance) || []
    # 
    # La valeur propre du filtre
    filter_for_instance = nil
    if values_filter
      filter_for_instance = {}
      values_filter.each do |key, value|
        if value.is_a?(Symbol) # => propriété de l'instance
          value = instance.send(value)
        end
        filter_for_instance.merge!(key => value)
      end
    end
    # 
    # On demande toutes les instances choisies
    # 
    insts = relative_class.choose({multi:true, create: false, filter: filter_for_instance, default: curvalue})
    curvalue = insts.map(&:id)
    # puts "curvalue : #{curvalue.inspect}"
    # 
    # Valeur finale à retourner
    # 
    curvalue = nil if curvalue.empty?
    return curvalue
  end

  ##
  # Si la propriété définit :itransform (méthode de transformation
  # de la donnée entrée), cette méthode est appelée pour transformer
  # la donnée.
  def transform_new_value(instance, new_value)
    case itransform
    when Symbol
      if instance.respond_to?(itransform)
        instance.send(itransform, new_value)
      elsif new_value.respond_to?(itransform)
        new_value.send(itransform)
      else
        raise "La valeur #{new_value.inspect} ne répond pas à #{itransform.inspect}…"
      end
    when Proc
      itransform.call(instance, new_value)
    end
  end

  def select_values_with_precedences(instance)
    # values
    uniq_name = "#{instance.class.name.to_s.gsub(/::/,'-')}-#{prop}".downcase
    @values = PrecedencedList.new(values, uniq_name) unless values.instance_of?(PrecedencedList)
    return values.to_prec
  end

  # @return l'index de la valeur actuelle de l'instance pour la 
  # propriété courante, lorsque c'est un select (tty-prompt, en
  # valeur par défaut, ne supporte que l'index, ou le :name du menu)
  # Si la valeur n'est pas définie ou si elle est introuvable, on
  # retourne nil
  def default_select_value(instance, vals)
    cvalue = current_value(instance) || default(instance) || return
    vals.each_with_index do |dchoix, idx|
      return idx + 1 if dchoix[:value] == cvalue
    end
    return nil
  end

  # @prop La valeur actuelle de cette propriété
  def current_value(instance)
    instance.send(prop)
  end

  # @prop La question à poser pour cette propriété
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

  def index;    @index    ||= data[:index]    end
  def name;     @name     ||= data[:name]     end
  def specs;    @specs    ||= data[:specs]    end
  def prop;     @prop     ||= data[:prop]     end
  def type;     @type     ||= data[:type]     end
  def quest;    @quest    ||= data[:quest]    end
  def values;   @values   ||= data[:values]   end
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
  def values_filter;    @values_filter  ||= data[:values_filter]  end
  def itransform;       @itransform     ||= data[:itransform]     end
  def relative_class;   @relative_class ||= data[:relative_class] end
  def format_method;    @format_method  ||= data[:mformat]||data[:mformate]||data[:format_method] end

  BOOLEAN_VALUES = [
    {name: MSG[:yes]    , value: true   },
    {name: MSG[:no]     , value: false  },
    {name: MSG[:cancel] , value: nil    }
  ]
end #/class Property
end #/module DataManager
end #/module Clir
