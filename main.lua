IllusionMod = RegisterMod("Illusion Hearts + Book of Illusions", 1)
local mod = IllusionMod

HeartSubType.HEART_ILLUSION = 9000
CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS = Isaac.GetItemIdByName("Book of Illusions")

local BOIDesc = "Spawns an illusion clone when used#Illusion clones are the same character as you and die in one hit"
local BOIDescSpa = "Genera un clon de ilusión tras usarlo#El clon es el mismo personaje que el tuyo#Morirá al recibir un golpe"
local BOIDescRu = "При использовании создаёт иллюзию# Иллюзия - это тот же персонаж, что и ваш, которые умирают от одного удара"
local BOIDescPt_Br = "Gera um clone de ilusão quando usado#Clones de ilusão são o mesmo personagem como você e morrem em um golpe"


local Wiki = {
  BookOfIllusions = {
    { -- Effect
      {str = "Effect", fsize = 2, clr = 3, halign = 0},
      {str = "Spawns an illusion clone when used."},
      {str = "Illusion clones are the same character as you, with the same starting stats and items."},
      {str = "Illusion clones control like Esau, but cannot pickup any items or pickups."},
      {str = "Illusion clones always die in one hit."},
	  },
    { -- Trivia
      {str = "Trivia", fsize = 2, clr = 3, halign = 0},
      {str = "This has the same effect as picking up an Illusion Heart."},
      {str = "Book of Illusions was an unused item in Antibirth, with its effect being the same as and complimentary to the unused Illusion Hearts."},
    },
  }
}

if EID then
    EID:addCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, BOIDesc, "Book of Illusions", "en_us")
	EID:assignTransformation("collectible", CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, "12", "en_us")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, BOIDescSpa, "El Libro de las ilusiones", "spa")
	EID:assignTransformation("collectible", CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, "12", "spa") 
	EID:addCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, BOIDescRu , "Книга иллюзий", "ru") 
	EID:assignTransformation("collectible", CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, "12", "ru") 
	EID:addCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, BOIDesc, "Livro de Ilusões", "pt_br")
	EID:assignTransformation("collectible", CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, "12", "pt_br") 
end

if Encyclopedia then
	Encyclopedia.AddItem({
	  ID = CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS,
	  WikiDesc = Wiki.BookOfIllusions,
	  Pools = {
		Encyclopedia.ItemPools.POOL_ANGEL,
		Encyclopedia.ItemPools.POOL_DEVIL,
	  	Encyclopedia.ItemPools.POOL_LIBRARY,
		Encyclopedia.ItemPools.POOL_GREED_ANGEL,
		Encyclopedia.ItemPools.POOL_GREED_DEVIL,
	  },
	})
end

if ExtraBirthright then
    ExtraBirthright.AddBookToBirthrightEffect(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS)
end

function IllusionMod:addIllusion(player, isIllusion)
	local id = Game():GetNumPlayers() - 1
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_JACOB then 
		player = player:GetOtherTwin()
		playerType = PlayerType.PLAYER_ESAU 
	end
	
	Isaac.ExecuteCommand('addplayer '..playerType..' '..player.ControllerIndex)
	local _p = Isaac.GetPlayer(id + 1)
	local d = mod:GetData(_p)
	if isIllusion then
		_p.Parent = player
		Game():GetHUD():AssignPlayerHUDs()
		
		for i=1, mod:GetMaxCollectibleID() do
			if not _p:HasCollectible(i) then
				for j=1, player:GetCollectibleNum(i) do
					_p:AddCollectible(i,0,false)
				end
			end
		end
		
		_p:AddMaxHearts(-_p:GetMaxHearts())
		_p:AddSoulHearts(-_p:GetSoulHearts())
		_p:AddBoneHearts(-_p:GetBoneHearts())
		_p:AddGoldenHearts(-_p:GetGoldenHearts())
		_p:AddEternalHearts(-_p:GetEternalHearts())
		_p:AddHearts(-_p:GetHearts())
		
		_p:AddMaxHearts(2)
		_p:AddHearts(2)
		_p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES | EntityCollisionClass.ENTCOLL_PLAYERONLY
		d.IsIllusion = true

		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, _p.Position, _p.Velocity, _p)
	end
	return _p
end

function mod:preIllusionHeartPickup(pickup, collider, low)
	local player = collider:ToPlayer()
	local pickupData = mod:GetData(pickup)

	if player then
		if pickup.SubType == HeartSubType.HEART_ILLUSION then
			pickupData.Picked = true
			pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			pickup:GetSprite():Play("Collect", true)
			
			IllusionMod:addIllusion(player, true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.preIllusionHeartPickup, PickupVariant.PICKUP_HEART)

