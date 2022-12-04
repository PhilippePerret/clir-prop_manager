require 'test_helper'

class MaClassePourGetMin
end
# modulee_get_min_ma_classe_in
module ModuleeGetMin
  class MaClasseIn
    def self.what; "Bonjour" end
  end
end

class GetClassFromMinClassTest < Minitest::Test

  def getc(minclass)
    Clir::DataManager::Manager.get_class_from_class_mmin(minclass)
  end

  def test_get_class_with_unknown_class
    refute getc('rien')
  end
  def test_get_class_with_simple_class
    refute getc('ma_classe_pour_get_mi')
    cls = getc('ma_classe_pour_get_min')
    assert cls
    assert_equal( 'Class', cls.class.to_s)
  end

  def test_get_class_with_classe_in_module
    str = "modulee_get_min_ma_classe_in"
    cls =  getc(str)
    assert cls
    assert_equal 'Class', cls.class.to_s
    assert_equal 'Bonjour', cls.what
  end

end
