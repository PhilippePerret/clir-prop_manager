# Pour pouvoir exposer publiquement, au niveau d'une classe,
# les constantes utiles
module ClirPropManagerConstants
  
  # --- Properties Constants ---
  REQUIRED    = 1
  DISPLAYABLE = 2
  EDITABLE    = 4
  REMOVABLE   = 8

  ALL_SPECS = REQUIRED|DISPLAYABLE|EDITABLE|REMOVABLE
end