function mod:postIllusionHeartUpdate(pickup)
	local pickupData = mod:GetData(pickup)
	
	if pickupData.Picked then
		if pickup:GetSprite():GetFrame() == 6 then
			pickup:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.postIllusionHeartUpdate, PickupVariant.PICKUP_HEART)

function mod:postPickupInit(pickup)
	local rng = pickup:GetDropRNG()
	
	if pickup.SubType == HeartSubType.HEART_GOLDEN then
		if rng:RandomFloat() >= 0.5 then
			pickup:Morph(pickup.Type, pickup.Variant, HeartSubType.HEART_ILLUSION)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.postPickupInit, PickupVariant.PICKUP_HEART)

function mod:onUseBookOfIllusions(boi, rng, player, flags, slot, data)
	DoBigbook("gfx/ui/giantbook/Illusions.png", SoundEffect.SOUND_BOOK_PAGE_TURN_12, nil, nil, true)
	
	IllusionMod:addIllusion(player, true)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUseBookOfIllusions, CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS)

function mod:preUseItem(item, rng, player, flags, slot, data) 
	local playerData = mod:GetData(player)
	
	if playerData.IsIllusion then --for some reason dopples can use items so i have to do this
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.preUseItem)

function mod:onEntityTakeDamage(tookDamage, amount, flags, source, frames) 
	local data = mod:GetData(tookDamage)
	
	if data.IsIllusion then
		local sprite = tookDamage:GetSprite()
		tookDamage:Die() --doples always die in one hit, so the hud looks nicer. ideally i'd just get rid of the hud but that doesnt seem possible
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, tookDamage.Position, tookDamage.Velocity, tookDamage)
		sprite:Stop()
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEntityTakeDamage, EntityType.ENTITY_PLAYER)


-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

function mod:GetMaxCollectibleID()
    return Isaac.GetItemConfig():GetCollectibles().Size -1
end

function mod:GetData(entity)
	if entity and entity.GetData then
		local data = entity:GetData()
		if not data.IllusionMod then
			data.IllusionMod = {}
		end
		return data.IllusionMod
	end
	return nil
end

OnRenderCounter = 0
IsEvenRender = true
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	OnRenderCounter = OnRenderCounter + 1
	
	IsEvenRender = false
	if Isaac.GetFrameCount()%2 == 0 then
		IsEvenRender = true
	end
end)

--ripairs stuff from revel
function ripairs_it(t,i)
	i=i-1
	local v=t[i]
	if v==nil then return v end
	return i,v
end
function ripairs(t)
	return ripairs_it, t, #t+1
end

--delayed functions
DelayedFunctions = {}

function DelayFunction(func, delay, args, removeOnNewRoom, useRender)
	local delayFunctionData = {
		Function = func,
		Delay = delay,
		Args = args,
		RemoveOnNewRoom = removeOnNewRoom,
		OnRender = useRender
	}
	table.insert(DelayedFunctions, delayFunctionData)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	for i, delayFunctionData in ripairs(DelayedFunctions) do
		if delayFunctionData.RemoveOnNewRoom then
			table.remove(DelayedFunctions, i)
		end
	end
end)

local function delayFunctionHandling(onRender)
	if #DelayedFunctions ~= 0 then
		for i, delayFunctionData in ripairs(DelayedFunctions) do
			if (delayFunctionData.OnRender and onRender) or (not delayFunctionData.OnRender and not onRender) then
				if delayFunctionData.Delay <= 0 then
					if delayFunctionData.Function then
						if delayFunctionData.Args then
							delayFunctionData.Function(table.unpack(delayFunctionData.Args))
						else
							delayFunctionData.Function()
						end
					end
					table.remove(DelayedFunctions, i)
				else
					delayFunctionData.Delay = delayFunctionData.Delay - 1
				end
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	delayFunctionHandling(false)
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	delayFunctionHandling(true)
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	DelayedFunctions = {}
end)

--bigbook pausing
local hideBerkano = false
function DoBigbookPause()
	local player = Isaac.GetPlayer(0)
	
	local sfx = SFXManager()
	
	hideBerkano = true
	player:UseCard(Card.RUNE_BERKANO, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER) --we undo berkano's effects later, this is done purely for the bigbook which our housing mod should have made blank if we got here
	
	--remove the blue flies and spiders that just spawned
	for _, bluefly in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, -1, false, false)) do
		if bluefly:Exists() and bluefly.FrameCount <= 0 then
			bluefly:Remove()
		end
	end
	for _, bluespider in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_SPIDER, -1, false, false)) do
		if bluespider:Exists() and bluespider.FrameCount <= 0 then
			bluespider:Remove()
		end
	end
end

