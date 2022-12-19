class MyClassWithCard
  include ClirDataManagerConstants
  DATA_PROPERTIES = [
    {prop: :id    , name: 'ID'    , specs: ALL},
    {prop: :name  , name: 'Nom'   , specs: ALL},
    {prop: :date  , name: 'Date'  , specs: ALL},
  ]

  @@save_system   = :card
  @@save_location = File.join(__dir__,'tmp','classe_with_card') 
  @@save_format   = :yaml

end
Clir::DataManager.new(MyClassWithCard)

#
# Pour les tests (fixtures)
class MyClassWithCard
  def self.reset
    save_location.length > 20 || raise("Pas bon du tout : #{save_location}")
    FileUtils.rm_rf(save_location)
  end
  def self.make_data(nombre)
    instances = []
    nombre.times.each do |i|
      d = {is_new: true, name: "Le nom ##{i}", date: Time.new(2000 + rand(22), 1 + rand(12), 1 + rand(28)).jj_mm_aaaa }
      instance = new(d)
      instance.save
      instances << instance
    end

    return instances
  end
end
