-- Suas variáveis do Hyprland (apps padrão, atalhos, bordas, blur...).
-- Referência de tudo que dá para mudar: ~/.config/hypr/variables.lua

-- Padrões da Akari (kitty, Dolphin, Firefox, VS Code, cursor branco)
local vars = dofile("/usr/share/akari/hypr/akari-vars.lua")

-- Suas mudanças, por exemplo:
-- vars.blurEnabled = false
-- vars.kbTerminal  = "SUPER + Return"

return vars
