require "test_helper"

require_relative 'requirements/ma_classe_ins'


class Clir::PropManagerTest < Minitest::Test


  def test_instance_displayed
    "
    Ce test s'assure que la méthode #display de l'instance affiche
    correctement les valeurs, en utilisant les méthodes de formatage
    adéquate, à savoir :
    - la méthode par défaut (f_<prop>)
    - la méthode fournie par mformate dans les données
    Il s'assure également que seules les propriétés à afficher sont
    bien affichées (et qu'elles le soient toutes.
    "
    MaClasseIns.pmanager
    inst = MaClasseIns.new({name:"Marion MICHEL", age: 29, sexe: 'F'})
    res = epure(capture_io { inst.display })
    # puts "res = #{res.inspect}"
    assert_match(/Nom\s+Madame Marion MICHEL/, res)
    assert_match(/Âge\s+29 ans/, res)
    assert_match(/Sexe\s+Femme/, res)
    refute_match(/Secret/, res)
  end

end
