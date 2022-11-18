=begin
  Clir::PropManager::Manager::Validator
  -------------------------------------
  To invalidate instance values

=end
module Clir
module PropManager
class Manager
class Validator

  attr_reader :manager
  
  def initialize(manager)
    @manager = manager    
  end

  # - main method -
  # 
  def valid?(property)
    puts "Je dois apprendre à valider la propriété #{property.inspect}.".jaune
  end

end #/class Validator
end #/class Manager
end #/module PropManager
end #/module Clir
