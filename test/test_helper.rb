$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "clir/prop_manager"

require "minitest/autorun"
require 'minitest/reporters'

reporter_options = { 
  color: true,          # pour utiliser les couleurs
  slow_threshold: true, # pour signaler les tests trop longs
}
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

#
# Une classe utilisable quand elle importe peu
# (par exemple test des propriétés)
class MaClasseLambda
  DATA_PROPERTIES = []
end
