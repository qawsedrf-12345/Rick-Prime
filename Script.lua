--=============================================================
-- SISTEMA COMPLETO v7.3 - RESPAWN + MORPH (R6) + FREEZE 0.65s
-- Mudanças v7.3:
--   • Fade preto → fade AZUL CIANO TRANSPARENTE
--   • Respawn mantém POSIÇÃO + ROTAÇÃO da morte
--=============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local SoundService     = game:GetService("SoundService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--=============================================================
-- CONFIGURAÇÕES GERAIS
--=============================================================
local CONFIG = {
    -- ============================================
    -- ÁUDIOS DE RESPAWN
    -- ============================================
    AudioMorte = "rbxassetid://74856211490258",
    VolumeAudioMorte = 1,
    PitchMinMorte = 0.98,
    PitchMaxMorte = 1.02,
    TocarAudioMorte = true,

    AudioRespawn = "rbxassetid://100387192833625",
    AudioRespawn2 = "rbxassetid://1013378689",
    VolumeAudioRespawn = 1,
    VolumeAudioRespawn2 = 0.8,
    PitchMinRespawn = 0.98,
    PitchMaxRespawn = 1.02,

    PreCarregarAudio = true,
    DelayAudioRespawn = 0,
    OffsetY = 3,

    -- ============================================
    -- 🎨 FADE (CIANO TRANSPARENTE)
    -- ============================================
    CorFade = Color3.fromRGB(0, 220, 255),
    TransparenciaFade = 0.55,

    -- ============================================
    -- 🥶 FREEZE NO RESPAWN
    -- ============================================
    FreezeAtivo = true,
    FreezeDuracao = 0.65,
    FreezeCamera = true,
    FreezeMovimento = true,
    FreezePulo = true,

    -- ============================================
    -- EFEITOS DE MORTE
    -- ============================================
    MorteFlashCiano = true,
    MorteFlashDuracao = 0.12,
    MorteCorCiano = Color3.fromRGB(0, 255, 255),
    MorteRGBSplit = true,
    MorteRGBDuracao = 0.4,
    MorteRGBDeslocamento = 8,
    MorteRGBPulsos = 4,
    MorteScanlines = true,
    MorteScanlinesDuracao = 0.7,
    MorteScanlinesVelocidade = 3,
    MorteVinhetaVermelha = true,
    MorteVinhetaDuracao = 0.6,
    MorteVinhetaIntensidade = 0.8,
    MorteFade = true,
    MorteFadeDuracao = 0.4,
    MorteCameraShake = true,
    MorteShakeIntensidade = 2.5,
    MorteShakeDuracao = 0.5,
    MorteShakeRotacional = true,
    MorteParticulas = true,
    MorteParticulasQuantidade = 120,
    MorteGlitchBlocks = true,
    MorteGlitchDuracao = 0.6,
    MorteGlitchQuantidade = 35,
    MorteBlur = true,
    MorteBlurTamanho = 15,
    MorteBlurDuracao = 0.7,
    MorteExplosaoLuz = true,
    MorteExplosaoDuracao = 0.5,

    -- ============================================
    -- EFEITOS DE RESPAWN
    -- ============================================
    RespawnFragmentos = true,
    RespawnFragmentosQuantidade = 40,
    RespawnFragmentosDuracao = 0.45,
    RespawnFragmentosRotacao = true,
    RespawnAnelEnergia = true,
    RespawnAnelDuracao = 0.55,
    RespawnFlashBranco = true,
    RespawnFlashDuracao = 0.18,
    RespawnPortalVerde = true,
    RespawnPortalDuracao = 0.7,
    RespawnPortalCor = Color3.fromRGB(50, 255, 130),
    RespawnPortalAnelInterno = true,
    RespawnCameraShake = true,
    RespawnShakeIntensidade = 1.2,
    RespawnShakeDuracao = 0.3,
    RespawnScanlines = true,
    RespawnScanlinesDuracao = 0.5,
    RespawnBlur = true,
    RespawnBlurTamanho = 10,
    RespawnBlurDuracao = 0.45,
    RespawnFeixeLuz = true,
    RespawnFeixeDuracao = 0.7,
    RespawnOndasChoque = true,
    RespawnOndasQuantidade = 3,
    RespawnOndasDuracao = 0.6,
    RespawnExplosaoParticulas = true,
    RespawnParticulasQuantidade = 60,
    RespawnRastroEnergia = true,
    RespawnRastroDuracao = 0.8,
    RespawnEcoDimensional = true,
    RespawnEcoDuracao = 0.7,
    RespawnFadeOutDuracao = 0.4,

    -- ============================================
    -- PÓS-RESPAWN
    -- ============================================
    PosRespawnChromaticEcho = true,
    PosRespawnDuracao = 0.6,
    PosRespawnColorCorrection = true,
    PosRespawnSaturacao = 0.4,
    PosRespawnContraste = 0.25,

    -- ============================================
    -- AUTO MORPH (só roda em jogos R6)
    -- ============================================
    MorphUsername = "quakehhhf",
    MorphAtivo = true,

    DEBUG = false,
}

--=============================================================
-- ESTADO GERAL
--=============================================================
local cframeSalvo = nil
local localInvisivel = nil
local conexoesCharacter = {}
local salvandoAtivo = true
local ultimoCFrameSalvo = nil
local tempoUltimoSalvamento = 0

local audiosRespawnAtivos = {}
local cicloAtual = 0
local audioTocadoNesteCiclo = false

local blurEffect = nil
local colorCorrectionEffect = nil
local cacheAudio = {}
local morphDescCache = nil

local freezeAtivo = false
local freezeConexoes = {}
local freezeToken = 0

local rigTypeJogo = nil

local function log(...)
    if CONFIG.DEBUG then print("[Sistema]", ...) end
end

local function agora()
    return os.clock()
end

local function detectarRigType()
    if rigTypeJogo then return rigTypeJogo end

    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            rigTypeJogo = hum.RigType
            log("🎯 Rig detectado (jogador):", rigTypeJogo.Name)
            return rigTypeJogo
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                rigTypeJogo = hum.RigType
                log("🎯 Rig detectado (outro player):", rigTypeJogo.Name)
                return rigTypeJogo
            end
        end
    end

    rigTypeJogo = Enum.HumanoidRigType.R15
    log("⚠️ Rig não detectado. Assumindo R15.")
    return rigTypeJogo
end

local function preCarregarAudio(id)
    if not id or id == "" then return end
    if cacheAudio[id] then return end

    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = 0
    sound.Parent = SoundService
    cacheAudio[id] = sound

    task.spawn(function()
        local tentativas = 0
        while not sound.IsLoaded and tentativas < 100 do
            task.wait(0.1)
            tentativas = tentativas + 1
        end
        if sound.IsLoaded then log("✅ Áudio pré-carregado:", id) end
    end)
end

local function criarBlur(tamanho)
    pcall(function()
        if blurEffect then blurEffect:Destroy() end
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Size = 0
        blurEffect.Parent = Lighting
        TweenService:Create(blurEffect, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Size = tamanho }):Play()
    end)
