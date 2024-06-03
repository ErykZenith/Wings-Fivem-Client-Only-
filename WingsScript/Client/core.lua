local AnimDictList = {
    playerUpper =  {"move_m@intimidation@idle_a", "idle_a"},
    playerLower = {"skydive@parachute@", "chute_idle"},
    wing = "creatures@crow@move",
}

local WingsControlAnim = {

    ["fastSpeed"] = {
        Anim = "flapping",
        Offsets = {
            pos = { X = 0.7, Y = -0.15, Z = 0.0 },
            rot = { X = 0.0, Y = 90.0, Z = -50.0 },
        }
    },
    
    ["invariable"] = {
        Anim = "descend",
        Offsets = {
            pos = { X = 0.7, Y = -0.15, Z = -0.3 },
            rot = { X = 0.0, Y = 90.0, Z = -70.0 },
        }
    },

    ["landing"] = {
        Anim = "land",
        AnimTime = 0.75,
        Offsets = {
            pos = { X = 0.7, Y = -0.15, Z = 0.0 },
            rot = { X = 0.0, Y = 90.0, Z = -30.0 },
        }
    },

    ["idle"] = {
        Anim = "ascend",
        Offsets = {
            pos = { X = 0.7, Y = -0.15, Z = 0.0 },
            rot = { X = 0.0, Y = 90.0, Z = -30.0 },
        }
    },

}

