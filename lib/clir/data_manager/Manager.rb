module Clir
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
      id = File.read(last_id_path).strip.to_i + 1
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
  
  def initialize(classe, data_properties = nil)
    @data_properties = data_properties || begin
      defined?(classe::DATA_PROPERTIES) || raise(ERRORS[:require_data_properties] % classe.name)
      classe::DATA_PROPERTIES
    end
    @classe = classe
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
  # @param options {Hash}
  #   :question   La question à poser ("Choisir" par défaut)
  #   :multi      Si true, on peut choisir plusieurs éléments
  #   :create     Si true, on peut créer un nouvel élément
  #   :filter     Filtre à appliquer aux valeurs à afficher
  #               Avec le filtre, les instances n'apparaitront pas
  #               à l'écran, contrairement à :exclude.
  #   :exclude    Liste d'identifiants qu'ils faut rendre "inchoisis-
  #               sables".
  #   :default    Quand :multi, les valeurs à sélectionner par défaut
  #               C'est une liste d'identifiants.
  # 
  def choose(options = nil)
    # 
    # Définition des options
    # 
    options ||= {}
    options.key?(:multi) || options.merge!(multi: false)
    options[:question]   ||= "Choisir"
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
      choixs.each { |choix| choix && choose_precedence_set(choix.id) }
      # 
      # Instances retournées
      # 
      choixs
    else
      choix = Q.select(options[:question], cs, {per_page: 20, filter:true})
      choix = classe.new.create if choix == :create
      choix || return # cancel
      choose_precedence_set(choix.id)
      choix
    end
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
  # Retourne une liste avec les items classés par précédences si la
  # liste de précédence existe.
  # 
  def get_choices_with_precedences(options)
    list = nil
    if File.exist?(precedence_list)
      # puts "Le fichier #{precedence_list.inspect} existe".bleu
      # sleep 10
      all_ids = @table.keys.join(',').split(',').map(&:to_i)
      list = precedence_ids.map do |n| 
        all_ids.delete(n)
        classe.get(n) # peut être nil, si destruction
      end.compact
      # On ajoute ceux qui n'ont jamais été choisis en précédence
      all_ids.each { |nid| list << @table[nid] }
    else
      list = @items
    end
    # 
    # Filtrer la liste si nécessaire
    # 
    if options[:filter]
      list = list.select do |item|
        item_match_filter?(item, options[:filter])
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

  def item_match_filter?(item, filter)
    filter.each do |key, expected|
      return false if item.send(key) != expected
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
    classe.define_singleton_method 'get' do |item_id|
      data_manager.get(item_id)
    end
    classe.define_singleton_method 'class_name' do
      my.class_name
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
          @data_file ||= File.join(my.save_location,"#{id}.yaml")
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
        instance_variable_get("@#{class_min}") || begin
          item = other_class.get(self.send(prop))
          # puts "Je dois obtenir le #{prop.inspect} ##{self.send(prop).inspect}".jaune
          # puts "Dans la classe #{other_class.name}".jaune
          # puts "item = #{item.inspect}".jaune
          # sleep 5
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
    instance.data = data || {id: __new_id, is_new: true}
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
    instance.before_edit if instance.respond_to?(:before_edit)
    @editor.edit(instance, options)
    instance.after_edit if instance_respond_to?(:after_edit)
    return instance # chainage
  end

  def display(instance, options = nil)
    @displayer ||= Displayer.new(self)
    options = instance.before_display(options) if instance.respond_to?(:before_display)
    @displayer.show(instance, options)
    instance.after_display if instance.respond_to?(:after_display)
    return instance # chainage
  end

  def remove(instance, options = nil)
    instance.before_remove if instance.respond_to?(:before_remove)
    puts "Je dois apprendre à détruire l'instance #{instance.inspect}.".jaune
    instance.after_remove if instance.respond_to?(:after_remove)
  end

  # Loop on every property (as instances)
  def each_property(&block)
    if block_given?
      properties.each do |property|
        yield property
      end
    end
  end

  # @prop All data properties as instance of {DataManager::Property}
  def properties
    @properties ||= begin
      data_properties.map.with_index do |dproperty, idx|
        dproperty.merge!(index: idx)
        Property.new(self, dproperty)
      end
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
        YAML.load_file(pth, {aliases:true, symbolize_names: true})
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
