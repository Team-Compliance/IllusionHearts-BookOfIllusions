IllusionMod = RegisterMod("Illusion Hearts + Book of Illusions", 1)
local mod = IllusionMod
local json = require("json")
local sfxManager = SFXManager()
local version = 2.4
local game = Game()
local hud = game:GetHUD()
--[[local illisionSprite = Sprite()
illisionSprite:Load("gfx/ui/ui_hearts_illusion.anm2",true)
illisionSprite:Play("IllusionHeart",true)]]

HeartSubType.HEART_ILLUSION = 9000
CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS = Isaac.GetItemIdByName("Book of Illusions")

local PickupIllusionSFX = Isaac.GetSoundIdByName("PickupIllusion")

local BOIDesc = "Spawns an illusion clone when used#Illusion clones are the same character as you and die in one hit"
local BOIDescSpa = "Genera un clon de ilusión tras usarlo#El clon es el mismo personaje que el tuyo#Morirá al recibir un golpe"
local BOIDescRu = "При использовании создаёт иллюзию# Иллюзия - это тот же персонаж, что и ваш, которые умирают от одного удара"
local BOIDescPt_Br = "Gera um clone de ilusão quando usado#Clones de ilusão são o mesmo personagem como você e morrem em um golpe"

local ForbiddenItems = {
	CollectibleType.COLLECTIBLE_1UP,
	CollectibleType.COLLECTIBLE_DEAD_CAT,
	CollectibleType.COLLECTIBLE_INNER_CHILD,
	CollectibleType.COLLECTIBLE_GUPPYS_COLLAR,
	CollectibleType.COLLECTIBLE_LAZARUS_RAGS,
	CollectibleType.COLLECTIBLE_ANKH,
	CollectibleType.COLLECTIBLE_JUDAS_SHADOW,
}

local MCMIllusionsBombs = false

local ForbiddenPCombos = {
	{PlayerType = PlayerType.PLAYER_THELOST_B, Item = CollectibleType.COLLECTIBLE_BIRTHRIGHT},
}

function mod.AddForbiddenItem(i)
	table.insert(ForbiddenItems,i)
end

function mod.AddForbiddenCharItem(type,i)
	table.insert(ForbiddenPCombos,{PlayerType = type, Item = i})
end

local pDataTable = {}

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
	EID:addCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS, BOIDescPt_Br, "Livro de Ilusões", "pt_br")
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

if ModConfigMenu then
	local IHandBoI = "Illusions mod"
	ModConfigMenu.UpdateCategory(IHandBoI, {
		Info = {"Configuration for clones.",}
	})
	ModConfigMenu.AddSetting(IHandBoI,
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return MCMIllusionsBombs
			end,
			Default = false,
			Display = function()
				local displaystring = MCMIllusionsBombs == true and "On" or "Off"
				return "Illusions can use bombs: "..displaystring
			end,
			OnChange = function(value)
				MCMIllusionsBombs = value
			end,
			Info = "Option for clones to drop bombs."
		})
end

local function BlackList(collectible)
	for _,i in ipairs(ForbiddenItems) do
		if i == collectible then
			return true
		end
	end
	return false
end

local function CanBeRevived(pType,withItem)
	for _,v in ipairs(ForbiddenPCombos) do
		if v.PlayerType == pType and v.Item == withItem then
			return true
		end
	end
	return false
end

--[[local function cloneHeartPos(hearts,hpOffset,p)
	return Isaac.WorldToScreen(p.Position) + p.PositionOffset * 0.75 + Vector(hearts*6-11-(hpOffset-1)*5+5*(hpOffset>5 and hpOffset-6 or 0), -30 * p.SpriteScale.Y - (p.CanFly and 4 or 0))
end

---Rendering hearts
---@param player EntityPlayer
---@param playeroffset integer
local function renderingHearts(player,playeroffset)
	local transperancy = 1
	if player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) then
		transperancy = 0.5
	end
	local offset = cloneHeartPos(1,0,player)
	
	illisionSprite.Color = Color(1,1,1,transperancy)
	illisionSprite:Render(Vector(offset.X, offset.Y), Vector(0,0), Vector(0,0))

end

---Should show hearts
---@return boolean
local function shouldDeHook()
	local reqs = {
	  not hud:IsVisible(),
	  game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD),
	  game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0
	}
	return reqs[1] or reqs[2] or reqs[3]
end

---Handling of rendering for clone
function mod:onRenderClone(player)
	if shouldDeHook() then return end
	--for i = 0, game:GetNumPlayers() - 1 do
		--local player = Isaac.GetPlayer(i)
		local data = mod.GetEntityData(player)
		---@cast player EntityPlayer
		if data.IsIllusion then
			if player:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B then
				renderingHearts(player)
			end
		else
			mod:RemoveEntityData(player)
		end
	--end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, mod.onRenderClone)]]

