require "test_helper"

class MaClasse
  def self.pmanager
    @@pmanager ||= Clir::PropManager.new(self)
  end
  DATA_PROPERTIES = [

  ]
end

class Clir::PropManagerTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::Clir::PropManager::VERSION
  end

  def test_it_add_instance_methods
    man = MaClasse.pmanager
    assert_instance_of Clir::PropManager::Manager, man
    inst = MaClasse.new
    assert_respond_to inst, :create
    assert_respond_to inst, :edit
    assert_respond_to inst, :display
    assert_respond_to inst, :show # alias
    assert_respond_to inst, :remove
    assert_respond_to inst, :destroy # alias
  end

end
