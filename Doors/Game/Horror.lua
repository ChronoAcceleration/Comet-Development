--[[

Hello!!
This is an re-creation of my unreleased custom Doors gamemode, "Doors But Horror".
The premise is basically a pitch-black environment, with the only light source being curious light.
There may be a few new entities you will not recognize aswell.

SyncHelper Utility Module Source: https://github.com/ChronoAcceleration/Comet-Development/blob/main/Doors/Utility/SyncHelper.lua
-- Chrono @Comet Development

game.Players.LocalPlayer.Character.Humanoid:TakeDamage(100)

--]]

if _G.ExecutedHorror then
    return
end

local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local LIGHTING_KEYWORDS = {
    "Light_Fixtures",
    "Chandelier"
}

local LIGHTING_CONFIGURATION = {
    ["FogColor"] = Color3.fromRGB(14, 13, 18),
    ["FogEnd"] = 100,
    ["FogStart"] = 5
}

local DEFAULT_COLOR_CORRECTION_VALUES = {
    ["Brightness"] = 0.04,
    ["Contrast"] = 0.05,
    ["Saturation"] = 0.2,
    ["Tint"] = Color3.fromRGB(255, 255, 255)
}

-- // Functions

local function runCoreCall(ITitle: string, IText: string, IDuration: number): ()
    local Success, Return = pcall(
        function(): boolean?
            StarterGui:SetCore("SendNotification", {
                Title = ITitle,
                Text = IText,
                Duration = IDuration
            })
        end
    )

    assert(Success, Return)
end

local function fetchCurrentRoom(Room: number, CurrentRooms: Folder): Model?
    local Room = CurrentRooms:FindFirstChild(tostring(Room))
    return Room
end

local function getGitSoundId(GithubSoundPath: string, AssetName: string): Sound
    local Url = GithubSoundPath

    if not isfile(AssetName..".mp3") then 
        writefile(AssetName..".mp3", game:HttpGet(Url)) 
    end

    local Sound = Instance.new("Sound")
    Sound.SoundId = (getcustomasset or getsynasset)(AssetName..".mp3")
    return Sound 
end

local function displaySystemMessage(Message, Color): ()
    local TextChannels = TextChatService.TextChannels
    local RBXGeneral = TextChannels.RBXGeneral

    RBXGeneral:DisplaySystemMessage(string.format('<font color="rgb(%d, %d, %d)">%s</font>', Color.R, Color.G, Color.B, Message))
end

local function runGuidingLight(Text: table, Type: string): ()
    local RemotesFolder = ReplicatedStorage.RemotesFolder
    local DeathHint = RemotesFolder.DeathHint

    firesignal(DeathHint.OnClientEvent, Text, Type)
end

local function changeDeathCause(Cause: string, Player: Player): ()
    local Character = Player.Character
    local Humanoid = Character.Humanoid

    local GameStats = ReplicatedStorage.GameStats
    local PlayerStats = GameStats[string.format("Player_%s", Player.Name)]
    local Total = PlayerStats.Total
    local DeathCause = Total.DeathCause

    DeathCause.Value = Cause
    Humanoid:TakeDamage(100)
end