function mod:Save(isSaving)
	if isSaving then
		local save = {}
		local playersSave = nil
		for key,value in pairs(pDataTable) do
			if value ~= nil and key ~= nil then
				if playersSave == nil then
					playersSave = {}
				end
				playersSave[tostring(key)] = value
			end
		end
		save.Players = playersSave
		save.Version = version
		save.BombOption = MCMIllusionsBombs
		mod:SaveData(json.encode(save))
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.Save)

function mod:Load(isLoading)
	pDataTable = {}
	local load
	if mod:HasData() then
		load = json.decode(mod:LoadData())
		if load.Version ~= nil and load.Version >= 2.3 then
			MCMIllusionsBombs = load.BombOption
		end
	end
	if isLoading then
		local playersLoad
		if load.Version == nil or load.Version ~= nil and load.Version < 2.3 then
			playersLoad = load
		else
			playersLoad = load.Players
		end
		if playersLoad ~= nil then
			for key,value in pairs(playersLoad) do
				if value ~= nil and key ~= nil then
					pDataTable[tonumber(key)] = value
				end
			end
		end
		for i = 0, game:GetNumPlayers()-1 do
			local p = Isaac.GetPlayer(i)
			local data = mod.GetEntityData(p)
			if data.IsIllusion then
				p:AddCacheFlags(CacheFlag.CACHE_ALL)
				p:EvaluateItems()
			else
				mod:RemoveEntityData(p)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.Load)

function mod:End(GameOver)
	if GameOver then
		pDataTable = {}
		local save = {Version = version, BombOption = MCMIllusionsBombs}
		mod:SaveData(json.encode(save))
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, mod.End)

function mod:UpdateClones(p)
	local data = mod.GetEntityData(p)
	if data.IsIllusion then
		if p:IsDead()  then
			--p.Visible = false
			if p:GetPlayerType() ~= PlayerType.PLAYER_THELOST and p:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B 
			and p:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B then
				p:GetSprite():SetLayerFrame(PlayerSpriteLayer.SPRITE_GHOST,0)
			end
			if p:GetSprite():IsFinished("Death") or p:GetSprite():IsFinished("ForgottenDeath") then
				p:GetSprite():SetFrame(70)
				if p:GetPlayerType() ~= PlayerType.PLAYER_THELOST and p:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B and
				p:GetPlayerType() ~= PlayerType.PLAYER_THESOUL and p:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B  and p:GetPlayerType() ~= PlayerType.PLAYER_THEFORGOTTEN_B
				and not p:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) then
					p:ChangePlayerType(PlayerType.PLAYER_THELOST)
					local offset = (p:GetPlayerType() ~= PlayerType.PLAYER_THEFORGOTTEN or p:GetPlayerType() ~= PlayerType.PLAYER_THEFORGOTTEN_B) and Vector(30 * p.SpriteScale.X,0) or Vector.Zero
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, p.Position + offset, Vector.Zero, p)
				end
			end
		end
		if not p:IsDead() then
			if p.Parent and (not p.Parent:Exists() or p.Parent:IsDead()) then
				p:Die()
				p:AddMaxHearts(-p:GetMaxHearts())
				p:AddSoulHearts(-p:GetSoulHearts())
				p:AddBoneHearts(-p:GetBoneHearts())
				p:AddGoldenHearts(-p:GetGoldenHearts())
				p:AddEternalHearts(-p:GetEternalHearts())
				p:AddHearts(-p:GetHearts())
				--Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, p.Position, Vector.Zero, p)
			end
		end
		p:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.UpdateClones)

function mod:CloneRoomUpdate()
	for i = 0, game:GetNumPlayers()-1 do
		local p = Isaac.GetPlayer(i)
		local data = mod.GetEntityData(p)
		if data.IsIllusion and p:IsDead() then
			p:GetSprite():SetFrame(70)
			p:ChangePlayerType(PlayerType.PLAYER_THELOST)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, p.Position, Vector.Zero, p)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.CloneRoomUpdate)