end

local function removerBlur(duracao)
    pcall(function()
        if not blurEffect then return end
        local b = blurEffect
        local tween = TweenService:Create(b, TweenInfo.new(duracao or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 })
        tween:Play()
        tween.Completed:Connect(function()
            if b and b.Parent then b:Destroy() end
            if blurEffect == b then blurEffect = nil end
        end)
    end)
end

local function criarColorCorrection(saturacao, contraste, duracao)
    pcall(function()
        if colorCorrectionEffect then colorCorrectionEffect:Destroy() end
        colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
        colorCorrectionEffect.Saturation = 0
        colorCorrectionEffect.Contrast = 0
        colorCorrectionEffect.Parent = Lighting
        TweenService:Create(colorCorrectionEffect, TweenInfo.new(duracao, Enum.EasingStyle.Quad), { Saturation = saturacao, Contrast = contraste }):Play()
    end)
end

local function removerColorCorrection(duracao)
    pcall(function()
        if not colorCorrectionEffect then return end
        local c = colorCorrectionEffect
        local tween = TweenService:Create(c, TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Saturation = 0, Contrast = 0 })
        tween:Play()
        tween.Completed:Connect(function()
            if c and c.Parent then c:Destroy() end
            if colorCorrectionEffect == c then colorCorrectionEffect = nil end
        end)
    end)
end

local function limparConexoesFreeze()
    for _, conn in ipairs(freezeConexoes) do
        pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
    end
    freezeConexoes = {}
end

local function iniciarFreeze(character, duracao)
    if not CONFIG.FreezeAtivo then return end

    freezeToken = freezeToken + 1
    local meuToken = freezeToken

    freezeAtivo = true
    limparConexoesFreeze()

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera

    if not humanoid or not rootPart or not camera then
        freezeAtivo = false
        return
    end

    if CONFIG.FreezeMovimento then
        pcall(function()
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
        end)
    end

    if CONFIG.FreezePulo then
        local connPulo = UserInputService.JumpRequest:Connect(function()
            if freezeAtivo and freezeToken == meuToken then
                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Seated) end)
            end
        end)
        table.insert(freezeConexoes, connPulo)
    end

    local cframeCameraCongelada = camera.CFrame
    if CONFIG.FreezeCamera then
        local connCam = RunService.RenderStepped:Connect(function()
            if freezeAtivo and freezeToken == meuToken and camera then
                camera.CFrame = cframeCameraCongelada
                camera.Focus = CFrame.new(cframeCameraCongelada.Position)
            end
        end)
        table.insert(freezeConexoes, connCam)
    end

    local connPos = RunService.Heartbeat:Connect(function()
        if freezeAtivo and freezeToken == meuToken and rootPart and rootPart.Parent then
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
    table.insert(freezeConexoes, connPos)

    task.delay(duracao, function()
        if freezeToken ~= meuToken then return end
        freezeAtivo = false
        limparConexoesFreeze()
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
                humanoid.JumpHeight = 7.2
            end)
        end
        log("🥶 Freeze terminado")
    end)

    log("🥶 Freeze iniciado por", duracao, "s")
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SistemaCompleto"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = player:WaitForChild("PlayerGui")

local fadeFrame = Instance.new("Frame")
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = CONFIG.CorFade
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel = 0
fadeFrame.ZIndex = 1000
fadeFrame.Parent = screenGui

local vinhetaFrame = Instance.new("ImageLabel")
vinhetaFrame.Size = UDim2.new(1, 0, 1, 0)
vinhetaFrame.BackgroundTransparency = 1
vinhetaFrame.Image = "rbxassetid://5577728657"
vinhetaFrame.ImageColor3 = Color3.fromRGB(255, 0, 0)
vinhetaFrame.ImageTransparency = 1
vinhetaFrame.ZIndex = 1005
vinhetaFrame.Parent = screenGui

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 1001
flashFrame.Parent = screenGui

local feixeFrame = Instance.new("Frame")
feixeFrame.Size = UDim2.new(0, 4, 0, 0)
feixeFrame.Position = UDim2.new(0.5, -2, 0.5, 0)
feixeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
feixeFrame.BackgroundColor3 = Color3.fromRGB(200, 255, 220)
feixeFrame.BackgroundTransparency = 1
feixeFrame.BorderSizePixel = 0
feixeFrame.ZIndex = 1002
feixeFrame.Parent = screenGui

local feixeGradient = Instance.new("UIGradient")
feixeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1),
})
feixeGradient.Parent = feixeFrame

local scanlinesFrame = Instance.new("Frame")
scanlinesFrame.Size = UDim2.new(1, 0, 1, 0)
scanlinesFrame.BackgroundTransparency = 1
scanlinesFrame.BorderSizePixel = 0
scanlinesFrame.ZIndex = 999
scanlinesFrame.Parent = screenGui

