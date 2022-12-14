=begin

  Class Periode
  -------------
  Pour gérer une période de temps, à partir d'une date (:from_date)
  jusqu'à une autre date (:to_date)

  Initialisation possible avec :
    - des vraies dates (Date)
    - des vrais temps (Time)
    - des dates stings en "JJ/MM/AAAA" (ATTENTION ! Format FR)
    - des dates strings inverses "AAAA/MM/JJ"
    - des dates strings raccourcis, par exemple seulement l'année
      ou le mois
    - des timestamps/nombre de secondes

  On obtient ensuite des méthodes pratiques et particulièrement la
  méthode :human_period qui détecte si la date définit une année, 
  un trimestre, un mois, etc.

  <Periode>#human_period ou #as_human
    => Période au format humain
        ("année xxxx", "1er trimestre 2014", "mois d’avril 2009",
         "semaine 25 de l’année 2012", 
         "du 1er avril au 1er juin 2022")

  <Periode>#du_au
    => "du <date départ> au <date fin>"

  <Periode>#from 
    => date de départ ({Time})

  <Periode>#to
    => date {Time} de fin

  <Periode>#time_in?(time)
    => true si le temps +time+ est dans la période


=end
require 'date'
# require_relative 'Date_utils'

class Periode

  # Pour définir une période (une date de départ et de fin)
  def self.choose(params = nil)
    params ||= {}
    params.merge!(from_date: params.delete(:default)) if params.key?(:default)
    params.key?(:from_date) || params.merge!(from_date: nil)
    params.key?(:to_date)   || params.merge!(to_date: nil)
    params[:from_date] = params[:from_date].to_s if params[:from_date].is_a?(Integer)
    while true
      date_default = params[:from_date] || Time.now
      if not date_default.is_a?(String)
        date_default = date_default.strftime('%d/%m/%Y')
      end
      params[:from_date]  = ask_for_a_date("De la date", date_default)
      if params[:from_date].is_a?(String) 
        if params[:from_date].match?(/^[0-9]{4}$/)
          params.merge!({
            from_date: "01/01/#{params[:from_date]}",
            to_date:   "01/01/#{params[:from_date].to_i + 1}"
          })
          break
        elsif params[:from_date].match?(/^[0-9]{1,2}\/[0-9]{4}$/)
          # 
          # Seulement le mois donné
          # 
          mois, annee = params[:from_date].split('/').collect{|n|n.to_i}
          fromdate, todate =
            if mois == 12
              ["01/12/#{annee}", "01/01/#{annee + 1}"]
            else
              ["01/#{mois.to_s.rjust(2,'0')}/#{annee}", "01/#{(mois + 1).to_s.rjust(2,'0')}/#{annee}"]
            end
          params.merge!(from_date:fromdate, to_date:todate)
          break
        end
      else
        params[:to_date] = ask_for_a_date("À la date", date_default)
        # --- Vérifications ---
        if params[:from_date] > params[:to_date]
          erreur "La date de début ne peut être supérieure à la date de fin…"
        else
          break
        end
      end
    end #/boucle

    return new(params[:from_date], params[:to_date], params[:options])
  end

  
  attr_reader :from_date, :to_date

  def initialize(from_date, to_date = nil, options = nil)
    from_date, to_date = defaultize(from_date, to_date)
    @from_date = date_from(from_date)  
    @to_date   = date_from(to_date)
  end

  def inspect
    @inspect ||= "#<Periode #{as_la_periode}>"
  end

  # @public
  # 
  # @return [Boolean] Si le temps +time+ (qui peut être exprimé par
  # une multitude de choses) se trouve dans la période courante
  # @param [Any] time   Le temps à tester, qui doit pouvoir être évalué par 'date_from'
  #                     [String] "JJ/MM/AAAA"
  #                     [Integer] 
  def time_in?(time)
    time = date_from(time)
    return time >= from_date && time <= to_date
  end

  ##
  # Méthode qui reçoit les deux premiers arguments de l'initiation
  # pour les interpréter au besoin. Par exemple, on peut fournir
  # seulement une année (dans +from_date+) ou un mois (MM/AAAA)
  # 
  # [N0001]
  #   Une année chiffrée (2022) peut avoir été donnée
  # 
  REG_ANNEE = /^[0-9]{4}$/
  REG_MOIS  = /^[0-9]{1,2}\/[0-9]{4}$/
  def defaultize(from_date, to_date)
    return [from_date, to_date] if to_date.is_a?(Time) || to_date.is_a?(Date)
    from_date = from_date.to_s # cf. [N0001]
    if to_date.nil?
      if from_date.match?(REG_ANNEE)
        # 
        # Période d'une année
        #
        annee = from_date.to_i
        from_date = "01/01/#{annee}"
        to_date   = "01/01/#{annee + 1}" 
      elsif from_date.match?(REG_MOIS)
        # 
        # Période d'un mois
        # 
        mois, annee = from_date.split('/')
        from_date = "01/#{mois.rjust(2,'0')}/#{annee}"
        if mois.to_i == 12
          mois, annee = [0, annee.to_i + 1]
        end
        to_date = "01/#{(mois.to_i+1).to_s.rjust(2,'0')}/#{annee}"
      end
    end
    return [from_date, to_date]
  end

  # - raccourcis -
  def from; from_date end
  def to; to_date end

  # - clé pour table -
  def as_hash_key
    @as_hash_key ||= "#{from.to_i}-#{to.to_i}"
  end
  
  ##
  # @return la durée en secondes de la période
  def duration
    @duration ||= to_timestamp - from_timestamp
  end

  def from_timestamp
    @from_timestamp ||= from_date.to_i
  end
  def to_timestamp
    @to_timestamp ||= to_date.to_i
  end

  ##
  # @return "l'année ..." ou "Le trimestre", etc.
  # 
  def as_la_periode
    @as_la_periode ||= begin
      if debut_et_fin_de_semaine?
        "la #{as_human}"
      elsif premier_jour_mois?
        if debut_et_fin_de_mois?
          "le mois d#{human_month.match?(/^[ao]/) ? '’' : 'e '}#{human_month} #{human_year}"
        elsif debut_et_fin_trimestre?
          "#{hindex_trimestre} trimestre #{human_year}"
        elsif debut_et_fin_annee?
          "l’année #{human_year}"
        else
          "le #{human_period_jours}"
        end
      else
        "le #{human_period_jours}"
      end
    end    
  end
  alias :to_s :as_la_periode

  ##
  # @return un texte comme "de l'année 2021"
  def as_du_au
    @as_du_au ||= begin
      if debut_et_fin_de_semaine?
        "de la #{as_human}"
      elsif premier_jour_mois?
        if debut_et_fin_de_mois?
          "du mois d#{human_month.match?(/^[ao]/) ? '’' : 'e '}#{human_month} #{human_year}"
        elsif debut_et_fin_trimestre?
          "#{hindex_trimestre} trimestre #{human_year}"
        elsif debut_et_fin_annee?
          "de l’année #{human_year}"
        else
          "du #{human_period_jours}"
        end
      else
        "du #{human_period_jours}"
      end
    end
  end
  
  def human_period
    @human_period ||= begin
      # Est-ce une semaine ?
      if debut_et_fin_de_semaine?
        "semaine #{from_date.to_date.cweek} de l’année #{human_year}"
      elsif premier_jour_mois?
        if debut_et_fin_de_mois?
          "mois d#{human_month.match?(/^[ao]/) ? '’' : 'e '}#{human_month} #{human_year}"
        elsif debut_et_fin_trimestre?
          "#{hindex_trimestre} trimestre #{human_year}"
        elsif debut_et_fin_annee?
          "Année #{human_year}"
        else
          human_period_jours
        end
      else
        human_period_jours
      end
    end
  end
  alias :as_human :human_period

  ##
  # @return la période simple en jour (lorsqu'aucun période humaine
  #         n'a été trouvée)
  # 
  def human_period_jours
    @human_period_jours ||= begin
      formated_from = formate_date(from_date, **{no_time: true, update_format:true, verbal: true})
      if from_date.year == to_date.year
        # Les années sont identiques, on les rassemble à la fin
        formated_from = formated_from[0..-6]
      end
      "#{formated_from} au #{formate_date(to_date, **{no_time: true, update_format:true, verbal: true})}"
    end
  end

  def as_human_jours
    @as_human_jours ||= "du #{human_period_jours}"
  end
  alias :du_au :as_human_jours

  ##
  # @return TRUE si la période correspond à un début et une fin de
  # semaine
  def debut_et_fin_de_semaine?
    :TRUE == @is_debut_et_fin_de_semaine ||= begin
      from_date.wday == 1 && duration.proche?(7.days) ? :TRUE : :FALSE
    end
  end

  ##
  # @return TRUE si la période commence le premier jour d'un mois
  def premier_jour_mois?
    from_date.day == 1
  end

  ##
  # @return TRUE si la période correspond à un mois
  # 
  def debut_et_fin_de_mois?
    from_date.day == 1 || return
    :TRUE == @is_debut_et_fin_de_mois ||= begin
      d = (from_date.to_date >> 1).to_time
      to_date.proche?(d) ? :TRUE : :FALSE
    end
  end

  ##
  # @return TRUE si la période correspond à un trimestre
  # 
  def debut_et_fin_trimestre?
    from_date.day == 1 || return
    :TRUE == @is_debut_et_fin_trimestre ||= begin
      d = from_date.to_date >> 3
      d = Date.new(d.year, d.month, 1).to_time
      to_date.proche?(d) ? :TRUE : :FALSE
    end
  end

  ##
  # @return TRUE is la période correspond à une année
  #
  def debut_et_fin_annee?
    from_date.day == 1    || return
    from_date.month == 1  || return
    :TRUE == @is_debut_et_fin_annee ||= begin
      dcomp = Time.new(from_date.year + 1, 1, 1)
      to_date.proche?(dcomp) ? :TRUE : :FALSE
    end
  end

  # Mois humain (en prenant le mois de from_date)
  def human_month
    @human_month ||= MOIS[from_date.month][:long]
  end
  # Année (en prenant l'année de from_date)
  def human_year
    @human_year ||= from_date.year
  end

  ##
  # Index du trimestre (de from_date)
  def index_trimestre
    @index_trimestre ||= (from_date.month.to_f / 3).ceil
  end

  def hindex_trimestre
    @hindex_trimestre ||= begin
      "#{index_trimestre}e#{index_trimestre > 1 ? '' : 'r'}"
    end
  end

  # dernier jour du mois (en prenant le mois de to_date)
  def last_day_of_the_month
    @last_day_of_the_month ||= Date.civil(to_date.year, to_date.month, -1).day
  end
  def from_mois
    @from_mois ||= from_date.month
  end
  def to_mois
    @to_mois ||= to_mois
  end
end

class Time
  def proche?(t)
    self.to_i.proche?(t.to_i)
  end
end
class Integer
  # Retourne true si le nombre (de secondes correspondant à une
  # durée) est ± une demi-heure
  def proche?(laps)
    self.between?(laps - 1800, laps + 1800) 
  end
  def days
    self * 24 * 3600
  end
  alias :day :days
end


