# Manuel français de `Clir::DataManager`

## Présentation

Cette classe permet de gérer facilement les données des instances (et des classes) dans les applications en ligne de commande (donc les applications tournant dans le Terminal).

Il suffit, pour une classe donnée, de définir les propriétés de ses instances en respectant quelques règles pour pouvoir ensuite afficher, créer, éditer et supprimer n'importe quelle valeur de ces instances.

Par exemple :

On définit les données de la classe `MaClasse` :

~~~ruby
require 'clir/data_manager'

class MaClasse
  include ClirDataManagerConstants
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
  
  # On doit définir aussi la sauvegarde
  @@save_system 	= :card # données sauvées dans des fiches
  @@save_format 	= :yaml # au format YAML
  @@save_location = "./data" # dans le dossier 'data'
end
~~~

On instancie un manager de données pour la classe :

~~~ruby
Clir::DataManager.new(MaClasse)
~~~

Cela implémente automatiquement plein de méthodes utiles pour les données et notamment :

~~~ruby
MaClasse.get(id)
# Retourne l'instance d'identifiant :id

<MaClasse>#create([{data}])
# Pour créer une instance (avec ou sans les données {data}

MaClasse.items
# => liste des instances

MaClasse.table 
# => table des instances avec en clé leur identifiant
~~~



Note : si la classe définissait ses données dans une autre constante que `DATA_PROPERTIES`, il faudrait donner cette constante en second argument de `Clir::DataManager.new`.

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

inst.new?
# => true si c'est une création d'instance (i.e. une instance qui n'a
#    pas encore été enregistrée

~~~

---

<a name="data-properties"></a>

## Données des propriétés d’instance

Le bon fonctionnement du ***manager de propriété*** tient principalement à la bonne définition des propriétés, généralement (mais pas exclusivement) dans la constante **`DATA_PROPERTIES`**. Cette définition permet de tout savoir sur les données et de savoir comment les gérer.

### Liste `Array`

Les données sont définies dans une liste (`{Array}`) afin de préserver l'ordre défini.

### Nom de la constante

Par défaut, le gem s'attend à trouver la constante **`DATA_PROPERTIES`** définie par la classe à manager. Mais ces données peuvent être définies dans toute autre constante si elle est fournie en second argument de l'instanciation du manager :

~~~ruby
class MaClasse
  AUTRES_DATA = [...]
  def self.manager
    @@manager ||= Clir::DataManager.new(self, AUTRES_DATA)
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



### Transformation de la donnée entrée

Quand on attend un nom (patronyme), on peut vouloir systématiquement le passer en capitale, quelle que soit l’entrée de l’utilisateur.

Pour ce faire, dans la donnée de la propriété dans `DATA_PROPERTIES`, on ajoute l’attribut `:itransform` (qui signifie “input transform” ou “transformation de la donnée entrée”.

Cette attribut peut avoir différents types de valeur :

* **une procédure** qui reçoit en premier argument l’instance et en second argument la valeur entrée
* **un symbol**. C’est alors une méthode à laquelle répond soit l’instance, sans la valeur. Par exemple, pour notre exemple, nous pourrions avoir `itransform: :upcase`. L’instance, a priori, ne répondant pas à cette méthode, c’est la valeur qui sera affectée.

---

<a name="data-manager"></a>

## Atteindre le manager de données (`#data_manager`)

Depuis la classe, on peut faire appel au manager de données à l’aide de `data_manager`. Par exemple :

~~~ruby
MaClasseManaged.data_manager.save_format
# Retourne :yaml si le format défini (dans @@save_format) est :yaml
~~~

La seule méthode du data manager qui est exposée publiquement d’office, c’est la propriété **`save_location`**  qui retourne le chemin d’accès soit au fichier de données (si `@@save_system = :file`) soit au dossier des fiches (si `@@save_system = :card`). On peut l’atteindre par :

~~~ruby
MaClasseManaged.save_location
# => /path/to/folder/de/sauvegarde/
~~~



## Les petits plus

Le fait de travailler avec `Clir::DataManager` offre de nombreux avantages, comme on a pu le voir. Il existe cependant quelques petites astuces à connaitre.

### Filtrer la liste des propriétés

Quand la liste des propriétés de l’instance est affichée, par exemple pour l’éditer (aka la modifier), on peut atteindre très rapidement la propriété à modifier en tapant ses premières lettres (ou ses lettres caractéristiques). Cela filtre la liste des propriétés et n’affiche que les propriétés correspondant au filtre. Si la liste des propriétés est longue, on peut énormément se simplifier la vie avec cette astuce.





[données des propriétés]: #data-properties