local scanlineCount = 80
local scanlines = {}
for i = 1, scanlineCount do
    local linha = Instance.new("Frame")
    linha.Size = UDim2.new(1, 0, 0, 2)
    linha.Position = UDim2.new(0, 0, (i - 1) / scanlineCount, 0)
    linha.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    linha.BackgroundTransparency = 1
    linha.BorderSizePixel = 0
    linha.ZIndex = 999
    linha.Parent = scanlinesFrame
    table.insert(scanlines, linha)
end

local rgbContainer = Instance.new("Frame")
rgbContainer.Size = UDim2.new(1, 0, 1, 0)
rgbContainer.BackgroundTransparency = 1
rgbContainer.BorderSizePixel = 0
rgbContainer.ZIndex = 998
rgbContainer.Parent = screenGui

local rgbR = Instance.new("Frame")
rgbR.Size = UDim2.new(1, 0, 1, 0)
rgbR.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
rgbR.BackgroundTransparency = 1
rgbR.BorderSizePixel = 0
rgbR.ZIndex = 998
rgbR.Parent = rgbContainer

local rgbG = Instance.new("Frame")
rgbG.Size = UDim2.new(1, 0, 1, 0)
rgbG.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
rgbG.BackgroundTransparency = 1
rgbG.BorderSizePixel = 0
rgbG.ZIndex = 998
rgbG.Parent = rgbContainer

local rgbB = Instance.new("Frame")
rgbB.Size = UDim2.new(1, 0, 1, 0)
rgbB.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
rgbB.BackgroundTransparency = 1
rgbB.BorderSizePixel = 0
rgbB.ZIndex = 998
rgbB.Parent = rgbContainer

local portalFrame = Instance.new("Frame")
portalFrame.Size = UDim2.new(0, 0, 0, 0)
portalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
portalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
portalFrame.BackgroundColor3 = CONFIG.RespawnPortalCor
portalFrame.BackgroundTransparency = 0.3
portalFrame.BorderSizePixel = 0
portalFrame.ZIndex = 1003
portalFrame.Parent = screenGui

local portalCorner = Instance.new("UICorner")
portalCorner.CornerRadius = UDim.new(1, 0)
portalCorner.Parent = portalFrame

local portalStroke = Instance.new("UIStroke")
portalStroke.Color = Color3.fromRGB(200, 255, 220)
portalStroke.Thickness = 5
portalStroke.Transparency = 0.2
portalStroke.Parent = portalFrame

local portalAnelInterno = Instance.new("Frame")
portalAnelInterno.Size = UDim2.new(0, 0, 0, 0)
portalAnelInterno.Position = UDim2.new(0.5, 0, 0.5, 0)
portalAnelInterno.AnchorPoint = Vector2.new(0.5, 0.5)
portalAnelInterno.BackgroundTransparency = 1
portalAnelInterno.BorderSizePixel = 0
portalAnelInterno.ZIndex = 1002
portalAnelInterno.Parent = screenGui

local portalAnelInternoCorner = Instance.new("UICorner")
portalAnelInternoCorner.CornerRadius = UDim.new(1, 0)
portalAnelInternoCorner.Parent = portalAnelInterno

local portalAnelInternoStroke = Instance.new("UIStroke")
portalAnelInternoStroke.Color = Color3.fromRGB(150, 255, 180)
portalAnelInternoStroke.Thickness = 3
portalAnelInternoStroke.Transparency = 1
portalAnelInternoStroke.Parent = portalAnelInterno

local anelEnergia = Instance.new("Frame")
anelEnergia.Size = UDim2.new(0, 0, 0, 0)
anelEnergia.Position = UDim2.new(0.5, 0, 0.5, 0)
anelEnergia.AnchorPoint = Vector2.new(0.5, 0.5)
anelEnergia.BackgroundTransparency = 1
anelEnergia.BorderSizePixel = 0
anelEnergia.ZIndex = 1004
anelEnergia.Parent = screenGui

local anelEnergiaCorner = Instance.new("UICorner")
anelEnergiaCorner.CornerRadius = UDim.new(1, 0)
anelEnergiaCorner.Parent = anelEnergia

local anelEnergiaStroke = Instance.new("UIStroke")
anelEnergiaStroke.Color = CONFIG.RespawnPortalCor
anelEnergiaStroke.Thickness = 6
anelEnergiaStroke.Transparency = 1
anelEnergiaStroke.Parent = anelEnergia

local fragmentosContainer = Instance.new("Frame")
fragmentosContainer.Size = UDim2.new(1, 0, 1, 0)
fragmentosContainer.BackgroundTransparency = 1
fragmentosContainer.ZIndex = 997
fragmentosContainer.Parent = screenGui

local glitchContainer = Instance.new("Frame")
glitchContainer.Size = UDim2.new(1, 0, 1, 0)
glitchContainer.BackgroundTransparency = 1
glitchContainer.ZIndex = 1006
glitchContainer.Parent = screenGui

local explosaoLuz = Instance.new("Frame")
explosaoLuz.Size = UDim2.new(0, 0, 0, 0)
explosaoLuz.Position = UDim2.new(0.5, 0, 0.5, 0)
explosaoLuz.AnchorPoint = Vector2.new(0.5, 0.5)
explosaoLuz.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
explosaoLuz.BackgroundTransparency = 1
explosaoLuz.BorderSizePixel = 0
explosaoLuz.ZIndex = 1007
explosaoLuz.Parent = screenGui

local explosaoLuzCorner = Instance.new("UICorner")
explosaoLuzCorner.CornerRadius = UDim.new(1, 0)
explosaoLuzCorner.Parent = explosaoLuz

local ondasContainer = Instance.new("Frame")
ondasContainer.Size = UDim2.new(1, 0, 1, 0)
ondasContainer.BackgroundTransparency = 1
ondasContainer.ZIndex = 1003
ondasContainer.Parent = screenGui

