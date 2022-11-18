=begin
  Clir::PropManager::Manager::Editor
  -------------------------------------
  To edit a instance values

=end
module Clir
module PropManager
class Manager
class Editor

  attr_reader :manager
  
  def initialize(manager)
    @manager = manager    
  end

  def edit(instance, options)
    puts "Je dois apprendre à éditer l'instance #{instance.inspect} avec les options #{options.inspect}.".jaune    
  end

end #/class Editor
end #/class Manager
end #/module PropManager
end #/module Clir