function mod:addIllusion(player, isIllusion)
	local id = game:GetNumPlayers() - 1
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_JACOB then 
		player = player:GetOtherTwin()
		playerType = PlayerType.PLAYER_ESAU 
	end
	if playerType == PlayerType.PLAYER_THESOUL_B then
		playerType = PlayerType.PLAYER_THEFORGOTTEN_B
	end
	if playerType == PlayerType.PLAYER_THESOUL then
		playerType = PlayerType.PLAYER_THEFORGOTTEN
	end
	Isaac.ExecuteCommand('addplayer 15 '..player.ControllerIndex)
	local _p = Isaac.GetPlayer(id + 1)
	local d = mod.GetEntityData(_p)
	if playerType == PlayerType.PLAYER_LAZARUS_B or playerType == PlayerType.PLAYER_LAZARUS2_B then
		_p:ChangePlayerType(0)
		if playerType == PlayerType.PLAYER_LAZARUS_B then
			d.TaintedLazA = true
		else
			d.TaintedLazB = true
		end
		local costume = playerType == PlayerType.PLAYER_LAZARUS_B and NullItemID.ID_LAZARUS_B or NullItemID.ID_LAZARUS2_B
		_p:AddNullCostume(costume)
	else
		_p:ChangePlayerType(playerType)--Isaac.ExecuteCommand('addplayer '..playerType..' '..player.ControllerIndex)
	end
	if isIllusion then
		_p.Parent = player
		hud:AssignPlayerHUDs()
		
		for i=1, mod:GetMaxCollectibleID() do
			if not BlackList(i) and not CanBeRevived(playerType,i) then
				local itemConfig = Isaac.GetItemConfig()
				local itemCollectible = itemConfig:GetCollectible(i)
				if itemCollectible then
					if not _p:HasCollectible(i) and player:HasCollectible(i) and itemCollectible.Tags & ItemConfig.TAG_QUEST ~= ItemConfig.TAG_QUEST then
						if itemCollectible.Type ~= ItemType.ITEM_ACTIVE then
							for j=1, player:GetCollectibleNum(i) do
								_p:AddCollectible(i,0,false)
							end
						end
					end
				end
			end
		end
		for i = 2, 0, -1 do
			local c = _p:GetActiveItem(i)
			if c > 0 then
				_p:RemoveCollectible(c,false,i)
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

		d.IsIllusion = true
		if playerType == PlayerType.PLAYER_THEFORGOTTEN_B then
			local dl = mod.GetEntityData(_p:GetOtherTwin())
			dl.IsIllusion = true
			_p:GetOtherTwin().Parent = player:GetOtherTwin()
		end
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, _p.Position, Vector.Zero, _p)
	end
	_p:PlayExtraAnimation("Appear")
	_p:AddCacheFlags(CacheFlag.CACHE_ALL)
	_p:EvaluateItems()
	return _p
end

function mod:CloneCache(p,cache)
	local d = mod.GetEntityData(p)
	if d.IsIllusion then
		--local color = Color(0.518, 0.22, 1, 0.45)
		local s = p:GetSprite().Color
		local color = Color(s.R, s.G, s.B, 0.45,0.518, 0.15, 0.8)
		local s = p:GetSprite()
		s.Color = color
	else
		d = nil
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.CloneCache)

function mod:HackyLazWorkAround(player,cache)
	local d = mod.GetEntityData(player)
	if d.IsIllusion then
		if d.TaintedLazA == true then
			if cache == CacheFlag.CACHE_RANGE then
				player.TearRange = player.TearRange - 80
			end
		elseif d.TaintedLazB == true then
			if cache == CacheFlag.CACHE_DAMAGE then
				player.Damage = player.Damage * 1.50
			elseif cache == CacheFlag.CACHE_FIREDELAY then
				player.MaxFireDelay = player.MaxFireDelay + 1
			elseif cache == CacheFlag.CACHE_SPEED then
				player.MoveSpeed = player.MoveSpeed - 0.1
			elseif cache == CacheFlag.CACHE_LUCK then
				player.Luck = player.Luck - 2
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HackyLazWorkAround)

function mod:preIllusionHeartPickup(pickup, collider, low)
	local player = collider:ToPlayer()
	if player then
		local d = mod.GetEntityData(player)
		if d.IsIllusion or player.Parent then
			return pickup:IsShopItem()
		else
			d = nil
		end
		if pickup.Variant == PickupVariant.PICKUP_HEART and pickup.SubType == HeartSubType.HEART_ILLUSION then
			pickup.Velocity = Vector.Zero
			pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			pickup:GetSprite():Play("Collect", true)
			pickup:Die()
			mod:addIllusion(player, true)
			sfxManager:Play(PickupIllusionSFX,1,0,false)
			return true		
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.preIllusionHeartPickup)

function mod:preIllusionWhiteFlame(p, collider, low)
	if collider.Type == EntityType.ENTITY_FIREPLACE and collider.Variant == 4 then
		local d = mod.GetEntityData(p)
		if d.IsIllusion or p.Parent then
			p:Kill()
			p:AddMaxHearts(-p:GetMaxHearts())
			p:AddSoulHearts(-p:GetSoulHearts())
			p:AddBoneHearts(-p:GetBoneHearts())
			p:AddGoldenHearts(-p:GetGoldenHearts())
			p:AddEternalHearts(-p:GetEternalHearts())
			p:AddHearts(-p:GetHearts())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.preIllusionWhiteFlame)

