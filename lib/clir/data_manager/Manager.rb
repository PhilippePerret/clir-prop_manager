module Clir
#
# Structure qui permet de conserver les items groupés
# @note
#   Cf. @@group_by et le manuel.
# 
GroupedItems = Struct.new(:name, :id, :items)

module DataManager
class << self
  def new(classe, data_properties = nil)
    Manager.new(classe, data_properties)
  end
end #/<< self module

class Manager

  ##
  # Méthode qui retourne un nouvel identifiant pour la classe
  # propriétaire.
  # 
  # Suivant le type de données, on trouve le dernier identifiant :
  #   - dans un fichier contenant les informations générales sur
  #     la classe d'objets
  #   - en relevant les ID d'un fichier YAML et en prenant le
  #     dernier.
  #   - en fouillant dans un dossier de fiches pour trouver la
  #     dernière.
  # 
  def __new_id
    case save_system
    when :card
      id = if File.exist?(last_id_path)
        File.read(last_id_path).strip.to_i + 1
      else 
        mkdir(File.dirname(last_id_path)) # to make sure folder exists
        1 
      end
      File.write(last_id_path, id.to_s)
      return id
    when :file
      @last_id || begin 
        load_data
        @last_id
      end
      return @last_id += 1
    when :conf
      puts "Je ne sais pas encore gérer le système de sauvegarde :conf.".orange
      raise(ExitSilently)
    end
  end

  attr_reader :classe
  attr_reader :data_properties
  attr_reader :items
  
  def initialize(classe, data_properties = nil)
    @data_properties = data_properties || begin
      defined?(classe::DATA_PROPERTIES) || raise(ERRORS[:require_data_properties] % classe.name)
      classe::DATA_PROPERTIES
    end
    @classe = classe
    #
    # Pour que rubocop ne râle pas…
    # 
    @table  = nil
    @is_full_loaded = false
    # 
    # Méthodes d'instance
    # 
    prepare_instance_methods_of_class
    # 
    # Méthodes de classe
    # 
    prepare_class_methods
    # 
    # On doit s'assurer que la class propriétaire du manager est 
    # valide, c'est-à-dire définit et contient tous les éléments 
    # nécessaires.
    # 
    owner_class_valid? || raise(ExitSilently)
    # 
    # On doit s'assurer que la classe définit bien son système de
    # sauvegarde et son lieu de sauvegarde
    # 
  end

  # @return true si la classe propriétaire est valide
  def owner_class_valid?
    classe.class_variable_defined?("@@save_system")   || raise(ERRORS[:require_save_system] % classe.name)
    classe.class_variable_defined?('@@save_location') || raise(ERRORS[:require_save_location] % classe.name)
    classe.class_variable_defined?('@@save_format')   || raise(ERRORS[:require_save_format] % classe.name)    
    [:card,:file,:conf].include?(save_system) || raise(ERRORS[:bad_save_system] % classe.name)
    [:csv, :yaml].include?(save_format) || raise(ERRORS[:bas_save_format] % classe.name)
    
    if save_system == :card && save_format == :csv
      raise(ERRORS[:no_csv_format_with_card])
    end
    if File.exist?(save_location)
      if save_system == :card
        File.directory?(save_location) || raise(ERRORS[:require_save_location_folder] % classe.name)
      else
        File.directory?(save_location) && raise(ERRORS[:require_save_location_file] % classe.name)
      end
    end
    # 
    # Si c'est un système d'enregistrement par fiche, on prépare
    # déjà le fichier du dernier identifiant.
    # 
    if save_system == :card
      File.write(last_id_path,"0") unless File.exist?(last_id_path)
    end
  rescue Exception => e
    puts "\n#{e.message}\n".rouge
    return false
  else
    return true
  end

  def add(item)
    item.data.merge!(id: __new_id) if item.data[:id].nil?
    @items ||= []
    @items << item
    @table ||= {}
    @table.merge!(item.id => item)
  end

  ##
  # Permet de choisir une instance
  # 
  # Par défaut, c'est la deuxième propriété qui est utilisée pour
  # l'affichage (sa version "formatée" si elle existe) mais les
  # options fournies peuvent définir une autre propriété avec l'at-
  # tribut :name_property
  # 
  # @param [Hash] options
  # @option options [String]  :question   La question à poser ("Choisir" par défaut)
  # @option options [Boolean] :multi      Si true, on peut choisir plusieurs éléments
  # @option options [Boolean] :create     Si true, on peut créer un nouvel élément
  # @option options [Hash]    :filter     Filtre à appliquer aux valeurs à afficher
  #     Avec le filtre, les instances n'apparaitront pas à l'écran, contrairement à :exclude.
  # @option options [Array]   :exclude    Liste d'identifiants qu'ils faut rendre "inchoisissables".
  # @option options [Array]   :default    Quand :multi, les valeurs à sélectionner par défaut. C'est une liste d'identifiants.
  # 
  def choose(options = nil)
    # 
    # Définition des options
    # 
    options ||= {}
    options.key?(:multi) || options.merge!(multi: false)
    options[:question]   ||= "#{MSG[:choose]} : "
    options[:question] = options[:question].jaune
    load_data unless full_loaded?
    @tty_name_procedure = nil
    # 
    # Définition des menus
    # 
    cs = get_choices_with_precedences(options)
    # 
    # Interaction
    # 
    if options[:multi]
      # 
      # Menus sélectionnés par défaut
      # 
      selecteds = nil 
      selecteds = get_default_choices(cs, options) if options[:default]
      # 
      # L'utilisateur procède aux choix
      # 
      choixs = Q.multi_select(options[:question], cs, {filter:true, default: selecteds, echo:false})
      if choixs.include?(:create)
        choixs.delete(:create)
        choixs << classe.new.create
      end
      #
      # Enregistrement de la précédence
      # 
      choixs = choixs.map do |choix|
        next if choix.nil?
        choose_precedence_set(choix.id)
        if choix.instance_of?(GroupedItems)
          choose_in_list_of_grouped_items(choix, options)
        else
          choix
        end
      end.compact
      # 
      # Instances retournées
      # 
      choixs
    else
      # 
      # L'utilisateur procède au choix 
      # 
      choix = Q.select(options[:question], cs, {per_page: 20, filter:true})
      choix = classe.new.create if choix == :create
      choix || return # cancel
      choose_precedence_set(choix.id)
      # 
      # Si c'est une liste d'items groupés, il faut encore choisir
      # dans cette liste l'item qui sera renvoyé. Sinon, on retourne
      # l'item choisi.
      # 
      if choix.instance_of?(GroupedItems)
        choix = choose_in_list_of_grouped_items(choix, options)
      end
      choix
    end
  end

  # @return [Any] Any instance chosen in +group+ 
  # @param [GroupedItemss] group Instance with items grouped
  #
  def choose_in_list_of_grouped_items(group, options)
    choices = group.items.map do |item|
      {name: item.name, value: item}
    end + [CHOIX_RENONCER]
    Q.select(options[:question], choices, {per_page:choices.count})
  end

  # Pour afficher des items les uns sur les autres, avec des
  # informations réduites.
  # 
  # @param options [Hash|Nil]  Options
  # @option options [Hash] :filter Filtre pour n'afficher que les items
  #     correspondant à :filter. :filter est une table de clés qui
  #     correspondent aux propriétés de l'item et de valeurs qui sont
  #     les valeurs attendues.
  # @option options [Periode] :periode Période concernée par l'affichage.
  # 
  def display_items(options = nil)
    full_loaded? || load_data
    # 
    # Dans le cas d'absence d'items
    # 
    @items.count > 0 || begin
      puts MSG[:no_items_to_display].orange
      return
    end

    # 
    # Filtrage de la liste (s'il le faut)
    # 
    disp_items = filter_items_of_list(@items, options)

    #
    # Procédure qui permet de récupérer la liste des données pour
    # l'affichage tabulaire des éléments
    # 
    header = []
    tableizable_props = []
    properties.each do |property|
      if property.tablizable?
        header << (property.short_name||property.name)
        tableizable_props << property
      end
    end

    tbl = Clir::Table.new(**{
      title:    "AFFICHAGE DES #{class_name}S",
      header:   header
    })
    disp_items.each do |item|
      tbl <<  tableizable_props.map do |property|
        property.formated_value_in(item) || '---'
      end
    end

    clear unless debug?
    tbl.display

  end

  ##
  # @return la liste des indexes des menus sélectionnés dans +cs+
  # Les sélectionnés sont définis par leur identifiant dans 
  # options[:default]
  # 
  def get_default_choices(cs, options)
    selecteds = options[:default]
    ids_sels = []
    cs.each_with_index do |dmenu, idx|
      ids_sels << (idx + 1) if selecteds.include?(dmenu[:value])
    end
    return ids_sels
  end

  def choose_precedence_set(id)
    precedence_ids.delete(id)
    precedence_ids.unshift(id)
    mkdir(tmp_folder)
    File.write(precedence_list, precedence_ids.join(' '))
  end

  def precedence_ids
    @precedence_ids ||= begin
      if File.exist?(precedence_list)
        File.read(precedence_list).split(' ').map(&:to_i)
      else [] end
    end
  end

  def precedence_list
    @precedence_list ||= File.join(tmp_folder, "#{classe.name.to_s.gsub(/::/,'_').downcase}.precedences")
  end

  def tmp_folder
    @tmp_folder ||= mkdir(File.join(APP_FOLDER,'tmp','precedences'))
  end

  ##
  # @return [Array] Liste des "choices" pour le select de Tty-prompt
  # pour choisir une instance de la classe.
  # Cette liste tient compte de la variable @@group_by de la classe,
  # qui détermine les regroupements de données à effectuer.
  # La méthode retour$ne aussi une liste avec ITEMS CLASSÉS PAR 
  # PRÉCÉDENCES si la liste de précédence existe.
  # Donc une liste :
  #   - items groupés par @@group_by
  #   - items classés par liste de précédence.
  # @note
  #   La liste de précédence se fiche de savoir s'il s'agit d'un
  #   item ou d'un groupement d'items 
  # 
  # Note : on va utiliser un autre system de classement, avec
  # sort et precedence_ids.index(<item id>)
  # La liste classée ser
  def get_choices_with_precedences(options)
    # 
    # La liste au départ
    # 
    list = @items

    # 
    # Filtrer la liste si nécessaire
    # 
    list = filter_items_of_list(list, options)

    #
    # Grouper les éléments si nécessaire
    # 
    list = group_items_of_list(list, options)

    # 
    # Quand on a la liste finale, on peut régler la précédence si
    # elle est définie
    # 
    if File.exist?(precedence_list)
      list.sort! do |a, b|
        (precedence_ids.index(a.id)||10000) <=> (precedence_ids.index(b.id)||10000)
      end
    end

    # 
    # On retourne des menus pour TTY-Prompt
    # 
    cs = list.map do |item|
      {name: tty_name_for(item, options), value: item}
    end + [CHOIX_RENONCER]
    cs.unshift(CHOIX_CREATE) if options[:create]

    return cs
  end

  # Filtre la liste +list+ avec le filtre +options[:filter]+ s'il
  # existe.
  # @return [Array] La liste des éléments filtrés
  def filter_items_of_list(list, options)
    return list unless options && options[:filter]
    # 
    # Duplication pour pouvoir le modifier
    # 
    option_filter = options[:filter].dup
    # 
    # Préparer éventuellement certaines valeurs du filtre
    # 
    option_filter.each do |k, v|
      case k
      when :periode
        #
        # Si une période est déterminée, il faut ajouter cette condition
        # au filtre.
        # 
        # L'idée c'est de déterminer que le temps de l'item doit être
        # supérieur ou égal au temps de départ de la période et doit
        # être inférieur ou égal au temps de fin de la période.
        # Le tout est de savoir quel temps prendre en compte. On 
        # cherche dans cet ordre
        #   :date, :created_at, :time
        # Pour le savoir on prend le premier élément, qui existe 
        # forcément.
        item1 = list.first
        time_prop = 
          if item1.respond_to?(:date)
            :date
          elsif item1.respond_to?(:created_at)
            :created_at
          elsif item1.respond_to?(:time)
            :time
          elsif not(time_property)
            time_property
          else
            raise ERRORS[:no_time_property] % ["#{classe.class}"]
          end
        # On prend la période en la retirant du filtre
        periode = options[:filter].delete(:periode)
        # Et on ajoute la condition sur le temps
        options[:filter].merge!( 
          time_prop => Proc.new { |inst| periode.time_in?(inst.send(time_prop) ) }
        )
      end #/case k
    end
    # 
    # Sélectionner les items valides
    # 
    list.select do |item|
      item_match_filter?(item, options[:filter])
    end
  end

  # Groupe les éléments dans la liste +list+ suivant la variable de
  # classe @@group_by ou +options[:group_by]+
  # 
  # @return [Array] La liste Tty-prompt avec les instances groupées
  # @note
  #   Cf. le manuel pour le détail de l'utilisation.
  # 
  def group_items_of_list(list, options = nil)
    return list if options[:group_by].nil? && items_grouped_by.nil?
    # 
    # La clé de groupement
    # 
    groupby = options[:group_by] || items_grouped_by
    # 
    # La clé de groupe fait-elle référence à une classe relative ?
    # 
    is_relative_class = groupby.to_s.match?(/_ids?$/)
    # 
    # Table des groupes initiés
    # 
    groups = {}
    # 
    # La liste finale qui contiendra les nouveaux éléments
    # 
    final_list = []
    # 
    # On boucle sur la liste en groupant
    # 
    list.each do |item|
      if (group_id = item.send(groupby))
        # 
        # Si ce groupe n'existe pas, on le crée
        # 
        unless groups.key?(group_id)
          # 
          # Le nom que prendra le groupe
          # 
          property = table_properties[groupby]
          nom = 
            if is_relative_class
              property.relative_class.get(group_id).name
            else
              property.name
            end
          group = GroupedItems.new(nom, group_id, [])
          groups.merge!(group_id => group)
          final_list << group
        end
        groups[group_id].items << item
      else
        # 
        # Si l'item ne répond pas à la propriété de classement, on
        # le met tel quel
        # 
        final_list << item
      end
    end
    # 
    # On retourne la liste finale
    # 
    return final_list
  end

  # @return [Boolean] True si l'instance +item+ correspond au filtre
  # +filter+
  # @param [Any] item Instance de classe quelconque (mais qui doit
  #                   répondre à toutes les clés du filtre)
  # @param [Hash] filter  Définition du filtre, avec en clé des 
  #                       méthode de l'item et en valeur les valeurs
  #                       attendues (comparées avec '!=').
  def item_match_filter?(item, filter)
    filter.each do |key, expected|
      case expected
      when Proc
        return false if not(expected.call(item))
      else
        return false if item.send(key) != expected
      end
    end
    return true
  end

  # @return le string à utiliser pour l'attribut :name de TTY prompt
  def tty_name_for(item, options)
    @tty_name_procedure ||= begin
      options ||= {}
      if options.key?(:name4tty) && options[:name4tty]
        #
        # Procédure à utiliser définie dans les options
        #
        case v = options[:name4tty]
        when Symbol then Proc.new { |inst| inst.send(options[:name4tty]) }
        when Proc   then Proc.new { |inst| options[:name4tty].call(inst) }
        end
      elsif item.respond_to?(:name4tty)
        # 
        # :name4tty Définie comme méthode d'intance
        # 
        case v = item.send(:name4tty)
        when Symbol then Proc.new { |inst| inst.send(inst.send(:name4tty)) }
        when String then Proc.new { |inst| inst.send(:name4tty) }
        end
      else
        #
        # Aucune définition => deuxième propriété
        # 
        prop = data_properties[1][:prop]
        Proc.new { |inst| inst.send(prop) }
      end
    end
    @tty_name_procedure.call(item)
  end

  ##
  # Méthode principale du manager, quand le :save_system est :file,
  # qui enregistre toutes les données
  # 
  def save_all
    case save_format
    when :yaml
      all_data = @items.map(&:data)
      File.write(save_location, all_data.to_yaml)
    when :csv
      CSV.open(save_location, 'wb') do |csv|
        @items.each do |item|
          csv << item.data
        end
      end
    end
  end

  def save_system
    classe.class_variable_get("@@save_system")
  end
  def save_location
    classe.class_variable_get("@@save_location")
  end
  def save_format
    classe.class_variable_get("@@save_format")
  end
  def items_grouped_by
    @items_grouped_by ||= begin
      if classe.class_variables.include?(:'@@group_by')
        classe.class_variable_get('@@group_by')
      end
    end
  end

  # 
  # Pour savoir si toutes les données sont chargées
  # 
  def full_loaded?
    @is_full_loaded === true
  end


  # --- Usefull Method for classes ---

  # Reçoit quelque chose comme 'edic_test_class' et retourne 
  # Edic::TestClass en mémorisant pour accélérer le processus
  # 
  def get_classe_from(class_min)
    return self.class.get_class_from_class_mmin(class_min)
  end
  def self.get_class_from_class_mmin(class_min)
    @@class4classMin ||= {}
    @@class4classMin[class_min] ||= begin
      dclass = class_min.split('_').map{|n|n.titleize}
      cc = Object # la classe courante en tant que classe
      ss = nil # le string courant en tan que classe en recherche
      while dclass.count > 0
        x = dclass.shift
        # puts "Étude de dclass.shift = #{x.inspect}"
        if cc.const_defined?(x)
          cc = cc.const_get(x) # => class
          x = nil
        elsif ss.nil?
          ss = x
        elsif ss != nil
          if cc.const_defined?(ss + x)
            cc = cc.const_get(ss + x)
            ss = nil
          else
            ss = ss + x # => "Data" + "Manager" => "DataManager"
            # Et on poursuit
          end
        end
      end
      cc = nil if cc == Object
      if cc.nil?
        raise ERRORS[:unable_to_get_class_from_class_min] % [class_min, "."]
      elsif not(x.nil?) || not(ss.nil?)
        raise ERRORS[:unable_to_get_class_from_class_min] % [class_min, " : #{MSG[:not_treated] % "#{x}#{ss}".inspect}."]
      end
      cc
    end
  end

  # Le nom simple de la classe propriétaire, sans module
  def class_name
    @class_name ||= classe.name.to_s.split('::').last
  end


  # --- Implementation Managed Class Methods ---


  def prepare_class_methods
    my = self
    classe.define_singleton_method 'data_manager' do
      return my
    end
    classe.define_singleton_method 'save_location' do
      return my.save_location
    end
    classe.define_singleton_method 'items' do |options = nil|
      my.load_data if not(my.full_loaded?)
      if options.nil?
        my.items
      else
        get(options)
      end
    end
    classe.define_singleton_method 'table' do
      my.full_loaded? || my.load_data
      my.instance_variable_get("@table")
    end
    classe.define_singleton_method 'get' do |item_id|
      data_manager.get(item_id)
    end
    classe.define_singleton_method 'class_name' do
      my.class_name
    end
    classe.define_singleton_method 'get_all' do |options = nil|
      my.load_data if not(my.full_loaded?)
      my.filter_items_of_list(my.items, options || {})
    end
    classe.define_singleton_method 'display' do |options = nil|
      my.display_items(options)
    end
    classe.define_singleton_method 'remove' do |instances, options = nil|
      my.remove(instances, options)
    end
    if classe.methods.include?(:choose)
      # Rien à faire
    else    
      classe.define_singleton_method 'choose' do |options = nil|
        return my.choose(options)
      end
    end
    unless classe.respond_to?(:feminine?)
      classe.define_singleton_method 'feminine?' do
        return false
      end
    end
  end

  # @return [Any] Any instance with ID +item_id+
  def get(item_id)
    item_id = item_id.to_i
    @table || load_data
    @table[item_id]
  end

  # Add instance methods to managed class (:create, :edit, :display
  # and :remove/:destroy)
  def prepare_instance_methods_of_class
    my = self
    classe.define_method 'initialize' do |data = {}|
      @data = data
    end
    classe.define_method 'create' do |options = {}|
      return my.create(self, options)
    end
    classe.define_method 'edit' do |options = {}|
      return my.edit(self, options)
    end
    classe.define_method 'display' do |options = {}|
      my.display(self, options)
    end
    classe.alias_method(:show, :display)
    classe.define_method 'remove' do |options = {}|
      my.remove(self, options)
    end
    classe.alias_method(:destroy, :remove)
    classe.define_method 'data' do
      return @data
    end
    classe.define_method 'data=' do |value|
      @data = value
    end

    # 
    # Quelques propriétés supplémentaires pour les instances
    # 
    classe.define_method "new?" do
      return @data[:is_new] === true
    end

    prepare_save_methods

    prepare_properties_methods

  end

  def prepare_save_methods
    my = self
    # 
    # Méthode de sauvegarde, en fonction du système de sauvegarde
    # choisi.
    # 
    case save_system
    when :card
      case save_format
      when :yaml
        classe.define_method "data_file" do
          @data_file ||= begin
            mkdir(my.save_location)
            File.join(my.save_location,"#{id}.yaml")
          end
        end
        classe.define_method "save" do
          if new?
            my.add(self) 
            @data.delete(:is_new)
          end
          File.write(data_file, data.to_yaml)
        end
      end
    when :file
      case save_format
      when :yaml
        classe.define_method "save" do
          load_data unless my.full_loaded?
          if new?
            my.add(self) 
            @data.delete(:is_new)
          end
          my.save_all
        end
      when :csv
        classe.define_method "save" do
          load_data unless my.full_loaded?
          if new?
            my.add(self)
            @data.delete(:is_new)
          end
          my.save_all
        end
      end
    when :conf
      raise "Je ne sais pas encore utiliser le système :conf de sauvegarde."
    end

  end

  def prepare_properties_methods
    #
    # Chaque propriété de DATA_PROPERTIES doit faire une méthode qui
    # permettra de récupérer et de définir la valeur
    #
    data_properties.each do |dproperty|
      prop = dproperty[:prop]
      classe.define_method "#{prop}" do
        return @data[prop]
      end
      classe.define_method "#{prop}=" do |value|
        @data.merge!( prop => value)
      end
      # 
      # Propriétés spéciales qui se terminent par _id et sont des
      # liens avec une autre classe (typiquement : user_id pour faire
      # référence à un user {User})
      # 
      if prop.to_s.match?(/_ids?$/)
        traite_property_as_other_class_instance(dproperty)
      end
    end

  end

  def traite_property_as_other_class_instance(dproperty)
    prop        = dproperty[:prop]
    last        = prop.end_with?('_ids') ? -5 : -4
    class_min   = prop[0..last]
    other_class = get_classe_from(class_min)
    # other_class.respond_to?(:choose) || begin
    #   raise "Impossible d'obtenir la classe relative #{class_min.inspect}. La classe calculée est #{other_class.name} qui ne répond pas à la méthode de classe :choose."
    # end
    # puts "other_classe avec #{class_min.inspect} : #{other_class}"
    # sleep 4
    dproperty.merge!(relative_class: other_class)
    # 
    # Les méthodes utiles pour la gestion de l'autre classe.
    # Note : une méthode différente suivant _id ou _ids
    # 
    case true
    when prop.end_with?('_ids')
      classe.define_method "#{class_min}" do # p.e. def vente;
        instance_variable_get("@#{class_min}") || begin
          items = self.send(prop).map do |item_id|
            other_class.get(item_id)
          end
          instance_variable_set("@#{class_min}", items)
        end
      end
    when prop.end_with?('_id')
      classe.define_method "#{class_min}" do # p.e. def user; ... end
        if instance_variables.include?("@#{class_min}".to_sym)
          instance_variable_get("@#{class_min}")
        else
          item = other_class.get(self.send(prop))
          instance_variable_set("@#{class_min}", item)
        end
      end
      classe.define_method "#{class_min}=" do |owner| # p.e. user=
        self.send("#{prop}=".to_sym, owner.id)
      end
    end
  end

  # To create a instance
  def create(instance, options = nil)
    data = instance.before_create if instance.respond_to?(:before_create)
    instance.data = data || {id: __new_id}
    instance.data.merge!(is_new: true)
    edit(instance, options)
    if not(instance.new?) # => bien créé
      key = classe.feminine? ? :item_created_fem : :item_created
      puts (MSG[key] % {element:  class_name}).vert
      instance.after_create if instance.respond_to?(:after_create)
    end
    return instance # chainage
  end

  def edit(instance, options = nil)
    @editor ||= Editor.new(self)
    is_new_item = instance.data[:is_new]
    instance.before_edit if instance.respond_to?(:before_edit)
    @editor.edit(instance, options)
    instance.after_edit if instance.respond_to?(:after_edit)
    unless is_new_item
      key = classe.feminine? ? :item_updated_fem : :item_updated
      puts (MSG[key] % [class_name, instance.id]).vert
    end
    return instance # chainage
  end

  def display(instance, options = nil)
    @displayer ||= Displayer.new(self)
    options = instance.before_display(options) if instance.respond_to?(:before_display)
    @displayer.show(instance, options)
    instance.after_display if instance.respond_to?(:after_display)
    return instance # chainage
  end

  # @note
  #   Cette méthode est testée dans remove_test.rb
  # 
  def remove(instances, options = nil)
    has_method_before = instances.first.respond_to?(:before_remove)
    has_method_after  = instances.first.respond_to?(:after_remove)
    # 
    # Tout charger si ça n'est pas encore fait
    full_loaded? || load_data 
    # 
    # Pour conserver les IDs supprimés et les supprimer plus
    # rapidement de @items
    # 
    table_removed_ids = {}
    # 
    # Boucle sur toutes les instances à détruire
    # 
    instances.each do |instance|
      # Méthode avant ?
      instance.send(:before_remove) if has_method_before
      # 
      # Si les instancences sont sauvées dans des cartes, il faut les
      # détruire
      # 
      if save_system == :card
        File.delete(instance.data_file) if File.exist?(instance.data_file)
      end
      # 
      # Pour pouvoir retirer l'instance de @items
      # 
      table_removed_ids.merge!(instance.id => true)
      # 
      # Retirer l'instance de @table
      # 
      @table.delete(instance.id)
      # 
      # Faut-il appeler une méthode après la destruction ?
      # 
      instance.send(:after_remove) if has_method_after
    end #/fin boucle sur les instances à détruire
    # 
    # On retire ces items de @items
    # 
    @items.reject! { |item| table_removed_ids[item.id] }
    #
    # Si les données sont enregistrées dans un fichier, on les 
    # sauve maintenant
    # 
    save_all if save_system == :file

    return true
  end

  # Loop on every property (as instances)
  def each_property(&block)
    if block_given?
      properties.each do |property|
        yield property
      end
    end
  end

  # @return [Array<Property>] All data properties as instance
  # @note
  #   Also product @table_properties, a table with key = :prop and
  #   value is instance DataManager::Property
  # 
  def properties
    @properties ||= begin
      data_properties.map.with_index do |dproperty, idx|
        dproperty.merge!(index: idx)
        Property.new(self, dproperty)
      end
    end
  end

  # @return [Hash] Table of properties. Key is property@prop, value
  # is DataManager::Property instance.
  def table_properties
    @table_properties ||= begin
      tbl = {}; properties.each do |property|
        tbl.merge!(property.prop => property)
      end; tbl
    end
  end

  # @prop Pour valider les nouvelles données
  def validator
    @validator ||= Validator.new(self)
  end


  # --- Data Methods ---

  def load_data
    @table    = {}
    @items    = []
    @last_id  = 0
    case save_system
    when :card
      load_data_from_cards
    when :file
      load_data_from_uniq_file
    end.each do |ditem|
      inst = classe.new(ditem)
      @table.merge!(inst.id => inst)
      @items << inst
      @last_id = 0 + inst.id if inst.id > @last_id
    end
    @is_full_loaded = true
  end

  def load_data_from_uniq_file
    if File.exist?(save_location)
      case save_format
      when :yaml
        YAML.load_file(save_location, {aliases:true, symbolize_names: true})
      when :csv
        CSV.read(save_location)
      end  
    else
      []
    end
  end
  def load_data_from_cards
    Dir["#{save_location}/*.#{save_format}"].map do |pth|
      case save_format
      when :yaml
        YAML.load_file(pth, **{aliases:true, symbolize_names: true})
      else
        raise "Format de fiche inconnue : #{save_format}"
      end
    end
  end

  # --- Path Methods ---

  def last_id_path
    @last_id_path ||= begin
      File.join(mkdir(save_location),"LASTID")
    end
  end
end #/class Manager
end #/module DataManager
end #/module Clir
