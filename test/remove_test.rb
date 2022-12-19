require 'test_helper'
require 'fixtures/classe_with_card'

class RemoveMethodTestor < Minitest::Test

  def setup
    super
  end
  def teardown
    super
  end


  def test_remove_exist
    assert_respond_to MyClassWithCard, :remove
  end

  def test_remove_raises_without_arguments
    assert_raises(ArgumentError) { MyClassWithCard.remove }
  end

  def test_remove_method_remove_instances
    # 
    # On fait quelques données
    # 
    MyClassWithCard.reset
    instances = MyClassWithCard.make_data(10)
    assert_equal 10, instances.count, "Il devrait y avoir 10 données, il y en a #{instances.count}."

    #
    # On s'assure qu'il y a bien 10 cartes
    # 
    expected = 10
    actual   = Dir["#{MyClassWithCard.save_location}/*.yaml"].count
    assert_equal expected, actual, "Il devrait y avoir #{expected} cartes dans le dossier. Je en trouve #{actual}…"
    actual = MyClassWithCard.items.count
    assert_equal expected, actual, "Il devrait y avoir 10 éléments dans @items, il y en a #{actual}"
    actual = MyClassWithCard.table.count
    assert_equal expected, actual, "Il devrait y avoir 10 éléments dans @table, il y en a #{actual}"
    
    # 
    # On va détruire les cartes 3, 5, 1 et 8
    # 
    rem_instances = [3,5,1,8].map { |i| MyClassWithCard.table[i] }

    # ====> Opération <====
    assert_silent { MyClassWithCard.remove(rem_instances) }

    #
    # On s'assure qu'il ne reste plus que 6 instances
    # 
    expected = 6
    actual   = Dir["#{MyClassWithCard.save_location}/*.yaml"].count
    assert_equal expected, actual, "Il devrait y avoir #{expected} cartes dans le dossier. Je en trouve #{actual}…"
    actual = MyClassWithCard.items.count
    assert_equal expected, actual, "Il devrait y avoir 10 éléments dans @items, il y en a #{actual}"
    actual = MyClassWithCard.table.count
    assert_equal expected, actual, "Il devrait y avoir 10 éléments dans @table, il y en a #{actual}"

    # 
    # Pour être tout à fait précis, on s'assure que ce sont les
    # bonnes instances qui restent
    # 
    ids_in_items = {}
    MyClassWithCard.items.each { |item| ids_in_items.merge!(item.id => true) }
    [2,4,6,7,9,10].each do |good_id|
      pth = File.join(MyClassWithCard.save_location, "#{good_id}.yaml")
      assert File.exist?(pth), "Le fichier #{pth.inspect} devrait exister…"
      assert MyClassWithCard.table[good_id], "L'instance ##{good_id} devrait exister dans @table"
      assert ids_in_items.key?(good_id), "L'instance ##{good_id} devrait exister dans @items"
    end
  end

end #/ class RemoveMethodTestor
