--[[
--{ ================== INSTRUÇÕES ==================

TIPO DE SCRIPT:
✔ Use um "Script"
❌ NÃO use LocalScript

ONDE COLOCAR:
Explorer → ServerScriptService → Insert Object → Script

ESTRUTURA NECESSÁRIA:
Workspace
 └── Mapa2
      └── Halloween
           ├── V1P3R statua  (PROTEGIDA - NÃO EXPLODE)
           ├── abobora       (Folder)
           ├── arvores       (Folder)
           ├── esqueletos    (Folder)
           └── outros        (Folder)

IMPORTANTE:
✔ V1P3R statua NÃO será destruída
✔ Todo o resto pode ser destruído
✔ Tudo respawna após 5 minutos

CONFIGURAÇÕES DOS OBJETOS:
✔ Anchored = true (recomendado)
✔ CanCollide = true
✔ CanTouch = true
✔ CanQuery = true

SE ALGO NÃO EXPLODIR:
→ Verifique se está dentro da pasta Halloween
→ Verifique se NÃO está dentro de V1P3R statua

SE QUISER MUDAR O TEMPO DE RESPAWN:
Altere:
local RESPAWN_TIME = 300

300 = 5 min
60 = 1 min
10 = 10 s

=====================================================
--} ==================================================
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local halloweenFolder = Workspace:WaitForChild("Mapa2"):WaitForChild("Halloween")
local protectedFolder = halloweenFolder:WaitForChild("V1P3R statua")

local RESPAWN_TIME = 300 -- 5 minutos

---------------------------------------------------
-- BACKUP DOS OBJETOS
---------------------------------------------------

local backupFolder = Instance.new("Folder")
backupFolder.Name = "HalloweenBackup"
backupFolder.Parent = ServerStorage

for _, obj in ipairs(halloweenFolder:GetChildren()) do
	if obj ~= protectedFolder then
		obj:Clone().Parent = backupFolder
	end
end

print("✅ Backup do mapa Halloween criado.")

---------------------------------------------------
-- RESPAWN
---------------------------------------------------

local function respawnObjects()
	print("🔄 Respawnando objetos do Halloween...")

	for _, obj in ipairs(halloweenFolder:GetChildren()) do
		if obj ~= protectedFolder then
			obj:Destroy()
		end
	end

	for _, backupObj in ipairs(backupFolder:GetChildren()) do
		backupObj:Clone().Parent = halloweenFolder
	end

	print("✅ Objetos restaurados.")
end

---------------------------------------------------
-- DESTRUIR SE FOR VÁLIDO
---------------------------------------------------

local function destroyIfValid(part)
	if part:IsDescendantOf(halloweenFolder)
		and not part:IsDescendantOf(protectedFolder) then

		local model = part:FindFirstAncestorOfClass("Model")

		if model and model ~= halloweenFolder then
			model:Destroy()
		else
			part:Destroy()
		end
	end
end

---------------------------------------------------
-- DETECTAR EXPLOSÃO
---------------------------------------------------

Workspace.DescendantAdded:Connect(function(descendant)

	if descendant:IsA("Explosion") then
		print("💥 Explosão detectada!")

		descendant.Hit:Connect(function(part)
			destroyIfValid(part)
		end)

		task.delay(RESPAWN_TIME, respawnObjects)
	end
end)
