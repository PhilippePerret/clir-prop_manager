# Manuel français de `Clir::PropManager`

## Présentation

Cette classe permet de gérer facilement les données des instances (et des classes) dans les applications en ligne de commande (donc les applications tournant dans le Terminal).

Il suffit, pour une classe donnée, de définir les propriétés de ses instances en respectant quelques règles pour pouvoir ensuite afficher, créer, éditer et supprimer n'importe quelle valeur de ces instances.

Par exemple :

On définit les données de la classe `MaClasse` :

~~~ruby
require 'clir/prop_manager'

class MaClasse
  include ClirPropManagerConstants
  DATA_PROPERTIES = [
    {prop: :id, type: :integer, specs:REQUIRED|DISPLAYABLE}, valid_if: {uniq: true},
    {
      prop: :name, 
      type: :string,
      specs:ALL_SPECS,
      valid_if: {
        not_empty:true, 
        min_length: 3, 
        max_length:40
      }
    }
  ]
end
~~~

On instancie un manager de données pour la classe :

~~~ruby

class MaClasse
  def self.prop_manager
    @@prop_manager ||= Clir::PropManager.new(self)
  end
end
~~~

Note : si la classe définissait ses données dans une autre constante que `DATA_PROPERTIES`, il faudrait donner cette constante en second argument de `Clir::PropManager.new`.

---

On peut maintenant utiliser cette méthode pour éditer les valeurs d'une instance :

~~~ruby
inst = MaClasse.new

inst.create
# => Permet de créer l'instance

inst.edit
# => permet d'éditer (de modifier) l'instance

inst.display
# => Affiche les données de l'instance

inst.remove
# => Détruit l'instance
~~~

---

<a name="data-properties"></a>

## Données des propriétés d’instance

Le bon fonctionnement du ***manager de propriété*** tient principalement à la bonne définition des propriétés. Cette définition permet de tout savoir sur la donnée et de savoir comment la gérer.

### Liste `Array`

Les données sont définies dans une liste (`{Array}`) afin de préserver l'ordre défini.

### Nom de la constante

Par défaut, le gem s'attend à trouver la constante `DATA_PROPERTIES` définie par la classe à manager. Mais ces données peuvent être définies dans toute autre constante si elle est fournie en second argument de l'instanciation du manager :

~~~ruby
class MaClasse
  AUTRES_DATA = [...]
  def self.manager
    @@manager ||= Clir::PropManager.new(self, AUTRES_DATA)
  end
~~~

---

## Formatage de l’affichage des données

La classe managée peut définir des méthodes de formatage d’affichage particulières pour chaque donnée. Par convention, ce nom doit être `f_<property name>`. Par exemple, si la propriété est **`name`** alors le nom de la méthode de mise en forme de sa valeur doit être par défaut **`f_name`**.

Par exemple : 

~~~ruby
class MaClasseManaged
  
  def age
    @age ||= data[:age]
  end
  
  def f_age
    "#{age} ans"
	end
  
end
~~~

On peut cependant définir un nom de méthode propre en définissant la propriété **`:mformate`** dans les [données des propriétés][].

> Note : toutes les valeurs commençant par “`:m` dans la définition des propriétés concernent des méthodes.

Par exemple :

~~~ruby
class MaClasse
  DATA_PROPERTIES = [
    {prop: :name, 	name:"Patronyme", type: :string, specs:ALL_SPECS, mformate: :formate_nom}
    {prop: :sexe, 	name:'Sexe', type: :string, specs:ALL_SPECS}
  ]
  
  def name; @name ||= data[:name] end
  def sexe; @sexe ||= data[:sexe] end
  def formate_nom
    "#{sexe == 'F' ? "Madame" : "Monsieur"} #{name}"
  end
end #/class
~~~











[données des propriétés]: #data-properties