local function toggleLights(room, turnOn, ambientColor): () -- LSPlash Code!
    local targetRoom = room;

    task.spawn(function()
        if typeof(targetRoom) ~= "Instance" then
            if typeof(targetRoom) == "number" then
                targetRoom = workspace.CurrentRooms:FindFirstChild(targetRoom);
            else
                targetRoom = nil;
            end
        end

        if targetRoom == nil then
            warn("Cannot find room");
        end

        local randomSeed = Random.new(math.ceil(os.time()));
        local lightFixtures = {};

        for _, object in pairs(targetRoom:GetDescendants()) do
            if object:IsA("Model") and (object.Name == "LightStand" or object.Name == "Chandelier") then
                table.insert(lightFixtures, object);
            end
        end

        if not turnOn then
            for _, fixture in pairs(lightFixtures) do
                for _, descendant in pairs(fixture:GetDescendants()) do
                    if descendant:IsA("Light") then
                        descendant:SetAttribute("OriginalBrightness", descendant.Brightness);
                    elseif descendant:IsA("Sound") then
                        descendant:SetAttribute("OriginalVolume", descendant.Volume);
                    end
                end
            end
        end

        TweenService:Create(game.Lighting, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Ambient = ambientColor
        }):Play()
        targetRoom:SetAttribute("Ambient", ambientColor)

        if turnOn then
            for _, fixture in pairs(lightFixtures) do
                local randomDelay = randomSeed:NextInteger(-10, 10) / 50
                local turnOnDuration = randomSeed:NextInteger(5, 20) / 100
                
                task.delay((targetRoom.RoomEntrance.Position - fixture.PrimaryPart.Position).Magnitude / 150 + randomDelay, function()
                    local neonPart = fixture:FindFirstChild("Neon", true)
                    
                    for _, descendant in pairs(fixture:GetDescendants()) do
                        if descendant:IsA("Light") then
                            TweenService:Create(descendant, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                Brightness = descendant:GetAttribute("OriginalBrightness") * 1
                            }):Play();
                        elseif descendant:IsA("Sound") then
                            TweenService:Create(descendant, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                Volume = descendant:GetAttribute("OriginalVolume")
                            }):Play();
                        end
                    end

                    if neonPart then
                        neonPart.Transparency = 0.9;
                        neonPart.Material = Enum.Material.Neon;
                        TweenService:Create(neonPart, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            Transparency = 0.2
                        }):Play();
                    end
                end);
            end
        else
            for _, fixture in pairs(lightFixtures) do
                local randomDelay = randomSeed:NextInteger(-10, 10) / 50;
                local turnOffDuration = randomSeed:NextInteger(5, 20) / 100;
                
                task.delay((targetRoom.RoomEntrance.Position - fixture.PrimaryPart.Position).Magnitude / 150 + randomDelay, function()
                    local chargeSound = game:GetService("ReplicatedStorage").Sounds.BulbCharge:Clone();
                    chargeSound.Parent = fixture.PrimaryPart;
                    chargeSound.Pitch = chargeSound.Pitch + math.random(-140, 140) / 800;
                    chargeSound:Play()
                    game.Debris:AddItem(chargeSound, 2);

                    local neonPart = fixture:FindFirstChild("Neon", true);
                    if neonPart then
                        TweenService:Create(neonPart, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                            Transparency = 0
                        }):Play()
                    end

                    for _, descendant in pairs(fixture:GetDescendants()) do
                        if descendant:IsA("Light") then
                            TweenService:Create(descendant, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                Brightness = descendant:GetAttribute("OriginalBrightness") * 2
                            }):Play()
                        elseif descendant:IsA("Sound") then
                            TweenService:Create(descendant, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                Volume = 0
                            }):Play()
                        end
                    end

                    task.wait(turnOffDuration + 0.01);

                    if neonPart then
                        neonPart.Transparency = 0
                        neonPart.Material = Enum.Material.Glass
                    end

                    for _, descendant in pairs(fixture:GetDescendants()) do
                        if descendant:IsA("Light") then
                            TweenService:Create(descendant, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                Brightness = 0
                            }):Play()
                        end
                    end

                    chargeSound:Stop()
                end)
            end
        end
    end)
end

local function removeRoomLights(Room: Model): ()
    if not Room:IsA("Model") then
        return --// This should never happen, but it's worth checking.
    end

    task.wait(1) -- Allow streaming in

    local RoomAssets = Room:WaitForChild("Assets")
    local LightingAssets = {}

    for _, Asset in RoomAssets:GetChildren() do
        if table.find(LIGHTING_KEYWORDS, Asset.Name) then
            table.insert(LightingAssets, Asset)
        end
    end

    for _, Asset in pairs(LightingAssets) do
        Asset:Destroy()
    end

    Room:SetAttribute("Ambient", Color3.fromRGB(0, 0, 0))
