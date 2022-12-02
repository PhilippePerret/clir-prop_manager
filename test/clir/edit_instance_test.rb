require "test_helper"

require_relative 'requirements/ma_classe_ins'


class Clir::EditInstanceTest < Minitest::Test


  def test_instance_editing
    "
    Ce test s'assure qu'on peut éditer une instance pour définir
    ses valeurs.
    "
    MaClasseIns.pmanager
    inst = MaClasseIns.new({id:12, name:"Marion MICHEL", age: 29, sexe: 'F'})
    res = epure(capture_io { inst.edit })
    # puts "res = #{res.inspect}"
    assert_match(/Enregistrer/, res)
    assert_match(/Nom\s+Madame Marion MICHEL/, res)
    assert_match(/Âge\s+29 ans/, res)
    assert_match(/Sexe\s+Femme/, res)
    refute_match(/Secret/, res)
  end



  def test_input_transform

    resume "
    Ce test s'assure que la propriété :itransform fait son
    travail dans les différentes situations.
    "

    synopsis "
    On fait la vérification avec :
    - :itransform {Proc} (qui doit recevoir en argument, dans
      l'ordre, l'instance puis la nouvelle valeur)
    - :itransform {Symbol} qui répond à la valeur (par exemple
      :upcase)
    - :itransfom {Symbol} qui répond à l'instance (i.e. méthode de
      l'instance)
    "
    
  end
end