local ecoContainer = Instance.new("Frame")
ecoContainer.Size = UDim2.new(1, 0, 1, 0)
ecoContainer.BackgroundTransparency = 1
ecoContainer.ZIndex = 997
ecoContainer.Parent = screenGui

local particulasContainer = Instance.new("Frame")
particulasContainer.Size = UDim2.new(1, 0, 1, 0)
particulasContainer.BackgroundTransparency = 1
particulasContainer.ZIndex = 1005
particulasContainer.Parent = screenGui

local function flashTela(cor, duracao)
    pcall(function()
        flashFrame.BackgroundColor3 = cor
        flashFrame.BackgroundTransparency = 0
        TweenService:Create(
            flashFrame,
            TweenInfo.new(duracao or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        ):Play()
    end)
end

local function vinhetaTela(cor, duracao, intensidade)
    task.spawn(function()
        pcall(function()
            vinhetaFrame.ImageColor3 = cor
            vinhetaFrame.ImageTransparency = 1
            local tween = TweenService:Create(
                vinhetaFrame,
                TweenInfo.new((duracao or 0.4) * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { ImageTransparency = 1 - (intensidade or 0.8) }
            )
            tween:Play()
            tween.Completed:Wait()
            task.wait(0.15)
            TweenService:Create(
                vinhetaFrame,
                TweenInfo.new((duracao or 0.4) * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { ImageTransparency = 1 }
            ):Play()
        end)
    end)
end

local function cameraShake(intensidade, duracao, rotacional)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local inicio = agora()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if agora() - inicio >= duracao then
            conn:Disconnect()
            return
        end
        local progresso = 1 - ((agora() - inicio) / duracao)
        local sx = (math.random() - 0.5) * 2 * intensidade * progresso
        local sy = (math.random() - 0.5) * 2 * intensidade * progresso

        if rotacional then
            local angulo = (math.random() - 0.5) * math.rad(3) * intensidade * progresso
            camera.CFrame = camera.CFrame * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, angulo)
        else
            camera.CFrame = camera.CFrame * CFrame.new(sx, sy, 0)
        end
    end)
end

local function efeitoRGBSplit(duracao, deslocamento, pulsos)
    pulsos = pulsos or 1
    task.spawn(function()
        for _ = 1, pulsos do
            task.spawn(function()
                rgbR.BackgroundTransparency = 0.6
                rgbG.BackgroundTransparency = 0.6
                rgbB.BackgroundTransparency = 0.6

                local inicio = agora()
                local dur = duracao / pulsos
                local conn
                conn = RunService.RenderStepped:Connect(function()
                    local p = (agora() - inicio) / dur
                    if p >= 1 then
                        conn:Disconnect()
                        rgbR.BackgroundTransparency = 1
                        rgbG.BackgroundTransparency = 1
                        rgbB.BackgroundTransparency = 1
                        return
                    end
                    local forca = (1 + p) * (1 - p * 0.5)
                    rgbR.Position = UDim2.new(0, -deslocamento * forca, 0, 0)
                    rgbB.Position = UDim2.new(0, deslocamento * forca, 0, 0)
                    rgbR.BackgroundTransparency = 0.6 + (0.4 * p)
                    rgbG.BackgroundTransparency = 0.6 + (0.4 * p)
                    rgbB.BackgroundTransparency = 0.6 + (0.4 * p)
                end)
            end)
            task.wait(0.08)
        end
    end)
end

local function efeitoScanlines(duracao, velocidade)
    velocidade = velocidade or 2
    task.spawn(function()
        for _, linha in ipairs(scanlines) do
            linha.BackgroundTransparency = 0.7
        end
        local inicio = agora()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local p = (agora() - inicio) / duracao
            if p >= 1 then
                conn:Disconnect()
                for _, linha in ipairs(scanlines) do
                    linha.BackgroundTransparency = 1
                end
                return
            end
            local offset = p * velocidade
            for i, linha in ipairs(scanlines) do
                local posBase = (i - 1) / scanlineCount
                linha.Position = UDim2.new(0, 0, (posBase + offset) % 1, 0)
                linha.BackgroundTransparency = 0.7 + (0.3 * p)
            end
        end)
    end)
end

local function efeitoOndas(quantidade, duracao, cor)
    task.spawn(function()
        for _ = 1, quantidade do
            task.spawn(function()
                local ondaFrame = Instance.new("Frame")
                ondaFrame.Size = UDim2.new(0, 0, 0, 0)
                ondaFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                ondaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                ondaFrame.BackgroundTransparency = 1
                ondaFrame.BorderSizePixel = 0
                ondaFrame.ZIndex = 1003
                ondaFrame.Parent = ondasContainer

                local ondaCorner = Instance.new("UICorner")
                ondaCorner.CornerRadius = UDim.new(1, 0)
                ondaCorner.Parent = ondaFrame

                local ondaStroke = Instance.new("UIStroke")
                ondaStroke.Color = cor
                ondaStroke.Thickness = 5
                ondaStroke.Transparency = 0.3
                ondaStroke.Parent = ondaFrame

                TweenService:Create(ondaFrame, TweenInfo.new(duracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(3, 0, 3, 0)
                }):Play()
                TweenService:Create(ondaStroke, TweenInfo.new(duracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Transparency = 1,
                    Thickness = 1
                }):Play()

                task.wait(duracao)
                if ondaFrame and ondaFrame.Parent then ondaFrame:Destroy() end
            end)
            task.wait(0.08)
        end
    end)
end

