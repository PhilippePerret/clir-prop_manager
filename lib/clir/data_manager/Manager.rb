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
    # donnée.
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
        @last_id || load_data
      when :conf
        puts "Je ne sais pas encore gérer le système de sauvegarde :conf.".orange
        raise(ExitSilently)
      end
      1
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

  def prepare_class_methods
    my = self
    classe.define_singleton_method 'data_manager' do
      return my
    end
    classe.define_singleton_method 'save_location' do
      return my.save_location
    end
    class.define_singleton_method 'choose' do |options = nil|
      return my.choose(options)
    end
  end

  # Add instance methods to managed class (:create, :edit, :display
  # and :remove/:destroy)
  def prepare_instance_methods_of_class
    my = self
    classe.define_method 'create' do |options = {}|
      my.create(self, options)
    end
    classe.define_method 'edit' do |options = {}|
      my.edit(self, options)
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
      classe.define_method "full_loaded?" do
        @is_full_loaded === true
      end
      case save_format
      when :yaml
        classe.define_method "save" do
          load_all unless full_loaded?
          if new?
            my.add(self) 
            @data.delete(:is_new)
          end
          my.save_all
        end
      when :csv
        classe.define_method "save" do
          load_all unless full_loaded?
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
    end

    # 
    # Quelques propriétés supplémentaires pour les instances
    # 
    classe.define_method "new?" do
      return @data[:is_new] === true
    end

  end

  # Le nom simple de la classe propriétaire, sans module
  def class_name
    @class_name ||= classe.name.to_s.split('::').last.downcase
  end


  # To create a instance
  def create(instance, options = nil)
    instance.data = {id: __new_id, is_new: true}
    edit(instance, options)
    if not(instance.new?)
      puts (MSG[:item_created] % {element:  class_name}).vert
    end
  end

  def edit(instance, options = nil)
    @editor ||= Editor.new(self)
    @editor.edit(instance, options)
  end

  def display(instance, options = nil)
    @displayer ||= Displayer.new(self)
    @displayer.show(instance, options)
  end

  def remove(instance, options = nil)
    puts "Je dois apprendre à détruire l'instance #{instance.inspect}.".jaune
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
    @table = {}
    @items = []
    case save_system
    when :card
      load_data_from_cards
    when :file
      load_data_from_uniq_file
    end.each do |ditem|
      inst = classe.new(ditem)
      @table.merge!(inst.id => inst)
      @items << inst
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
