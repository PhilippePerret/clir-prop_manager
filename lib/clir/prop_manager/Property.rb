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

  def name;   @name   ||= data[:name]   end
  def specs;  @specs  ||= data[:specs]  end
  def prop;   @prop   ||= data[:prop]   end
  def type;   @type   ||= data[:type]   end
  def format_method; @format_method ||= data[:mformate] end

end #/class Property
end #/module PropManager
end #/module Clir
