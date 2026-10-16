-- Valores padrão da Akari para as variáveis do Caelestia.
-- A lista completa (e os valores originais) está em ~/.config/hypr/variables.lua.
return {
    -- Apps
    terminal        = "kitty",
    browser         = "firefox",
    editor          = "code",
    fileExplorer    = "dolphin",
    audioSettings   = "pwvucontrol",

    -- Cursor branco, combinando com o preto e branco
    cursorTheme     = "Bibata-Modern-Ice",
    cursorSize      = 24,

    -- Notebook: suspende ao usar o gesto de dormir
    sleepGestureCmd = "systemctl suspend",
}
