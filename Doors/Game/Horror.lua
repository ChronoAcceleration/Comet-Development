--[[

Hello!!
This is an re-creation of my unreleased custom Doors gamemode, "Doors But Horror".
The premise is basically a pitch-black environment, with the only light source being guiding light.
There may be a few new entities you will not recognize aswell.

SyncHelper Utility Module Source: https://github.com/ChronoAcceleration/Comet-Development/blob/main/Doors/Utility/SyncHelper.lua
-- Chrono @Comet Development

--]]

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

local function whisper(SpawnDistance: number, ChaseDuration: number): ()
    local PlayerCharacter = Player.Character
    local CharacterRoot = PlayerCharacter.HumanoidRootPart
    local CharacterCFrame = PlayerCharacter:GetPivot()
    local CharacterBack = CharacterCFrame.LookVector * -1
    local SpawnPosition = CharacterCFrame.Position + CharacterBack * SpawnDistance

    local WhisperEntity = game:GetObjects("rbxassetid://90061066167445")[1]
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
    Movement.D = 1000
    Movement.P = 4000
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

local function spawnEntity(): ()
    local EntityChance = SyncHelper:generateRandom(1, 25, LatestRoom.Value)
    local DelayTime = SyncHelper:generateRandom(5, 15, LatestRoom.Value)

    SyncHelper:deltaWait(DelayTime)

    if EntityChance >= 15 then
        print("Not spawning an entity!")
        return
    end

    local Entity = 1
    if Entity == 1 then
        if Workspace:FindFirstChild("WhisperNew") then
            return
        end
        whisper(SyncHelper:generateRandom(20, 40, LatestRoom.Value), SyncHelper:generateRandom(15, 30, LatestRoom.Value))
    end
end

-- Game Hooks

CurrentRooms.ChildAdded:Connect(removeRoomLights)
CurrentRooms.ChildAdded:Connect(spawnEntity)