local function efeitoEco(cor, duracao)
    task.spawn(function()
        local eco = Instance.new("Frame")
        eco.Size = UDim2.new(1, 0, 1, 0)
        eco.BackgroundColor3 = cor
        eco.BackgroundTransparency = 0.75
        eco.BorderSizePixel = 0
        eco.ZIndex = 997
        eco.Parent = ecoContainer

        local tween = TweenService:Create(eco, TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        if eco and eco.Parent then eco:Destroy() end
    end)
end

local function efeitoGlitchBlocks(duracao, quantidade, corBase)
    corBase = corBase or Color3.fromRGB(0, 255, 255)
    local h, s, v = corBase:ToHSV()
    local cores = {
        corBase,
        Color3.fromHSV(h, math.clamp(s * 0.7, 0, 1), math.clamp(v * 1.2, 0, 1)),
        Color3.fromHSV((h + 0.05) % 1, math.clamp(s * 0.5, 0, 1), math.clamp(v * 0.9, 0, 1)),
    }
    task.spawn(function()
        local inicio = agora()
        while agora() - inicio < duracao do
            for _ = 1, quantidade do
                local bloco = Instance.new("Frame")
                bloco.Size = UDim2.new(math.random(5, 25) / 100, 0, math.random(1, 3) / 100, 0)
                bloco.Position = UDim2.new(math.random() * 0.9, 0, math.random() * 0.95, 0)
                bloco.BackgroundColor3 = cores[math.random(1, #cores)]
                bloco.BackgroundTransparency = math.random(0.2, 0.6)
                bloco.BorderSizePixel = 0
                bloco.ZIndex = 1006
                bloco.Parent = glitchContainer
                task.spawn(function()
                    task.wait(math.random(1, 5) / 100)
                    if bloco and bloco.Parent then bloco:Destroy() end
                end)
            end
            task.wait(0.05)
        end
    end)
end

local function efeitoFeixeLuz(cor, duracao)
    task.spawn(function()
        feixeFrame.BackgroundColor3 = cor or Color3.fromRGB(200, 255, 220)
        feixeFrame.Size = UDim2.new(0, 4, 0, 0)
        feixeFrame.BackgroundTransparency = 0.3
        TweenService:Create(feixeFrame, TweenInfo.new(duracao * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 120, 0, 0),
            BackgroundTransparency = 0.5
        }):Play()
        task.wait(duracao * 0.6)
        TweenService:Create(feixeFrame, TweenInfo.new(duracao * 0.4, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 500, 0, 0)
        }):Play()
    end)
end

local function efeitoParticulasTela(quantidade, cor)
    task.spawn(function()
        for _ = 1, quantidade do
            task.spawn(function()
                local part = Instance.new("Frame")
                part.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
                part.Position = UDim2.new(0.5, 0, 0.5, 0)
                part.AnchorPoint = Vector2.new(0.5, 0.5)
                part.BackgroundColor3 = cor or Color3.fromRGB(0, 255, 100)
                part.BackgroundTransparency = math.random(0.1, 0.4)
                part.BorderSizePixel = 0
                part.ZIndex = 1005
                part.Parent = particulasContainer
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = part
                local angulo = math.random() * math.pi * 2
                local distancia = math.random(80, 150) / 100
                local tween = TweenService:Create(part, TweenInfo.new(math.random(40, 70) / 100, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5 + math.cos(angulo) * distancia, 0, 0.5 + math.sin(angulo) * distancia, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 0, 0)
                })
                tween:Play()
                tween.Completed:Wait()
                if part and part.Parent then part:Destroy() end
            end)
        end
    end)
end

local function obterMorphDesc()
    if morphDescCache then return morphDescCache end
    local okId, id = pcall(function() return Players:GetUserIdFromNameAsync(CONFIG.MorphUsername) end)
    if not okId or not id then return nil end

    local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(id) end)
    if not okDesc or not desc then return nil end

    morphDescCache = desc
    return desc
end

local function aplicarMorph()
    if not CONFIG.MorphAtivo then return false end

    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        log("🚫 Morph ignorado: jogo é R15")
        return false
    end

    local desc = obterMorphDesc()
    if not desc then return false end

    local okModel, generatedModel = pcall(function()
        return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
    end)
    if not okModel or not generatedModel then return false end

    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic")
            or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            pcall(function() item:Destroy() end)
        end
    end

    for _, targetItem in ipairs(generatedModel:GetChildren()) do
        local existing = character:FindFirstChild(targetItem.Name)
        if existing and existing:IsA("BasePart") and existing.Name ~= "HumanoidRootPart" then
            pcall(function() existing.Color = targetItem.Color end)
        end
    end

    local targetHead = generatedModel:FindFirstChild("Head")
    local currentHead = character:FindFirstChild("Head")
    if targetHead and currentHead then
        local oldFace = currentHead:FindFirstChildOfClass("Decal")
        if oldFace then oldFace:Destroy() end
        local newFace = targetHead:FindFirstChildOfClass("Decal")
        if newFace then
            newFace:Clone().Parent = currentHead
        else
            local defaultFace = Instance.new("Decal")
            defaultFace.Name = "face"
            defaultFace.Texture = "rbxasset://textures/face.png"
            defaultFace.Parent = currentHead
        end
        local oldMesh = currentHead:FindFirstChildOfClass("SpecialMesh")
        if oldMesh then oldMesh:Destroy() end
        local newMesh = targetHead:FindFirstChildOfClass("SpecialMesh")
        if newMesh then newMesh:Clone().Parent = currentHead end
    end

    for _, item in ipairs(generatedModel:GetChildren()) do
        if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors")
            or item:IsA("CharacterMesh") then
            pcall(function() item:Clone().Parent = character end)
        elseif item:IsA("Accessory") then
            local cloned = item:Clone()
            local handle = cloned:FindFirstChild("Handle")
            if handle then
                local attachment = handle:FindFirstChildOfClass("Attachment")
                if attachment then
                    local targetAttachment = character:FindFirstChild(attachment.Name, true)
                    if targetAttachment then
                        handle.CFrame = targetAttachment.WorldCFrame
                        local weld = Instance.new("Weld")
                        weld.Name = "AccessoryWeld"
                        weld.Part0 = handle
                        weld.Part1 = targetAttachment.Parent
                        weld.C0 = attachment.CFrame
                        weld.C1 = targetAttachment.CFrame
                        weld.Parent = handle
                    end
                end
            end
            pcall(function() cloned.Parent = character end)
        end
    end

    generatedModel:Destroy()
    return true