function mod:postPickupInit(pickup)
	local rng = pickup:GetDropRNG()
	if pickup.SubType == HeartSubType.HEART_GOLDEN and pickup:GetSprite():GetAnimation() == "Appear" then
		if rng:RandomFloat() >= 0.5 then
			pickup:Morph(pickup.Type, pickup.Variant, HeartSubType.HEART_ILLUSION)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.postPickupInit, PickupVariant.PICKUP_HEART)

function mod:onUseBookOfIllusions(boi, rng, player, flags, slot, data)
	if GiantBookAPI then
		GiantBookAPI.playGiantBook("Appear", "Illusions.png", Color(0.2, 0.1, 0.3, 1, 0, 0, 0), Color(0.117, 0.0117, 0.2, 1, 0, 0, 0), Color(0, 0, 0, 0.8, 0, 0, 0), SoundEffect.SOUND_BOOK_PAGE_TURN_12)
	end
	sfxManager:Play(SoundEffect.SOUND_BOOK_PAGE_TURN_12, 1, 0, false, 1)
	mod:addIllusion(player, true)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUseBookOfIllusions, CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS)

function mod:onEntityTakeDamage(tookDamage, amount, flags, source, frames) 
	local data = mod.GetEntityData(tookDamage)
	if data.IsIllusion then
			--Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, tookDamage.Position, Vector.Zero, tookDamage)
			tookDamage:Kill() --doples always die in one hit, so the hud looks nicer. ideally i'd just get rid of the hud but that doesnt seem possible
			local p = tookDamage:ToPlayer()
			p:AddMaxHearts(-p:GetMaxHearts())
			p:AddSoulHearts(-p:GetSoulHearts())
			p:AddBoneHearts(-p:GetBoneHearts())
			p:AddGoldenHearts(-p:GetGoldenHearts())
			p:AddEternalHearts(-p:GetEternalHearts())
			p:AddHearts(-p:GetHearts())
	else
		mod:RemoveEntityData(tookDamage)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEntityTakeDamage, EntityType.ENTITY_PLAYER)

function mod:AfterDeath(e)
	if e.Type == EntityType.ENTITY_PLAYER then
		mod:RemoveEntityData(e)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.AfterDeath)

function mod:DarkEsau(e)
	if e.SpawnerEntity and e.SpawnerEntity:ToPlayer() then
		local p = e.SpawnerEntity:ToPlayer()
		local d = mod.GetEntityData(p)
		if d.IsIllusion then
			local s = e:GetSprite().Color
			local color = Color(s.R, s.G, s.B, 0.45,0.518, 0.15, 0.8)
			local s = e:GetSprite()
			s.Color = color
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.DarkEsau, EntityType.ENTITY_DARK_ESAU)

function mod:ClonesControls(entity,hook,action)
	if entity ~= nil and entity.Type == EntityType.ENTITY_PLAYER and not MCMIllusionsBombs then
		local p = entity:ToPlayer()
		local d = mod.GetEntityData(p)
		if d.IsIllusion then
			if (hook == InputHook.GET_ACTION_VALUE or hook == InputHook.IS_ACTION_PRESSED) and p:GetSprite():IsPlaying("Appear") then
				return hook == InputHook.GET_ACTION_VALUE and 0 or false
			end
			if hook == InputHook.IS_ACTION_TRIGGERED and (action == ButtonAction.ACTION_BOMB or action == ButtonAction.ACTION_PILLCARD or
			action == ButtonAction.ACTION_ITEM or p:GetSprite():IsPlaying("Appear")) then
				return false
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.ClonesControls)

function mod:GetMaxCollectibleID()
    return Isaac.GetItemConfig():GetCollectibles().Size -1
end

function mod.GetEntityData(entity,forgottenB)
	forgottenB = forgottenB or false
	if entity then
		if entity.Type == EntityType.ENTITY_PLAYER then
			local player = entity:ToPlayer()
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and forgottenB then
				player = player:GetOtherTwin()
			end
			local id = 1
			if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
				id = 2
			end
			local index = player:GetCollectibleRNG(id):GetSeed()
			if not pDataTable[index] then
				pDataTable[index] = {}
			end
			return pDataTable[index]
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			if not pDataTable[index] then
				pDataTable[index] = {}
			end
			return pDataTable[index]
		end
	end
	return nil
end

function mod:RemoveEntityData(entity,forgottenB)
	forgottenB = forgottenB or false
	if entity then
		if entity.Type == EntityType.ENTITY_PLAYER then
			local player = entity:ToPlayer()
			if not player then return end
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and forgottenB then
				player = player:GetOtherTwin()
			end
			local id = 1
			if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
				id = 2
			end
			local index = player:GetCollectibleRNG(id):GetSeed()
			if pDataTable[index] then
				pDataTable[index] = nil
			end
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			if pDataTable[index] then
				pDataTable[index] = nil
			end
		end
	end
end
