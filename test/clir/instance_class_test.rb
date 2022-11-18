require "test_helper"

class MaClasseIns
  include ClirPropManagerConstants
  def self.pmanager
    @@pmanager ||= Clir::PropManager.new(self)
  end
  DATA_PROPERTIES = [
    {prop: :name    , name: "Nom"   , type: :string   , specs:EDITABLE|DISPLAYABLE|REQUIRED, mformate: :formatage_nom},
    {prop: :age     , name: "Âge"   , type: :integer  , specs:EDITABLE|DISPLAYABLE},
    {prop: :secret  , name: "Code"  , type: :string   , specs:REQUIRED},
    {prop: :sexe    , name: "Sexe"  , type: :string   , specs:ALL_SPECS}
  ]
  attr_reader :data
  def initialize(data = nil)
    @data = data || {}
  end
  # - Data Methods -
  def name    ; data[:name]     end
  def age     ; data[:age]      end
  def sexe    ; data[:sexe]     end
  def secret  ; data[:secret]   end
  # - Helpers Methods -
  def formatage_nom
    "#{femme? ? 'Madame' : 'Monsieur'} #{name}"
  end
  def f_age; "#{age} ans" end
  def f_sexe
    sexe == 'F' ? 'Femme' : 'Homme'
  end
  # - Volatile Properties -
  def femme?; @isfemme ||= sexe == 'F' end
end

class Clir::PropManagerTest < Minitest::Test


  def test_instance_displayed
    # Ce test s'assure que la méthode #display de l'instance affiche
    # correctement les valeurs, en utilisant les méthodes de 
    # formatage adéquate, à savoir :
    #   - la méthode de formatage par défaut (f_<prop>)
    #   - la méthode de formatage donnée par un nom
    # Il s'assure aussi que seules les propriétés à afficher sont
    # bien affichées
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
