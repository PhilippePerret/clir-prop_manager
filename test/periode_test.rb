require 'test_helper'

class PeriodeTesteur < Minitest::Test

  def setup
    super
  end

  def teardown
    super
  end


  def test_initialisation
    [
      # Initialiser avec des strings français
      ["01/01/2000", "03/01/2001", "1er janvier 2000 au 3 janvier 2001"],
      # Initialiser avec des strings à l'envers
      ["2012/05/26","2015/8/3", "26 mai 2012 au 3 aout 2015"],
      # Initialiser avec des Times et des Dates
      [Time.new(2001,2,12), Date.new(2001,5,13), '12 février au 13 mai 2001'],
    ].each do |d1,d2,expected|
      per = Periode.new(d1,d2)
      assert(per.is_a?(Periode))
      actual = per.human_period
      assert_equal(expected, actual, "C'est bien une période")
    end
  end

  def test_human_periode_jours
    [
      # Une année
      ["10/01/2000", "01/01/2001", "du 10 janvier 2000 au 1er janvier 2001"],
      # Un trimestre
      ["01/01/2001", "01/04/2001", "du 1er janvier au 1er avril 2001"],
      # Un mois
      ["01/05/2001", "01/06/2001", "du 1er mai au 1er juin 2001"],
      # Une semaine
      ["14/06/2021", "21/06/2021", "du 14 juin au 21 juin 2021"],  
    ].each do |d1,d2,expected|
      per = Periode.new(d1,d2)
      assert(per.is_a?(Periode))
      # actual = per.human_period_jours
      actual = per.du_au
      assert_equal(expected, actual, "C'est bien une période")
    end
  end

  def test_human_periode_annee
    d1 = Time.new(2021,1,1)
    d2 = Time.new(2022,1,1)
    per = Periode.new(d1,d2)
    assert_equal("Année 2021", per.human_period, "La méthode :human_period retourne la bonne valeur")

    d1 = Time.new(2021,1,1)
    d2 = Time.new(2021,12,31)
    per = Periode.new(d1,d2)
    refute_equal("Année 2021", per.human_period, "La méthode :human_period retourne la bonne valeur")

    d1 = Time.new(2021,1,1)
    d2 = Time.new(2021,12,31,23,59,59)
    per = Periode.new(d1,d2)
    assert_equal("Année 2021", per.human_period, "La méthode :human_period retourne la bonne valeur")

    d1 = Time.new(2021,1,1)
    d2 = Time.new(2022,2,1)
    per = Periode.new(d1,d2)
    refute_equal("Année 2021", per.human_period, "La méthode :human_period retourne la bonne valeur")

    d1 = Time.new(2021,1,2)
    d2 = Time.new(2022,1,1)
    per = Periode.new(d1,d2)
    refute_equal("Année 2021", per.human_period, "La méthode :human_period retourne la bonne valeur")
  end

  def test_periode_trimestre
    [
      ["01/01/2019", "01/04/2019"],
      ["01/01/2019", Time.new(2019,03,31,23,59,30)]
    ].each do |d1, d2|
      per = Periode.new(d1,d2)
      assert_equal('1er trimestre 2019', per.human_period, "La méthode :human_period retourne la bonne valeur de trimestre")
    end

    [
      ["02/01/2019", "01/04/2019"],
      ["01/01/2019", Time.new(2019,03,31)],
      ["01/01/2019", "01/04/2020"]
    ].each do |d1,d2|
      per = Periode.new(d1,d2)
      refute_equal('1er trimestre 2019', per.human_period, "La méthode :human_period retourne la bonne valeur de trimestre")
    end

    # - 2e trimestre -

    [
      ["01/04/2018", "01/07/2018"],
      ["01/04/2018", Time.new(2018,06,30,23,59,30)]
    ].each do |d1, d2|
      per = Periode.new(d1,d2)
      assert_equal('2e trimestre 2018', per.human_period, "La méthode :human_period retourne la bonne valeur de trimestre")
    end

    # - 3e trimestre -

    [
      ["01/07/2017", "01/10/2017"],
      ["01/07/2017", Time.new(2017,9,30,23,59,30)]
    ].each do |d1, d2|
      per = Periode.new(d1,d2)
      assert_equal('3e trimestre 2017', per.human_period, "La méthode :human_period retourne la bonne valeur de trimestre")
    end

    # - 4e trimestre -

    [
      ["01/10/2016", "01/01/2017"],
      ["01/10/2016", Time.new(2016,12,31,23,59,30)]
    ].each do |d1, d2|
      per = Periode.new(d1,d2)
      assert_equal('4e trimestre 2016', per.human_period, "La méthode :human_period retourne la bonne valeur de trimestre")
    end
  end

  def test_periode_mois
    [
      ["01/01/1000","01/02/1000", "mois de janvier 1000", true],
      ["01/01/1001", lastDay(1,1001), "mois de janvier 1001", true],
      ["01/02/2000","01/03/2000", "mois de février 2000", true],
      ["01/02/2001", lastDay(2,2001), "mois de février 2001", true],
      ["01/03/2002","01/04/2002", "mois de mars 2002", true],
      ["01/03/2002", lastDay(3,2002), "mois de mars 2002", true],
      ["01/04/2002","01/05/2002", "mois d’avril 2002", true],
      ["01/04/2002", lastDay(4,2002), "mois d’avril 2002", true],
      ["01/07/2002","01/08/2002", "mois de juillet 2002", true],
      ["01/08/2002", lastDay(8,2002), "mois d’aout 2002", true],
      ["01/09/2003","01/10/2003", "mois de septembre 2003", true],
      ["01/10/2003", lastDay(10,2003), "mois d’octobre 2003", true],
      ["01/11/2004","01/12/2004", "mois de novembre 2004", true],
      ["01/12/2004", lastDay(12,2004), "mois de décembre 2004", true],
      # = échouent =
      ["02/01/2000","01/02/2000", "mois de janvier 2000", false],
    ].each do |d1,d2,expected, oui|
      per = Periode.new(d1,d2)
      methode = oui ? :assert_equal : :refute_equal
      send(methode, expected, per.human_period, "la méthode :human_period doit retourner #{expected.inspect}")
    end
  end

  def test_periode_semaine
    [
      ["14/06/2021", "21/06/2021", "semaine 24 de l’année 2021", true],  
      ["14/06/2021", Time.new(2021,6,20,23,59,59), "semaine 24 de l’année 2021", true],  
      ["15/06/2021", "21/06/2021", "semaine 24 de l’année 2021", false],
      ["15/06/2021", Time.new(2021,6,20,23,59,59), "semaine 24 de l’année 2021", false],  
    ].each do |d1,d2,expected, oui|
      per = Periode.new(d1,d2)
      methode = oui ? :assert_equal : :refute_equal
      send(methode, expected, per.human_period, "la méthode :human_period doit retourner #{expected.inspect}")
    end
  end

  def test_annee
    per = Periode.new(now, now.to_date >> 3)
    assert_equal(per.human_year, now.year, "La méthode :human_year retourne la bonne valeur")
  end


  def test_time_in_predicate
    periode = Periode.new("14/12/2022", "21/12/2022")
    dedans  = Time.new(2022, 12, 17)
    assert periode.time_in?(dedans)
    aubord = Time.new(2022,12,14)
    assert periode.time_in?(aubord)
    aubord = Time.new(2022,12,21)
    assert periode.time_in?(aubord)
    hors   = Time.new(2022, 12, 22)
    refute periode.time_in?(hors)
    # - différents formats -
    [
      "15/12/2022",
      Time.new(2022,12,15),
      Time.new(2022,12,15).to_i,
    ].each do |time|
      assert periode.time_in?(time)
    end
  end

  # --- Utilitaires ---
  def lastDay(mois,annee)
    d = Date.civil(annee, mois, -1)
    Time.new(d.year, d.month, d.day, 23, 59, 59)
  end
  def now
    @now ||= Time.now
  end
end #/PeriodeTesteur
