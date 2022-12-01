module Clir
module PropManager
class << self
  def new(classe, data_properties = nil)
    Manager.new(classe, data_properties)
  end
end #/<< self module

class Manager
  
  attr_reader :classe
  attr_reader :data_properties
  
  def initialize(classe, data_properties = nil)
    @data_properties = data_properties || begin
      defined?(classe::DATA_PROPERTIES) || raise(ERRORS[:require_data_properties] % classe.name)
      classe::DATA_PROPERTIES
    end
    @classe = classe
    prepare_instance_methods_of_class
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

    # Chaque propriété de DATA_PROPERTIES doit faire une méthode qui
    # permettra de récupérer et de définir la valeur
    data_properties.each do |dproperty|
      prop = dproperty[:prop]
      classe.define_method "#{prop}" do
        return @data[prop]
      end
      classe.define_method "#{prop}=" do |value|
        @data.merge!( prop => value)
      end
    end
  end


  # To create a instance
  def create(instance, options = nil)
    edit(instance, options)
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

  def save(instance, options = nil)
    puts "Je dois apprendre à sauver l'instance #{instance.inspect}".jaune
  end

  # Loop on every property (as instances)
  def each_property(&block)
    if block_given?
      properties.each do |property|
        yield property
      end
    end
  end

  # @prop All data properties as instance of {PropManager::Property}
  def properties
    @properties ||= begin
      data_properties.map do |dproperty|
        Property.new(self, dproperty)
      end
    end
  end

  # @prop Pour valider les nouvelles données
  def validator
    @validator ||= Validator.new(self)
  end

end #/class Manager
end #/module PropManager
end #/module Clir
