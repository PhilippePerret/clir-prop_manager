require "test_helper"

class Clir::DataManagerPropertyTest < Minitest::Test

  def manager
    @manager ||= Clir::DataManager.new(MaClasseLambda)
  end
  def init_property_with(data)
    man = data.delete(:manager) || manager
    Clir::DataManager::Property.new(man, data)
  end

  def test_constants_are_defined
    assert_equal 1, Clir::DataManager::REQUIRED
    assert_equal 2, Clir::DataManager::DISPLAYABLE
    assert_equal 4, Clir::DataManager::EDITABLE
    assert_equal 8, Clir::DataManager::REMOVABLE
  end

  def test_property_responds_to_predicate_methods
    iprop     = init_property_with({specs: 1|2|4|8})
    iprop_no  = init_property_with({specs: 0})
    inst      = MaClasseLambda.new

    assert iprop.required?(inst), 'Property should be required'
    assert iprop_no.required?(inst), 'Property shouldn’t be required'

    assert iprop.displayable?(inst), "Property should be displayable"
    refute iprop_no.displayable?(inst), "Property shouldn't be displayable"

    assert iprop.editable?(inst), "Property should be editable"
    refute iprop_no.editable?(inst), "Property shouldn't be editable"

    assert iprop.removable?(inst), "Property should be removable"
    refute iprop_no.removable?(inst), "Property shouldn't be removable"

  end


end