end

local function pararAudiosRespawn()
    for _, sound in ipairs(audiosRespawnAtivos) do
        pcall(function()
            if sound and sound.Parent then
                sound:Stop()
                sound:Destroy()
            end
        end)
    end
    audiosRespawnAtivos = {}
end

local function tocarAudioIndividual(id, volume, pitchMin, pitchMax)
    if not id or id == "" then return nil end
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume or 1
    sound.PlaybackSpeed = math.random(pitchMin * 100, pitchMax * 100) / 100
    sound.Parent = SoundService
    pcall(function() sound:Play() end)
    sound.Ended:Connect(function()
        if sound and sound.Parent then sound:Destroy() end
    end)
    task.delay(15, function()
        if sound and sound.Parent then sound:Destroy() end
    end)
    return sound
end

local function tocarAudioMorte()
    local sound = tocarAudioIndividual(
        CONFIG.AudioMorte,
        CONFIG.VolumeAudioMorte,
        CONFIG.PitchMinMorte,
        CONFIG.PitchMaxMorte
    )
    if sound then log("🔊 Áudio de morte tocando") end
end

local function tocarAudiosRespawn()
    if audioTocadoNesteCiclo then return end
    pararAudiosRespawn()
    audioTocadoNesteCiclo = true
    local s1 = tocarAudioIndividual(CONFIG.AudioRespawn, CONFIG.VolumeAudioRespawn, CONFIG.PitchMinRespawn, CONFIG.PitchMaxRespawn)
    if s1 then table.insert(audiosRespawnAtivos, s1) end
    local s2 = tocarAudioIndividual(CONFIG.AudioRespawn2, CONFIG.VolumeAudioRespawn2, CONFIG.PitchMinRespawn, CONFIG.PitchMaxRespawn)
    if s2 then table.insert(audiosRespawnAtivos, s2) end
end

local function efeitoMorte()
    if CONFIG.MorteFlashCiano then
        task.spawn(function() flashTela(CONFIG.MorteCorCiano, CONFIG.MorteFlashDuracao) end)
    end
    if CONFIG.MorteRGBSplit then
        task.spawn(function() efeitoRGBSplit(CONFIG.MorteRGBDuracao, CONFIG.MorteRGBDeslocamento, CONFIG.MorteRGBPulsos) end)
    end
    if CONFIG.MorteScanlines then
        task.spawn(function() efeitoScanlines(CONFIG.MorteScanlinesDuracao, CONFIG.MorteScanlinesVelocidade) end)
    end
    if CONFIG.MorteVinhetaVermelha then
        task.spawn(function() vinhetaTela(Color3.fromRGB(255, 0, 0), CONFIG.MorteVinhetaDuracao, CONFIG.MorteVinhetaIntensidade) end)
    end
    if CONFIG.MorteFade then
        task.spawn(function()
            task.wait(0.15)
            TweenService:Create(
                fadeFrame,
                TweenInfo.new(CONFIG.MorteFadeDuracao, Enum.EasingStyle.Quad),
                { BackgroundTransparency = CONFIG.TransparenciaFade }
            ):Play()
        end)
    end
    if CONFIG.MorteCameraShake then
        task.spawn(function()
            cameraShake(CONFIG.MorteShakeIntensidade, CONFIG.MorteShakeDuracao, CONFIG.MorteShakeRotacional)
        end)
    end
    if CONFIG.MorteParticulas then
        task.spawn(function()
            local character = player.Character
            if not character then return end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local attachment = Instance.new("Attachment")
            attachment.Parent = rootPart
            local emitter = Instance.new("ParticleEmitter")
            emitter.Texture = "rbxassetid://243660364"
            emitter.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
            })
            emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0) })
            emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
            emitter.Lifetime = NumberRange.new(0.6, 1.5)
            emitter.Speed = NumberRange.new(20, 40)
            emitter.SpreadAngle = Vector2.new(180, 180)
            emitter.Rotation = NumberRange.new(-180, 180)
            emitter.RotSpeed = NumberRange.new(-360, 360)
            emitter.Rate = 0
            emitter.Parent = attachment
            pcall(function() emitter:Emit(CONFIG.MorteParticulasQuantidade) end)
            task.delay(2, function()
                if attachment and attachment.Parent then attachment:Destroy() end
            end)
        end)
    end
    if CONFIG.MorteGlitchBlocks then
        task.spawn(function() efeitoGlitchBlocks(CONFIG.MorteGlitchDuracao, CONFIG.MorteGlitchQuantidade, CONFIG.MorteCorCiano) end)
    end
    if CONFIG.MorteBlur then
        task.spawn(function()
            criarBlur(CONFIG.MorteBlurTamanho)
            task.wait(0.15)
            removerBlur(CONFIG.MorteBlurDuracao)
        end)
    end
    if CONFIG.MorteExplosaoLuz then
        task.spawn(function()
            explosaoLuz.Size = UDim2.new(0, 0, 0, 0)
            explosaoLuz.BackgroundTransparency = 0.2
            explosaoLuz.BackgroundColor3 = CONFIG.MorteCorCiano
            TweenService:Create(explosaoLuz, TweenInfo.new(CONFIG.MorteExplosaoDuracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(3, 0, 3, 0), BackgroundTransparency = 1 }):Play()
            task.wait(CONFIG.MorteExplosaoDuracao + 0.1)
            explosaoLuz.Size = UDim2.new(0, 0, 0, 0)
        end)
    end
end