end

local function convertHelpfulLight(Light: Part, Music: Sound): ()
    local HelpParticle = Light.HelpParticle
    HelpParticle.Color = ColorSequence.new(Color3.fromRGB(255, 238, 0))
    HelpParticle.Rate = 10

    Music.Parent = Light
    Music.Looped = true
    Music.RollOffMaxDistance = 100
    Music.RollOffMinDistance = 0
    Music.RollOffMode = Enum.RollOffMode.Linear
    Music.Volume = 0.5
    Music:Play()

    for _, PointLight: PointLight in Light:GetChildren() do
        if not PointLight:IsA("PointLight") then
            continue
        end

        PointLight.Brightness = 1
        PointLight.Color = Color3.fromRGB(255, 238, 55)

        task.delay(
            1,
            function(): ()
                if PointLight.Brightness ~= 1 then
                    print("WHYU YOU NOGIUYO OOOO STAY 1 GUTHRJDHGRSJTKGDTRGB GRRR IM GONNA KILL")
                    PointLight.Brightness = 1
                end
            end
        )
        
        if not PointLight.Shadows then
            PointLight.Shadows = true
        end
    end
end

--// Functionality (wink wink get it!!)

local PlaceId = game.PlaceId
local DoorsPlaceId = 6839171747

if PlaceId ~= DoorsPlaceId then
    return runCoreCall(
        "Error",
        "Make sure you are running this script in the Hotel!",
        5
    )
end

local SyncHelper: ModuleScript = loadstring(game:HttpGet("https://github.com/ChronoAcceleration/Comet-Development/raw/refs/heads/main/Doors/Utility/SyncHelper.lua"))()

local GameData: Folder = ReplicatedStorage:WaitForChild("GameData")
local LatestRoom: NumberValue = GameData:WaitForChild("LatestRoom")
local CurrentRooms: Folder = workspace:WaitForChild("CurrentRooms")
local Player: Player = Players.LocalPlayer

if LatestRoom.Value ~= 0 then
    return runCoreCall(
        "Error",
        "The game has already started!",
        5
    )
end

_G.ExecutedHorror = true

-- Await Game Start

LatestRoom:GetPropertyChangedSignal("Value"):Wait()

-- Game Start

