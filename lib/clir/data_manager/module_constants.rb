# Pour pouvoir exposer publiquement, au niveau d'une classe,
# les constantes utiles
module ClirDataManagerConstants
  
  # --- Properties Constants ---
  REQUIRED    = 1
  DISPLAYABLE = 2
  EDITABLE    = 4
  REMOVABLE   = 8
  TABLEIZABLE = 16 # pour affiche pluriel dans une Clir::Table

  ALL_SPECS = ALL = REQUIRED|DISPLAYABLE|EDITABLE|REMOVABLE|TABLEIZABLE
end