local function efeitoRespawn()
    fadeFrame.BackgroundColor3 = CONFIG.CorFade
    fadeFrame.BackgroundTransparency = CONFIG.TransparenciaFade

    if CONFIG.RespawnFragmentos then
        task.spawn(function()
            for _ = 1, CONFIG.RespawnFragmentosQuantidade do
                local frag = Instance.new("Frame")
                frag.Size = UDim2.new(0, math.random(10, 30), 0, math.random(10, 30))
                frag.AnchorPoint = Vector2.new(0.5, 0.5)
                frag.BackgroundColor3 = CONFIG.RespawnPortalCor
                frag.BackgroundTransparency = math.random(0.1, 0.4)
                frag.BorderSizePixel = 0
                frag.Rotation = math.random(0, 360)
                frag.ZIndex = 1004
                frag.Parent = fragmentosContainer
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(math.random(0, 1), 0)
                corner.Parent = frag
                local angulo = math.random() * math.pi * 2
                local distancia = 1.5
                frag.Position = UDim2.new(0.5 + math.cos(angulo) * distancia, 0, 0.5 + math.sin(angulo) * distancia, 0)
                task.spawn(function()
                    local props = { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }
                    if CONFIG.RespawnFragmentosRotacao then props.Rotation = frag.Rotation + math.random(-720, 720) end
                    local tween = TweenService:Create(frag, TweenInfo.new(CONFIG.RespawnFragmentosDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.In), props)
                    tween:Play()
                    tween.Completed:Wait()
                    if frag and frag.Parent then frag:Destroy() end
                end)
            end
        end)
    end

    if CONFIG.RespawnOndasChoque then
        task.spawn(function() efeitoOndas(CONFIG.RespawnOndasQuantidade, CONFIG.RespawnOndasDuracao, CONFIG.RespawnPortalCor) end)
    end

    if CONFIG.RespawnAnelEnergia then
        task.spawn(function()
            anelEnergia.Size = UDim2.new(0, 0, 0, 0)
            anelEnergiaStroke.Transparency = 0.2
            TweenService:Create(anelEnergia, TweenInfo.new(CONFIG.RespawnAnelDuracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(3, 0, 3, 0) }):Play()
            TweenService:Create(anelEnergiaStroke, TweenInfo.new(CONFIG.RespawnAnelDuracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Transparency = 1, Thickness = 1 }):Play()
            task.wait(CONFIG.RespawnAnelDuracao + 0.1)
            anelEnergia.Size = UDim2.new(0, 0, 0, 0)
        end)
    end

    if CONFIG.RespawnFlashBranco then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.7)
            flashTela(Color3.fromRGB(255, 255, 255), CONFIG.RespawnFlashDuracao)
            TweenService:Create(fadeFrame, TweenInfo.new(CONFIG.RespawnFadeOutDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
        end)
    else
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.5)
            TweenService:Create(fadeFrame, TweenInfo.new(CONFIG.RespawnFadeOutDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
        end)
    end

    if CONFIG.RespawnFeixeLuz then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.5)
            efeitoFeixeLuz(CONFIG.RespawnPortalCor, CONFIG.RespawnFeixeDuracao)
        end)
    end

    if CONFIG.RespawnPortalVerde then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.6)
            portalFrame.Size = UDim2.new(0, 0, 0, 0)
            portalFrame.BackgroundTransparency = 0.2
            portalStroke.Transparency = 0.2
            TweenService:Create(portalFrame, TweenInfo.new(CONFIG.RespawnPortalDuracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(2, 0, 2, 0) }):Play()
            if CONFIG.RespawnPortalAnelInterno then
                task.spawn(function()
                    portalAnelInterno.Size = UDim2.new(0, 0, 0, 0)
                    portalAnelInternoStroke.Transparency = 0.3
                    TweenService:Create(portalAnelInterno, TweenInfo.new(CONFIG.RespawnPortalDuracao * 0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1.5, 0, 1.5, 0) }):Play()
                    TweenService:Create(portalAnelInternoStroke, TweenInfo.new(CONFIG.RespawnPortalDuracao * 0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Transparency = 1, Thickness = 1 }):Play()
                end)
            end
            task.wait(CONFIG.RespawnPortalDuracao * 0.7)
            TweenService:Create(portalFrame, TweenInfo.new(CONFIG.RespawnPortalDuracao * 0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(portalStroke, TweenInfo.new(CONFIG.RespawnPortalDuracao * 0.5, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
            task.wait(CONFIG.RespawnPortalDuracao)
            portalFrame.Size = UDim2.new(0, 0, 0, 0)
        end)
    end

    if CONFIG.RespawnExplosaoParticulas then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.7)
            efeitoParticulasTela(CONFIG.RespawnParticulasQuantidade, CONFIG.RespawnPortalCor)
        end)
    end

    if CONFIG.RespawnRastroEnergia then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.5)
            for _ = 1, 8 do
                task.spawn(function()
                    local rastro = Instance.new("Frame")
                    rastro.Size = UDim2.new(0, 8, 0, 8)
                    rastro.Position = UDim2.new(0.5, math.random(-15, 15), 0.6, 0)
                    rastro.AnchorPoint = Vector2.new(0.5, 0.5)
                    rastro.BackgroundColor3 = Color3.fromRGB(150, 255, 180)
                    rastro.BackgroundTransparency = 0.2
                    rastro.BorderSizePixel = 0
                    rastro.ZIndex = 1004
                    rastro.Parent = fragmentosContainer
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = rastro
                    local tween = TweenService:Create(rastro, TweenInfo.new(CONFIG.RespawnRastroDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, math.random(-30, 30), 0.3, 0), BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 20) })
                    tween:Play()
                    tween.Completed:Wait()
                    if rastro and rastro.Parent then rastro:Destroy() end
                end)
                task.wait(0.05)
            end
        end)
    end

    if CONFIG.RespawnEcoDimensional then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.5)
            efeitoEco(CONFIG.RespawnPortalCor, CONFIG.RespawnEcoDuracao)
        end)
    end

    if CONFIG.RespawnScanlines then
        task.spawn(function() efeitoScanlines(CONFIG.RespawnScanlinesDuracao, 2) end)
    end

    if CONFIG.RespawnCameraShake then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.7)
            cameraShake(CONFIG.RespawnShakeIntensidade, CONFIG.RespawnShakeDuracao, false)
        end)
    end

    if CONFIG.RespawnBlur then
        task.spawn(function()
            task.wait(CONFIG.RespawnFragmentosDuracao * 0.6)
            criarBlur(CONFIG.RespawnBlurTamanho)
            removerBlur(CONFIG.RespawnBlurDuracao)
        end)
    end
