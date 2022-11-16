require "test_helper"

class Clir::PropManagerPropertyTest < Minitest::Test

  def manager
    @manager ||= Clir::PropManager.new(MaClasseLambda)
  end
  def init_property_with(data)
    man = data.delete(:manager) || manager
    Clir::PropManager::Property.new(man, data)
  end

  def test_constants_are_defined
    assert_equal 1, Clir::PropManager::REQUIRED
    assert_equal 2, Clir::PropManager::DISPLAYABLE
    assert_equal 4, Clir::PropManager::EDITABLE
    assert_equal 8, Clir::PropManager::REMOVABLE
  end

  def test_property_responds_to_predicate_methods
    iprop = init_property_with({specs: 1|2|4|8})
    iprop_no = init_property_with({specs: 0})

    assert_predicate iprop, :required?, 'Property should be required'
    refute_predicate iprop_no, :required?, 'Property shouldn’t be required'

    assert iprop.displayable?, "Property should be displayable"
    refute iprop_no.displayable?, "Property shouldn't be displayable"

    assert iprop.editable?, "Property should be editable"
    refute iprop_no.editable?, "Property shouldn't be editable"

    assert iprop.removable?, "Property should be removable"
    refute iprop_no.removable?, "Property shouldn't be removable"

  end


end
