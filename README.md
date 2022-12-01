# Clir::PropManager

1. You define (deeply) the instance properties,
2. you "attach" the PropManager to your class,
3. you can then create, edit, remove and save your instances in command line.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'clir/prop_manager'
```

En attendant que le gem soit complet, mettre le code suivant dans le programme devant l'utiliser (pas besoin de faire `bundle install` etc.) :

~~~

$LOAD_PATH.unshift File.join(Dir.home,'Programmes','Gems','clir-prop_manager','lib')

~~~

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install clir-prop_manager

## Usage

Pour qu'une classe quelconque puisse utiliser le gem, lui mettre :

~~~ruby
module MonModule
  class MaClasse
    include ClirPropManagerConstants # <==== usefull
  end
end

Clir::PropManager.new(MonModule::MaClasse)

~~~

Le module `ClirPropManagerConstants` permet de charger les constants comme `REQUIRED`, `EDITABLE`, etc.

Il faut ensuite définir les propriétés des instances de cette classe, à l'aide la constante `DATA_PROPERTIES` :

~~~ruby
module MonModule
  class MaClasse

    DATA_PROPERTIES = [
      {prop: :id,   type: :id, name: "ID", specs: REQUIRED, default: :new_id},
      {prop: :name, type: :string,  name:"Votre nom", specs:REQUIRED|EDITABLE|DISPLAYABLE},
      {prop: :name, type: :string,  name:"Votre genre", specs:ALL, default: 'F'}
      # ...
    ]

  end
end
~~~

On pourrait aussi envoyer les données lors de l'installation du manager de propriétés :

~~~ruby

pdata = [
  {prop: :id, ...}
]

Clir::PropManager.new(MonModule::MaClasse, pdata)

~~~

Pour créer la première instance, il suffit ensuite de faire :

~~~ruby

MonModule::MaClasse.new.create

~~~

Pour éditer ou afficher une instance de la classe :

~~~ruby
i = MonModule::MaClasse.new()

i.edit

i.show

~~~

Les données sont toujours placées dans la propriété `@data` de l'instance, qui peut être définie à l'instanciation, une fois qu'on a les données :

~~~ruby

module MonModule
  class MaClasse

    def initialize(data)
      @data = data
    end
  end
end
~~~

Noter qu'il n'est pas nécessaire de faire `attribute_reader: :data` puisque data est automatiquement défini en accesseur.

Noter qu'il n'est pas non plus nécessaire de créer toutes les méthodes-propriété qui sont nécessaires habituellement pour récupérer et définir les valeurs.

À partir du moment où `DATA_PROPERTIES` définit : 

~~~ruby
DATA_PROPERTIES = [
  # ...
  {prop: :maprop, ...}
  # ...
]
~~~

… alors le manager de propriétés définit les méthodes : 

~~~ruby
module MonModule
  class MaClasse

    def maprop
      return @data[:maprop]
    end

    def maprop=(value)
      @data.merge!(maprop: value)
    end

  end
end
~~~

Donc, on récupère et définit les valeurs de cette manière :

~~~ruby

i = MonModule::MaClasse.new({maprop: "Valeur courante"})

i.maprop
# => "Valeur courante"

i.maprop = "Nouvelle valeur"

i.maprop
# => "Nouvelle valeur"

~~~

### Définition des propriétés

C'est donc la grosse partie pour utiliser profitablement de `PropManager`. Une bonne définition des propriétés conduit à une utilisation tout à fait efficace.

#### Identifiant de la propriété 

Cet identifiant se définit à l'aide de l'attribut `:prop`.

~~~ruby
DATA_PROPERTIES = [
  { prop: :maprop }
]
~~~

C'est par ce nom que l'instance connaitra la valeur consignée. Pour définir quelqu'un, par exemple, on aura :

~~~ruby
DATA_PROPERTIES = [
  { prop: :prenom },
  { prop: :nom    },
]
~~~

Et une instance pourra utiliser :

~~~ruby
simone = MaClasse.new
simone.prenom
# => "Simone"
simone.nom
# => "De Beauvoir"
~~~

#### Question personnalisée

Par défaut, la question « Nouvelle valeur pour “`<propriété>`” » est posée pour modifier une propriété.

On peut néanmoins définir une autre question avec l'attribut `:quest` qui peut contenir des valeurs de template <b>qui ne doivent utiliser que les valeurs dans les `data` de l'instance</b>.

TODO: Plus tard on pourra aussi imaginer évaluer la question ou fournir d'autres valeurs au template (par exemple un attribut `:quest_values` qui pourrait être définie en dur ou par une procédure qui utiliserait l'instance en premier argument).

#### Valeur par défaut dans les propriétés

Une donnée propriété peut définir la valeur par défaut de cette propriété pour une instance donnée. 

~~~ruby
DATA_PROPERTIES = [
  {prop: :maprop ... default: <...> }
]
~~~

Cette valeur peut être de diférent type :

* une valeur explicite :

~~~ruby
  default: "Ma valeur par défafut"
  default: 12
  default: true
~~~

* une procédure :

~~~ruby
  default: Proc.new() { |instance| instance.name.length }
~~~

> Noter que l'instance est toujours transmise en premier argument.

* une méthode d'instance :

~~~ruby
class MaClasse
  def valeur_default_pour_prop
    return "oui"
  end
end

default: :valeur_default_pour_prop
~~~

* une méthode de classe :

~~~ruby
class MaClasse
  def self.valeur_default_pour_prop
    @@valeur_prop += 1
  end
end

default: :valeur_default_pour_prop
~~~



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/clir-prop_manager.

