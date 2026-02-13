-- Script para ser colocado no ServerScriptService ou na bomba

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Caminho para os itens que devem ser destruídos
local ITEMS_FOLDER = Workspace.Mapa2.Halloween
local RESPAWN_TIME = 300 -- 5 minutos em segundos

-- Variável de controle
local itensForamDestruidos = false
local estruturaOriginal = nil

-- Função para salvar a estrutura original APENAS UMA VEZ
local function salvarEstruturaOriginal()
    if estruturaOriginal then return estruturaOriginal end
    
    local estrutura = {}
    
    for _, item in ipairs(ITEMS_FOLDER:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("Model") then
            table.insert(estrutura, {
                Instance = item,
                Parent = item.Parent,
                Position = item:IsA("BasePart") and item.Position or nil,
                CFrame = item:IsA("BasePart") and item.CFrame or nil,
                Nome = item.Name,
                Classe = item.ClassName
            })
        end
    end
    
    estruturaOriginal = estrutura
    return estruturaOriginal
end

-- Salvar estrutura original dos itens (APENAS UMA VEZ)
salvarEstruturaOriginal()

-- Função para verificar se os itens ainda existem
local function verificarItensExistem()
    for _, itemData in ipairs(estruturaOriginal) do
        -- Verificar se o item original ainda existe
        if itemData.Instance and itemData.Instance.Parent then
            return true -- Ainda existe pelo menos um item
        end
    end
    return false -- Nenhum item existe mais
end

-- Função para destruir os itens
local function destroyItems()
    -- Verificar se já foram destruídos
    if itensForamDestruidos then
        print("Itens já foram destruídos! Aguardando respawn...")
        return
    end
    
    -- Verificar se realmente existem itens para destruir
    if not verificarItensExistem() then
        print("Não há itens para destruir!")
        return
    end
    
    local itensDestruidos = 0
    
    for _, itemData in ipairs(estruturaOriginal) do
        local item = itemData.Instance
        
        if item and item.Parent then
            if item:IsA("BasePart") then
                -- Criar explosão visual
                local explosion = Instance.new("Explosion")
                explosion.Position = item.Position
                explosion.BlastPressure = 0
                explosion.BlastRadius = 5
                explosion.Parent = Workspace
                
                item:Destroy()
                itensDestruidos = itensDestruidos + 1
                
            elseif item:IsA("Model") then
                -- Criar explosões para todas as partes do modelo
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local explosion = Instance.new("Explosion")
                        explosion.Position = part.Position
                        explosion.BlastPressure = 0
                        explosion.BlastRadius = 5
                        explosion.Parent = Workspace
                    end
                end
                item:Destroy()
                itensDestruidos = itensDestruidos + 1
            end
        end
    end
    
    if itensDestruidos > 0 then
        itensForamDestruidos = true
        print(itensDestruidos .. " itens foram destruídos!")
        
        -- Iniciar contagem para respawn
        task.spawn(function()
            print("Respawn em " .. RESPAWN_TIME .. " segundos...")
            task.wait(RESPAWN_TIME)
            respawnItems()
        end)
    else
        print("Nenhum item foi destruído!")
    end
end

-- Função para renascer os itens
local function respawnItems()
    -- Verificar se realmente precisa respawnar
    if not itensForamDestruidos then
        print("Não há necessidade de respawn - itens ainda existem!")
        return
    end
    
    -- Verificar se já existem itens (por segurança)
    if verificarItensExistem() then
        print("Itens já existem! Limpando...")
        itensForamDestruidos = false
        return
    end
    
    -- Recriar os itens baseado na estrutura original
    for _, itemData in ipairs(estruturaOriginal) do
        if itemData.Instance then
            local newItem = itemData.Instance:Clone()
            
            -- Restaurar posição
            if newItem:IsA("BasePart") and itemData.CFrame then
                newItem.CFrame = itemData.CFrame
            end
            
            -- Atualizar a referência na estrutura original
            itemData.Instance = newItem
            
            -- Colocar no local original
            newItem.Parent = itemData.Parent
        end
    end
    
    itensForamDestruidos = false
    print("Itens da pasta Halloween renasceram após " .. RESPAWN_TIME .. " segundos!")
end

-- Função para configurar a bomba
local function configurarBomba(bomba)
    if not bomba then
        bomba = Workspace:FindFirstChild("Bomba") or Workspace:FindFirstChild("Bomb")
    end
    
    if bomba then
        print("Bomba encontrada! Configurando...")
        
        -- Remover conexões anteriores para evitar múltiplas explosões
        if bomba.TouchedConnection then
            bomba.Touched:Disconnect(bomba.TouchedConnection)
        end
        
        -- Conectar nova explosão
        bomba.TouchedConnection = bomba.Touched:Connect(function(hit)
            -- Verificar se foi tocada por um player
            local character = hit.Parent
            if character and character:FindFirstChild("Humanoid") then
                destroyItems()
            end
        end)
        
        -- Verificar evento personalizado
        local explosionEvent = bomba:FindFirstChild("Explode")
        if explosionEvent and explosionEvent:IsA("BindableEvent") then
            if bomba.ExplosionConnection then
                explosionEvent.Event:Disconnect(bomba.ExplosionConnection)
            end
            bomba.ExplosionConnection = explosionEvent.Event:Connect(destroyItems)
        end
    else
        warn("Bomba não encontrada! Verifique o nome.")
    end
end

-- Inicializar
configurarBomba()

-- Função para teste manual APENAS ADMIN
local function testarExplosao(jogador)
    if jogador then
        -- Verificar se é admin (substitua pelo seu UserId)
        if jogador.UserId == 123456 then -- SEU USER ID AQUI
            print("Admin " .. jogador.Name .. " ativou explosão de teste!")
            destroyItems()
        else
            print(jogador.Name .. " não tem permissão para usar este comando!")
        end
    else
        destroyItems()
    end
end

-- Comando de chat para admin
game.Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/explodir" or message:lower() == "!explodir" then
            testarExplosao(player)
        end
    end)
end)

-- Comando para verificar status
local function verificarStatus()
    local status = itensForamDestruidos and "DESTRUÍDOS" or "INTACTOS"
    local existem = verificarItensExistem() and "EXISTEM" or "NÃO EXISTEM"
    print("Status dos itens: " .. status)
    print("Itens no mapa: " .. existem)
end

-- Comando para ver status no chat
game.Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/status" and player.UserId == 123456 then
            verificarStatus()
        end
    end)
end)