end

local function efeitoPosRespawn()
    if CONFIG.PosRespawnChromaticEcho then
        task.spawn(function()
            rgbR.BackgroundTransparency = 0.85
            rgbB.BackgroundTransparency = 0.85
            rgbR.Position = UDim2.new(0, -3, 0, 0)
            rgbB.Position = UDim2.new(0, 3, 0, 0)
            TweenService:Create(rgbR, TweenInfo.new(CONFIG.PosRespawnDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0) }):Play()
            TweenService:Create(rgbB, TweenInfo.new(CONFIG.PosRespawnDuracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0) }):Play()
        end)
    end
    if CONFIG.PosRespawnColorCorrection then
        task.spawn(function()
            criarColorCorrection(CONFIG.PosRespawnSaturacao, CONFIG.PosRespawnContraste, 0.3)
            task.wait(0.3)
            removerColorCorrection(0.5)
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if not salvandoAtivo then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    if humanoid.Health <= 0 then return end

    local agoraT = agora()
    local cframeAtual = rootPart.CFrame

    if agoraT - tempoUltimoSalvamento < 1 and ultimoCFrameSalvo
        and (cframeAtual.Position - ultimoCFrameSalvo.Position).Magnitude <= 5 then
        return
    end

    cframeSalvo = cframeAtual

    if localInvisivel and localInvisivel.Parent then localInvisivel:Destroy() end
    localInvisivel = Instance.new("Part")
    localInvisivel.Name = "LocalInvisivel_Respawn"
    localInvisivel.Size = Vector3.new(1, 1, 1)
    localInvisivel.CFrame = cframeAtual
    localInvisivel.Anchored = true
    localInvisivel.CanCollide = false
    localInvisivel.CanTouch = false
    localInvisivel.CanQuery = false
    localInvisivel.Transparency = 1
    localInvisivel.Massless = true
    localInvisivel.Parent = workspace

    ultimoCFrameSalvo = cframeAtual
    tempoUltimoSalvamento = agoraT
end)

local function limparConexoes()
    for _, conn in ipairs(conexoesCharacter) do
        pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
    end
    conexoesCharacter = {}
end

local function configurarCharacter(character)
    limparConexoes()
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    local conn = humanoid.Died:Connect(function()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local cf = rootPart.CFrame
            if cf.Position.Y > -100 then
                cframeSalvo = cf
                if localInvisivel and localInvisivel.Parent then localInvisivel:Destroy() end
                localInvisivel = Instance.new("Part")
                localInvisivel.Name = "LocalInvisivel_Respawn"
                localInvisivel.Size = Vector3.new(1, 1, 1)
                localInvisivel.CFrame = cf
                localInvisivel.Anchored = true
                localInvisivel.CanCollide = false
                localInvisivel.CanTouch = false
                localInvisivel.CanQuery = false
                localInvisivel.Transparency = 1
                localInvisivel.Massless = true
                localInvisivel.Parent = workspace
            end
        end
        salvandoAtivo = false
        task.spawn(efeitoMorte)
        if CONFIG.TocarAudioMorte then
            task.spawn(tocarAudioMorte)
        end
    end)
    table.insert(conexoesCharacter, conn)
end

player.CharacterAdded:Connect(function(character)
    salvandoAtivo = false
    cicloAtual = cicloAtual + 1
    audioTocadoNesteCiclo = false
    pararAudiosRespawn()

    task.spawn(function() iniciarFreeze(character, CONFIG.FreezeDuracao) end)

    task.spawn(function()
        if CONFIG.DelayAudioRespawn > 0 then task.wait(CONFIG.DelayAudioRespawn) end
        tocarAudiosRespawn()
    end)

    local humanoid = character:WaitForChild("Humanoid", 10)
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)

    if not humanoid or not rootPart then
        salvandoAtivo = true
        return
    end

    if humanoid.Health <= 0 then humanoid.HealthChanged:Wait() end
    task.wait(0.15)

    if cframeSalvo then
        local posFinal = cframeSalvo.Position + Vector3.new(0, CONFIG.OffsetY, 0)
        local rotacaoFinal = (cframeSalvo - cframeSalvo.Position)
        rootPart.CFrame = CFrame.new(posFinal) * rotacaoFinal

        task.wait(0.2)
        if localInvisivel and localInvisivel.Parent then localInvisivel:Destroy() end
        localInvisivel = nil
        cframeSalvo = nil
        ultimoCFrameSalvo = nil
        tempoUltimoSalvamento = agora()
    end

    task.spawn(efeitoRespawn)
    task.spawn(efeitoPosRespawn)

    task.spawn(function()
        task.wait(0.3)
        aplicarMorph()
    end)

    salvandoAtivo = true
    configurarCharacter(character)
end)

if CONFIG.PreCarregarAudio then
    task.spawn(function()
        preCarregarAudio(CONFIG.AudioMorte)
        preCarregarAudio(CONFIG.AudioRespawn)
        preCarregarAudio(CONFIG.AudioRespawn2)
    end)
end

task.spawn(function() obterMorphDesc() end)
task.spawn(function() detectarRigType() end)

if player.Character then
    task.spawn(function()
        player.Character:WaitForChild("Humanoid", 10)
        task.wait(0.5)
        aplicarMorph()
    end)
    configurarCharacter(player.Character)

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        cframeSalvo = rootPart.CFrame
    end
end