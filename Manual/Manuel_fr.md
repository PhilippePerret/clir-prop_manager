# Manuel français de `Clir::PropManager`

## Présentation

Cette classe permet de gérer facilement les données des instances (et des classes) dans les applications en ligne de commande (donc les applications tournant dans le Terminal).

Il suffit, pour une classe donnée, de définir les propriétés de ses instances en respectant quelques règles pour pouvoir ensuite afficher, créer, éditer et supprimer n'importe quelle valeur de ces instances.

Par exemple :

On définit les données :

~~~ruby
require 'clir/prop_manager'

class MaClasse
  include ClirPropManagerConstants
  DATA_PROPERTIES = [
    {prop: :id, type: :integer, specs:REQUIRED|DISPLAYABLE}, valid_if: {uniq: true},
    {
      prop: :name, 
      type: :string,
      specs:REQUIRED|DISPLAYABLE|EDITABLE|REMOVABLE,
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

## Définition des propriétés

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
