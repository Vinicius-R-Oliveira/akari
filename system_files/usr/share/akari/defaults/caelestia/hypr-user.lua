-- Suas configurações extras do Hyprland (carregado por último).
-- Wiki: https://wiki.hypr.land/Configuring/Start/

-- Recursos da Akari (Hajime, teclado, apps do Fedora). Não remova esta linha.
dofile("/usr/share/akari/hypr/akari.lua")

-- Exemplos:
-- Tela do notebook a 144 Hz
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
--
-- Desligar a transição de boas-vindas (Hajime):
--   crie o arquivo ~/.config/akari/no-hajime
