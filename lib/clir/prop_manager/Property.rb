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
  def format_method; @format_method ||= data[:mformate] end

end #/class Property
end #/module PropManager
end #/module Clir
