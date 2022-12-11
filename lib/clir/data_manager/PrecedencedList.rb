=begin

  Class Clir::PrecedencedList
=end
module Clir
class PrecedencedList < Array

  ##
  # Instantiation
  # 
  # @param liste {Array} La liste des items
  # @param  list_name {String} Un nom unique pour cette liste de
  #         valeur. Si ce n'est pas un nom unique, des comportements
  #         inattendus se produiront.
  # 
  def initialize(liste, list_name)
    super(liste)
    liste.first.is_a?(Hash) || raise("Pour pouvoir gérer les précédences d'une liste, il faut que les éléments soit des dictionnaires (Hash).")
    liste.first.key?(:value) || raise("Pour pouvoir gérer les précédences d'une liste, il faut que les éléments définissent l'attribut unique :value.")
    @list_name = list_name
  end

  # = main =
  # 
  # Méthode principale qui retourne les items gérés au niveau de
  # la précédence.
  # 
  def to_prec
    if precedence_exist?
      @table = nil # Pour forcer 
      liste = precedences.map do |value|
        table.delete(value)
      end.compact # les items supprimés
      # 
      # On ajoute les items restants
      # 
      table.each do |value, ditem|
        liste << ditem
      end
      return liste
    else
      return self
    end
  end

  # @public
  # = main =
  # 
  # Méthode principale pour enregistrer le dernier item choisi
  # 
  def set_last(value)
    precedences.delete(value)
    @precedences.unshift(value)
    save
  end


  def table
    @table ||= begin
      tbl = {}
      self.each { |ditem| tbl.merge!(ditem[:value] => ditem) }
      tbl
    end
  end

  def save
    File.write(path, precedences.join("\n"))
  end

  def precedences
    @precedences ||= begin
      if precedence_exist?
        # puts "Je lis le fichier de précédence : #{path}".orange
        # sleep 4
        File.read(path).split("\n")
      else [] end
    end
  end

  def precedence_exist?
    File.exist?(path)
  end

  def path
    @path ||= File.join(self.class.folder, "#{@list_name}.precedences")
  end

  # @note
  #   En mode test, il faut le refaire chaque fois
  def self.folder
    if test?
      mkdir(File.join(Dir.home, 'TESTS', '.precedences'))
    else
      @@folder ||= mkdir(File.join(Dir.home, '.precedences'))
    end
  end
end #/class PrecedencedList
end #/module Clir
