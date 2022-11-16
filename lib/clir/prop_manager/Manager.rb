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
    classe.define_method 'create' do
      my.create(self)
    end
    classe.define_method 'edit' do
      my.edit(self)
    end
    classe.define_method 'display' do
      my.display(self)
    end
    classe.alias_method(:show, :display)
    classe.define_method 'remove' do
      my.remove(self)
    end
    classe.alias_method(:destroy, :remove)
  end

  # To create a instance
  def create(instance)
    puts "Je dois apprendre à créer l'instance #{instance.inspect}".jaune
  end

  def edit(instance)
    puts "Je dois apprendre à éditer l'instance #{instance.inspect}.".jaune
  end

  def display(instance)
    puts "Je dois apprendre à afficher l'instance #{instance.inspect}.".jaune
  end

  def remove(instance)
    puts "Je dois apprendre à détruire l'instance #{instance.inspect}.".jaune
  end

end #/class Manager

end #/module PropManager
end #/module Clir