do
    local Room1 = fetchCurrentRoom(1, CurrentRooms)
    
    local Success, Return = pcall(
        function(): ()
            local StartSound = getGitSoundId("https://github.com/ChronoAcceleration/Comet-Development/blob/main/Doors/Assets/Horror/CourtyardEntry.mp3?raw=true", "HorrorBeginChime")
            StartSound.Parent = SoundService

            task.delay(
                .5,
                function(): ()
                    StartSound:Play()
                    StartSound.Ended:Wait()
                    StartSound:Destroy()
                end
            )
        end
    )

    assert(Success, Return)

    SyncHelper:deltaWait(.5)
    toggleLights(Room1, false, Color3.fromRGB(0,0,0))
    removeRoomLights(fetchCurrentRoom(2, CurrentRooms)) -- Remove the lights from the second room, because the event doesnt catch that one :(

    Lighting.FogColor = LIGHTING_CONFIGURATION.FogColor
    Lighting.FogEnd = LIGHTING_CONFIGURATION.FogEnd
    Lighting.FogStart = LIGHTING_CONFIGURATION.FogStart

    displaySystemMessage("Can you survive the darkness?", Color3.fromRGB(199, 125, 125))
end

-- Entities

local EntityStorage = Instance.new("Folder", ReplicatedStorage); EntityStorage.Name = "HorrorModeEntities"
local WhisperEntityBase = game:GetObjects("rbxassetid://90061066167445")[1]; WhisperEntityBase.Parent = EntityStorage
local SpecterEntityBase = game:GetObjects("rbxassetid://125103851470017")[1]; SpecterEntityBase.Parent = EntityStorage

local CuriousHumm = getGitSoundId("https://github.com/ChronoAcceleration/Comet-Development/blob/main/Doors/Assets/Horror/Curious%20Humm.mp3?raw=true", "CuriousHumm")
CuriousHumm.Parent = SoundService

-- Hotfixes

pcall(function(): ()
    SpecterEntityBase.Spawn.Playing = false
end)

-- Hotfixes End

local function whisper(SpawnDistance: number, ChaseDuration: number, GracePeriod: number): ()
    local PlayerCharacter = Player.Character
    local CharacterRoot = PlayerCharacter.HumanoidRootPart
    local CharacterCFrame = PlayerCharacter:GetPivot()
    local CharacterBack = CharacterCFrame.LookVector * -1
    local SpawnPosition = CharacterCFrame.Position + CharacterBack * SpawnDistance
    
    local WhisperEntity = WhisperEntityBase:Clone()
    local WhisperRig = WhisperEntity.Rig
    local WhisperBreathing = WhisperRig.Breathing
    local WhisperParticles = WhisperRig.Attachment

    WhisperEntity.Parent = workspace
    WhisperEntity:PivotTo(CFrame.new(SpawnPosition))

    WhisperEntity.Name = "WhisperNew"
    WhisperRig.CanCollide = false
    WhisperRig.CanTouch = false
    WhisperRig.CanQuery = false
    WhisperRig.Anchored = false

    local Movement = Instance.new("BodyPosition", WhisperRig)
    Movement.D = 1500
    Movement.P = 3000
    Movement.MaxForce = Vector3.new(1000, 250000, 1000)

    WhisperBreathing:Play()
    WhisperBreathing.Volume = 0
    TweenService:Create(WhisperBreathing, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Volume = 1
    }):Play()

    local TargetDistance = (CharacterRoot.Position - WhisperRig.Position).Magnitude
    
    local MovementUpdate = RunService.Heartbeat:Connect(
        function(): ()
            TargetDistance = (CharacterRoot.Position - WhisperRig.Position).Magnitude
            Movement.Position = CharacterRoot.Position
        end
    )

    local DeathCheck = task.spawn(
        function(): ()
            SyncHelper:deltaWait(GracePeriod)

            while true do
                if TargetDistance <= 13 then
                    runGuidingLight(
                        {
                            "Oh.. Hello.",
                            "I thought I wouldn't see you here.", 
                            "The Guiding Celestial is not here with us at the moment.", 
                            "They were.. busy fixing some important deals with the lighting.",
                            "Let's just get to the point.",
                            "The thing is pretty quiet, so we can call it Whisper.",
                            "Now normally, it wouldn't be an issue--But as for now.. you just have to avoid them.",
                            "Stay as far away from them!"
                        },
                        "Yellow"
                    )
                    changeDeathCause("Whisper", Player)
                    break
                end
                task.wait(.1)
            end
        end
    )

    SyncHelper:deltaWait(ChaseDuration)

    task.cancel(DeathCheck)
    for _, Effect in WhisperParticles:GetChildren() do
        Effect.Enabled = false
    end

    TweenService:Create(WhisperBreathing, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Volume = 0
    }):Play()

    MovementUpdate:Disconnect()
    Movement:Destroy()
    Debris:AddItem(WhisperEntity, 5)
end

