class MaClasseIns
  include ClirDataManagerConstants
  def self.pmanager
    @@pmanager ||= Clir::DataManager.new(self)
  end
  DATA_PROPERTIES = [
    {prop: :id      , id:   'ID'    , type: :number   , specs:REQUIRED  },
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
  def id      ; data[:id]       end
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
