-- ─────────────────────────────────────────────────────────────
--  Akari 灯り — ajustes sobre o Hyprland do Caelestia
--  Este arquivo é do sistema e é atualizado junto com a imagem.
--  Para mudar algo, use ~/.config/caelestia/hypr-user.lua (vem depois).
-- ─────────────────────────────────────────────────────────────

-- Teclado: usa o layout escolhido na instalação (ex.: br / abnt2)
local function read_keyboard()
    local f = io.open("/etc/X11/xorg.conf.d/00-keyboard.conf")
    if f then
        local s = f:read("*a")
        f:close()
        local layout = s:match('"XkbLayout"%s+"([^"]+)"')
        local variant = s:match('"XkbVariant"%s+"([^"]*)"')
        if layout then
            return layout, variant or ""
        end
    end
    f = io.open("/etc/vconsole.conf")
    if f then
        local s = f:read("*a")
        f:close()
        local km = s:match('KEYMAP="?([%w%-_]+)"?')
        if km == "br-abnt2" or km == "br" then
            return "br", "abnt2"
        elseif km then
            return km:match("^(%a+)") or "us", ""
        end
    end
    return "us", ""
end

local kb_layout, kb_variant = read_keyboard()
hl.config({
    input = {
        kb_layout  = kb_layout,
        kb_variant = kb_variant,
    },
})

-- Máquina virtual (VMware, VirtualBox, QEMU, Hyper-V): a aceleração 3D virtual
-- não funciona com o Qt/Quickshell (tela preta), então desenha pelo processador.
-- No computador de verdade nada muda. Forçar: crie ~/.config/akari/software-render
local function read_file(path)
    local f = io.open(path)
    if not f then return "" end
    local s = f:read("*a") or ""
    f:close()
    return s
end

local function in_vm()
    local dmi = (read_file("/sys/class/dmi/id/sys_vendor") .. " " .. read_file("/sys/class/dmi/id/product_name")):lower()
    for _, v in ipairs({ "vmware", "virtualbox", "innotek", "qemu", "kvm", "bochs", "parallels", "virtual machine", "xen" }) do
        if dmi:find(v, 1, true) then
            return true
        end
    end
    return false
end

local home = os.getenv("HOME") or ""
local function exists(path)
    local f = io.open(path)
    if f then f:close() return true end
    return false
end

if in_vm() or exists(home .. "/.config/akari/software-render") then
    hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
end

-- Apps Qt/KDE (Dolphin) usam as cores do Caelestia via kdeglobals
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- Serviços da sessão (caminhos do Fedora)
hl.on("hyprland.start", function()
    -- Hajime: a transição de boas-vindas depois da senha
    hl.exec_cmd("/usr/libexec/akari/hajime")
    -- Janela de senha do sistema (polkit) no estilo do Hyprland
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    -- Localização para o modo noturno (gammastep)
    hl.exec_cmd("/usr/libexec/geoclue-2.0/demos/agent")
    -- Wallpaper animado (se o escolhido for um dos animados)
    hl.exec_cmd("sleep 2 && /usr/libexec/akari/akari-wallpaper-hook")
    -- Tarefas em segundo plano (ex.: instalar o JetBrains Toolbox)
    hl.exec_cmd("/usr/libexec/akari/akari-session-start")
end)

-- A transição aparece na hora, sem animação de camada
hl.layer_rule({ match = { namespace = "akari-hajime" }, no_anim = true })

-- Ichiba (loja) e JetBrains Toolbox abrem flutuando, no centro
hl.window_rule({
    match  = { class = "^(ichiba)$" },
    float  = true,
    size   = "(monitor_w*0.72) (monitor_h*0.8)",
    center = true,
})
hl.window_rule({ match = { class = "^(jetbrains-toolbox)$" }, float = true })