local function wailingSpecter(Duration: number): ()
    local SpecterEntity = SpecterEntityBase:Clone()
    local SpawnSound = SpecterEntity.Spawn; SpawnSound.Volume = 3
    local ColorCorrection = Lighting.MainColorCorrection

    local function getRandomPlaybackSpeed(): number
        return math.random() * (1.8 - 0.3) + 0.3
    end

    local function variatePlaybackSpeed(Speed: number): ()
        local PlaybackTween = TweenService:Create(
            SpawnSound,
            TweenInfo.new(0.05, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {
                PlaybackSpeed = Speed
            }
        )

        PlaybackTween:Play()
    end

    local CurrentRoom = fetchCurrentRoom(LatestRoom.Value, CurrentRooms)
    local RoomEntrance = CurrentRoom.RoomEntrance
    assert(RoomEntrance, "RoomEntrance is nil! This is not awesome sauce.")

    LatestRoom:GetPropertyChangedSignal("Value"):Wait()

    local ColorCorrectionVariate = task.spawn(
        function(): ()
            while true do
                local newBrightness = math.random() * (0.1 - 0.01) + 0.01
                local newContrast = math.random() * (0.1 - 0.01) + 0.01
                local newSaturation = math.random() * (0.3 - 0.1) + 0.1
                local newTint = Color3.fromRGB(math.random(200, 255), math.random(200, 255), math.random(200, 255))
    
                TweenService:Create(ColorCorrection, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Brightness = newBrightness,
                    Contrast = newContrast,
                    Saturation = newSaturation,
                    TintColor = newTint
                }):Play()
    
                task.wait(0.05)
            end
        end
    )

    local PlaybackSpeedVariate = task.spawn(
        function(): ()
            while true do
                variatePlaybackSpeed(getRandomPlaybackSpeed())
                task.wait(.05)
            end
        end
    )

    local SpecterSpawnPosition = RoomEntrance.Position + RoomEntrance.CFrame.LookVector * 10
    SpecterEntity.Parent = workspace
    SpecterEntity:PivotTo(CFrame.new(SpecterSpawnPosition))
    SpawnSound:Play()

    SyncHelper:deltaWait(Duration)
    task.cancel(PlaybackSpeedVariate)
    task.cancel(ColorCorrectionVariate)

    task.spawn(
        function(): ()
            SyncHelper:deltaWait(1)
            ColorCorrection.Brightness = DEFAULT_COLOR_CORRECTION_VALUES.Brightness
            ColorCorrection.Contrast = DEFAULT_COLOR_CORRECTION_VALUES.Contrast
            ColorCorrection.Saturation = DEFAULT_COLOR_CORRECTION_VALUES.Saturation
            ColorCorrection.TintColor = DEFAULT_COLOR_CORRECTION_VALUES.Tint
        end
    )

    SpecterEntity:Destroy()
end

local function spawnEntity(): ()
    local EntityChance = SyncHelper:generateRandom(1, 100, LatestRoom.Value)
    print(EntityChance)

    if EntityChance > 15 then
        return
    end

    local Entity = SyncHelper:generateFullRandom(1, 2, LatestRoom.Value)
    if Entity == 1 then
        if Workspace:FindFirstChild("WhisperNew") then
            return
        end

        task.spawn(
            function(): ()
                local DelayTime = SyncHelper:generateRandom(0, 15, LatestRoom.Value)
                SyncHelper:deltaWait(DelayTime)

                whisper(
                    SyncHelper:generateRandom(20, 45, LatestRoom.Value),
                    SyncHelper:generateRandom(10, 20, LatestRoom.Value),
                    SyncHelper:generateRandom(2, 4, LatestRoom.Value)
                )
            end
        )
    elseif Entity == 2 then
        -- wraith goes here
    end
end

-- Game Hooks

CurrentRooms.ChildAdded:Connect(removeRoomLights)
CurrentRooms.ChildAdded:Connect(spawnEntity)

CurrentRooms.DescendantAdded:Connect(
    function(Asset: Instance): ()
        if Asset.Name == "HelpfulLight" then
            convertHelpfulLight(Asset, CuriousHumm:Clone())
        end
    end
)

-- Loop Hooks

-- MAIN THREAD

task.spawn(
    function(): ()
        while SyncHelper:deltaWait(SyncHelper:generateRandom(30, 60, LatestRoom.Value)) do
            local SpecterSpawnChance = SyncHelper:generateFullRandom(1, 100, LatestRoom.Value)

            if SpecterSpawnChance ~= 1 then
                return
            end

            wailingSpecter(SyncHelper:generateRandom(10, 20, LatestRoom.Value))
        end
    end
)