local function LoadAnimations(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function LoadWingsModel(model)
    local ModelHash = GetHashKey(model)
    if not HasModelLoaded(ModelHash) then
        RequestModel(ModelHash)
        while not HasModelLoaded(ModelHash) do
            Wait(100)
        end
    end
end

local WingHandler = setmetatable({}, WingHandler)
WingHandler.__index = WingHandler

-- Player
WingHandler.PedPlayer = nil
WingHandler.CamRot = nil

-- Script State
WingHandler.Wing = nil
WingHandler.WingState = nil

-- Settings Wings
WingHandler.RotationPlayer = 0.0
WingHandler.ForceSpeed = 0.0

-- Wings
WingHandler.WingConfig = nil
WingHandler.WingAction = nil
WingHandler.WingModel = nil

function WingHandler:SetPlayerAnim()
    
    CreateThread(function()
        while self.Wing do
            LoadAnimations(AnimDictList.playerLower[1])
            TaskPlayAnimAdvanced(
                self.PedPlayer,
                AnimDictList.playerLower[1],
                AnimDictList.playerLower[2],
                GetEntityCoords(self.PedPlayer),
                0.0, 0.0, GetEntityHeading(self.PedPlayer),
                3.0, 0, -1, 4, 0, 0, 0
            )

            if not IsEntityPlayingAnim(self.PedPlayer, AnimDictList.playerUpper[1], AnimDictList.playerUpper[2],  53) then
                
                LoadAnimations(AnimDictList.playerUpper[1])
                TaskPlayAnimAdvanced(
                    self.PedPlayer,
                    AnimDictList.playerUpper[1], 
                    AnimDictList.playerUpper[2], 
                    GetEntityCoords(self.PedPlayer),
                    0.0, 0.0, GetEntityHeading(self.PedPlayer),
                    -1, 0, -1, 53, 0, 0, 0
                )

                SetEntityAnimCurrentTime(self.PedPlayer, AnimDictList.playerUpper[1], AnimDictList.playerUpper[2], 0.01);

                while true do
                    local currentTime = GetEntityAnimCurrentTime(self.PedPlayer, AnimDictList.playerUpper[1], AnimDictList.playerUpper[2]);
                    if currentTime > 0.01 then
                        SetEntityAnimSpeed(self.PedPlayer, AnimDictList.playerUpper[1], AnimDictList.playerUpper[2], 0);
                        break
                    end
                    Wait(0)
                end

            end
            
            Wait(3300)
        end
    end)

end

function WingHandler:CheckActionSpawnWing()

    if GetEntityHeightAboveGround(self.PedPlayer) < 2.0 then

        self.WingAction = "landing"

    else

        self.WingAction = "idle"

    end

end

function WingHandler:SpawnWing()

    if DoesEntityExist(self.PedPlayer) then

        LoadWingsModel(self.WingConfig.model)
    
        self.WingModel = CreatePed(
            0, 
            GetHashKey(self.WingConfig.model), 
            GetEntityCoords(self.PedPlayer), 
            0.0,
            0.0,
            0.0,
            GetEntityHeading(self.PedPlayer),
            false, true
        )

        SetEntityInvincible(self.WingModel, true)
        FreezeEntityPosition(self.WingModel, true)
        SetBlockingOfNonTemporaryEvents(self.WingModel, true)

        if DoesEntityExist(self.WingModel) then

            WingHandler:CheckActionSpawnWing()

            AttachEntityToEntity(
                self.WingModel,
                self.PedPlayer,
                GetPedBoneIndex(self.PedPlayer, 24817), 
                WingsControlAnim[self.WingAction].Offsets.pos.X, 
                WingsControlAnim[self.WingAction].Offsets.pos.Y, 
                WingsControlAnim[self.WingAction].Offsets.pos.Z, 
                WingsControlAnim[self.WingAction].Offsets.rot.X, 
                WingsControlAnim[self.WingAction].Offsets.rot.Y, 
                WingsControlAnim[self.WingAction].Offsets.rot.Z, 
                0, true, false, true, 0, true
            )
            
            
            if self.WingAction == "landing" then

                LoadAnimations(AnimDictList.wing)
                TaskPlayAnimAdvanced(
                    self.WingModel,
                    AnimDictList.wing, 
                    WingsControlAnim[self.WingAction].Anim,
                    GetEntityCoords(self.WingModel),
                    0.0, 0.0, GetEntityHeading(self.WingModel),
                    -1, 1.0, -1, 1, 0, 0, 0
                )

            else

                FreezeEntityPosition(self.PedPlayer, true)
                ClearPedTasksImmediately(self.PedPlayer)

                LoadAnimations(AnimDictList.wing)
                TaskPlayAnimAdvanced(
                    self.WingModel,
                    AnimDictList.wing, 
                    WingsControlAnim[self.WingAction].Anim,
                    GetEntityCoords(self.WingModel),
                    0.0, 0.0, GetEntityHeading(self.WingModel),
                    7.0, -1, -1, 1, 0, 0, 0
                )
        
                WingHandler:SetPlayerAnim()
                FreezeEntityPosition(self.PedPlayer, false)

            end

            if WingsControlAnim[self.WingAction].AnimTime ~= nil then

                while true do
                    local currentTime = GetEntityAnimCurrentTime(self.WingModel, AnimDictList.wing, WingsControlAnim[self.WingAction].Anim);
                    if currentTime > WingsControlAnim[self.WingAction].AnimTime then
                        SetEntityAnimSpeed(self.WingModel, AnimDictList.wing, WingsControlAnim[self.WingAction].Anim, 0);
                        break
                    end
                    Wait(0)
                end

            end

        end

    end

end

function WingHandler:Setup(wingIndex)

    self.Wing = true
    self.PedPlayer = PlayerPedId()
    self.WingConfig = Config.WingsModel[wingIndex]
    self.RotationPlayer = math.min(80.0, math.max(0.0, self.RotationPlayer))
    self.ForceSpeed = math.min(200.0, math.max(10.0, self.ForceSpeed))

end

function WingHandler:ReSpeed()

    if self.RotationPlayer < 0.0 then
        self.RotationPlayer = self.RotationPlayer + 2.0
    end

    if  self.ForceSpeed > 10.0 then
        self.ForceSpeed = self.ForceSpeed - 5.0
    end

end

function WingHandler:MoveSpeed()

    if self.RotationPlayer > -70.0 then
        self.RotationPlayer = self.RotationPlayer - 1.0
    end

    if self.ForceSpeed < 200.0 then
        self.ForceSpeed = self.ForceSpeed + 1.0
    end

end

function WingHandler:MoveWing()

    local x = -(math.sin(math.rad(self.CamRot.z)) * self.ForceSpeed * 10)
    local y = (math.cos(math.rad(self.CamRot.z)) * self.ForceSpeed * 10)
    local z = self.ForceSpeed * (self.CamRot.x * 0.2)
    
    for i = 1, 10 do
        ApplyForceToEntity(self.PedPlayer, 1, x, y, z, 0, 0, 0, false, false, false, false, false, false)
    end

end

function WingHandler:Jump()

    if GetEntityHeightAboveGround(self.PedPlayer) < 2.0 then

        
        ClearPedTasksImmediately(self.PedPlayer)
        
        self.WingAction = "idle"
        LoadAnimations(AnimDictList.wing)
        TaskPlayAnimAdvanced(
            self.WingModel,
            AnimDictList.wing, 
            WingsControlAnim[self.WingAction].Anim,
            GetEntityCoords(self.WingModel),
            0.0, 0.0, GetEntityHeading(self.WingModel),
            7.0, -1, -1, 1, 0, 0, 0
        )

        WingHandler:SetPlayerAnim()
        
        while true do

            for i = 1, 10 do
                if GetEntityHeightAboveGround(self.PedPlayer) <= 5.0 then
                    ApplyForceToEntity(self.PedPlayer, 1, 0.0, 0.0, 10.0, 0, 0, 0, false, false, false, false, false, false)
                end
            end
            
            if GetEntityHeightAboveGround(self.PedPlayer) > 5.0 then
                break
            end
    
            Wait(0)
        end

    end

end

function WingHandler:ControlWing()
    
    while self.Wing do

        
        if  self.WingAction ~= "landing" then
            
            -- ควรทำงานหลังการอยู่บนการอากาศ
            self.CamRot = GetGameplayCamRot(0)
            SetEntityRotation(self.PedPlayer, self.RotationPlayer, 0.0, self.CamRot.z)
            -- ควรทำงานหลังการอยู่บนการอากาศ

            SetEntityVelocity(self.PedPlayer, 0.0, 0.0, 0.0)
            
            if IsControlPressed(0, 32) then
                WingHandler:MoveWing()
            end

            if IsControlPressed(0, 352) then
                
                WingHandler:MoveSpeed()

            else

                WingHandler:ReSpeed()

            end

            if 
                IsEntityDead(self.PedPlayer) or 
                IsPedRagdoll(self.PedPlayer)
            then
                WingHandler:StopWing()
            end
            
        else
            
            if IsControlJustPressed(0, 22) then
                WingHandler:Jump()
            end
            
        end

        if IsControlJustPressed(0, 73) then
            WingHandler:StopWing()
        end

        
        Wait(0)
    end
    
end

function WingHandler:StopWing()
    
    self.Wing = false
    
    FreezeEntityPosition(self.PedPlayer, true)
    StopAnimTask(self.PedPlayer, AnimDictList.playerUpper[1], AnimDictList.playerUpper[2], 10.0)
    StopAnimTask(self.PedPlayer, AnimDictList.playerLower[1], AnimDictList.playerLower[2], 10.0)
    FreezeEntityPosition(self.PedPlayer, false)
    
    if self.WingModel ~= nil then

        StopAnimTask(self.WingModel, AnimDictList.wing, WingsControlAnim[self.WingAction].Anim, 1.0)

        local alpha = GetEntityAlpha(self.WingModel)
        for i = 1, 10 do
            alpha = alpha - 25
            SetEntityAlpha(self.WingModel, alpha)
            Wait(100)
        end

        DeleteEntity(self.WingModel)
        
    end
    
    self.PedPlayer = nil
    self.CamRot = nil
    self.Wing = nil
    self.WingState = nil
    self.RotationPlayer = 0.0
    self.ForceSpeed = 0.0
    self.WingConfig = nil
    self.WingAction = nil
    self.WingModel = nil

    collectgarbage()
    
end

function WingHandler:StartWing(wingIndex)

    WingHandler:Setup(wingIndex)
    WingHandler:SpawnWing()
    WingHandler:ControlWing()
    
end

function UseWing(wingIndex)

    WingHandler:StartWing(wingIndex)

end

function WingHandler:StopScript()
    
    if self.WingModel ~= nil then
        DeleteEntity(self.WingModel)
    end
    
end

CreateThread(function()
    while true do

        if IsControlJustPressed(0, 38) then
            UseWing("wings")
        end

        Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end

    WingHandler:StopScript()

end)