local isPausingGame = false
local isPausingGameTimer = 0
function KeepPaused()
	isPausingGame = true
	isPausingGameTimer = 0
end

function StopPausing()
	isPausingGame = false
	isPausingGameTimer = 0
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if isPausingGame then
		isPausingGameTimer = isPausingGameTimer - 1
		if isPausingGameTimer <= 0 then
			isPausingGameTimer = 30
			DoBigbookPause()
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_USE_CARD, function()
	if not hideBerkano then
		DelayFunction(function()
			local stuffWasSpawned = false
			
			for _, bluefly in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, -1, false, false)) do
				if bluefly:Exists() and bluefly.FrameCount <= 1 then
					stuffWasSpawned = true
					break
				end
			end
			
			for _, bluespider in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_SPIDER, -1, false, false)) do
				if bluespider:Exists() and bluespider.FrameCount <= 1 then
					stuffWasSpawned = true
					break
				end
			end
			
			if stuffWasSpawned then
				DoBigbook("gfx/ui/giantbook/rune_07_berkano.png", nil, nil, nil, false)
			end
		end, 1, nil, false, true)
	end
	hideBerkano = false
end, Card.RUNE_BERKANO)

--giantbook overlays
local shouldRenderGiantbook = false
local giantbookUI = Sprite()
giantbookUI:Load("gfx/ui/giantbook/giantbook.anm2", true)
local giantbookAnimation = "Appear"
function DoBigbook(spritesheet, sound, animationToPlay, animationFile, doPause)

	if doPause == nil then
		doPause = true
	end
	if doPause then
		DoBigbookPause()
	end
	
	if not animationToPlay then
		animationToPlay = "Appear"
	end
	
	if not animationFile then
		animationFile = "gfx/ui/giantbook/giantbook.anm2"
		if animationToPlay == "Appear" or animationToPlay == "Shake" then
			animationFile = "gfx/ui/giantbook/giantbook.anm2"
		elseif animationToPlay == "Static" then
			animationToPlay = "Effect"
			animationFile = "gfx/ui/giantbook/giantbook_clicker.anm2"
		elseif animationToPlay == "Flash" then
			animationToPlay = "Idle"
			animationFile = "gfx/ui/giantbook/giantbook_mama_mega.anm2"
		elseif animationToPlay == "Sleep" then
			animationToPlay = "Idle"
			animationFile = "gfx/ui/giantbook/giantbook_sleep.anm2"
		elseif animationToPlay == "AppearBig" or animationToPlay == "ShakeBig" then
			if animationToPlay == "AppearBig" then
				animationToPlay = "Appear"
			elseif animationToPlay == "ShakeBig" then
				animationToPlay = "Shake"
			end
			animationFile = "gfx/ui/giantbook/giantbookbig.anm2"
		end
	end
	
	giantbookAnimation = animationToPlay
	giantbookUI:Load(animationFile, true)
	if spritesheet then
		giantbookUI:ReplaceSpritesheet(0, spritesheet)
		giantbookUI:LoadGraphics()
	end
	giantbookUI:Play(animationToPlay, true)
	shouldRenderGiantbook = true
	
	if sound then
		local sfx = SFXManager()
		sfx:Play(sound, 1, 0, false, 1)
	end
	
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if ShouldRender() then
		local centerPos = GetScreenCenterPosition()
		
		if IsEvenRender then
			giantbookUI:Update()
			if giantbookUI:IsFinished(giantbookAnimation) then
				shouldRenderGiantbook = false
			end
		end
		
		if shouldRenderGiantbook then
			giantbookUI:Render(centerPos, Vector.Zero, Vector.Zero)
		end
	end
end)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	shouldRenderGiantbook = false
end)

function ShouldRender(ignoreMusic, ignoreNoHud)

	local music = MusicManager()
	local currentMusic = music:GetCurrentMusicID()
	
	local game = Game()
	local seeds = game:GetSeeds()

	if (ignoreMusic or (currentMusic ~= Music.MUSIC_JINGLE_BOSS and currentMusic ~= Music.MUSIC_JINGLE_NIGHTMARE)) and (ignoreNoHud or not seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD)) then
		return true
	end
	
	return false
end

function GetScreenCenterPosition()

	local game = Game()
	local room = game:GetRoom()

	local shape = room:GetRoomShape()
	local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
	local pos = room:GetCenterPos()
	
	if centerOffset.X > 260 then
		pos.X = pos.X - 260
	end
	if shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LTL then
		pos.X = pos.X - 260
	end
	if centerOffset.Y > 140 then
		pos.Y = pos.Y - 140
	end
	if shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LTL then
		pos.Y = pos.Y - 140
	end
	
	return Isaac.WorldToRenderPosition(pos, false)
	
end