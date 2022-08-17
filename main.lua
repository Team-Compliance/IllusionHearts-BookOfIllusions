IllusionMod = RegisterMod("Illusion Hearts + Book of Illusions", 1)
local mod = IllusionMod
local json = require("json")

HeartSubType.HEART_ILLUSION = 9000
CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS = Isaac.GetItemIdByName("Book of Illusions")

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

function mod:Save(isSaving)
	if isSaving then
		local playersSave = { }
		for key,value in pairs(pDataTable) do
			if value ~= nil and key ~= nil then
				playersSave[tostring(key)] = value
			end
		end
		mod:SaveData(json.encode(playersSave))
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.Save)

function mod:Load(isLoading)
	pDataTable = {}
	if isLoading and mod:HasData() then
		local playersLoad = json.decode(mod:LoadData())
		for key,value in pairs(playersLoad) do
			if value ~= nil and key ~= nil then
				pDataTable[tonumber(key)] = value
			end
		end
		for i = 0, Game():GetNumPlayers()-1 do
			local p = Isaac.GetPlayer(i)
			local index = mod:GetEntityIndex(p)
			if pDataTable[index].IsIllusion then
				p:AddCacheFlags(CacheFlag.CACHE_ALL)
				p:EvaluateItems()
			else
				mod:RemoveEntityIndex(p)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.Load)

function mod:End(GameOver)
	if GameOver then
		pDataTable = {}
		mod:RemoveData()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, mod.End)

function mod:UpdateClones(p)
	local index = mod:GetEntityIndex(p)
	if pDataTable[index].IsIllusion then
		if p:IsDead() then
			p:ChangePlayerType(PlayerType.PLAYER_THELOST)
			p.Visible = false
			p:GetSprite():SetLastFrame()
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, p.Position, Vector.Zero, nil)
		end
		if p.Parent and not p.Parent:Exists() then
			p:Die()
		end
		p:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.UpdateClones)

function mod:addIllusion(player, isIllusion)
	local id = Game():GetNumPlayers() - 1
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_JACOB then 
		player = player:GetOtherTwin()
		playerType = PlayerType.PLAYER_ESAU 
	end
	
	Isaac.ExecuteCommand('addplayer '..playerType..' '..player.ControllerIndex)
	local _p = Isaac.GetPlayer(id + 1)
	local d = mod:GetEntityIndex(_p)
	if isIllusion then
		_p.Parent = player
		Game():GetHUD():AssignPlayerHUDs()
		
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
				_p:RemoveCollectible(c)
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
		
		pDataTable[d].IsIllusion = true
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, _p.Position, _p.Velocity, _p)
	end
	_p:AddCacheFlags(CacheFlag.CACHE_ALL)
	_p:EvaluateItems()
	return _p
end

function mod:CloneCache(p,cache)
	local d = mod:GetEntityIndex(p)
	if pDataTable[d].IsIllusion then
		local color = Color(0.518, 0.22, 1, 0.45)
		local s = p:GetSprite()
		s.Color = color
	else
		mod:RemoveEntityIndex(p)
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.CloneCache)

function mod:preIllusionHeartPickup(pickup, collider, low)
	local player = collider:ToPlayer()
	if player then
		local i = mod:GetEntityIndex(player)
		if pDataTable[i].IsIllusion then
			return false
		else
			mod:RemoveEntityIndex(player)
		end
		if pickup.SubType == HeartSubType.HEART_ILLUSION then
			pickup.Velocity = Vector.Zero
			pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			pickup:GetSprite():Play("Collect", true)
			pickup:Die()
			mod:addIllusion(player, true)
			return true		
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.preIllusionHeartPickup, PickupVariant.PICKUP_HEART)

function mod:postPickupInit(pickup)
	local rng = pickup:GetDropRNG()
	
	if pickup.SubType == HeartSubType.HEART_GOLDEN and player:GetSprite():GetAnimation() == "Appear" then
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
	mod:addIllusion(player, true)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUseBookOfIllusions, CollectibleType.COLLECTIBLE_BOOK_OF_ILLUSIONS)

function mod:onEntityTakeDamage(tookDamage, amount, flags, source, frames) 
	local data = mod:GetEntityIndex(tookDamage)
	
	if pDataTable[data].IsIllusion then
		if not (Game():GetRoom():GetType() == RoomType.ROOM_SACRIFICE and source.Type == 0 and flags & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES) then		
			tookDamage:Die() --doples always die in one hit, so the hud looks nicer. ideally i'd just get rid of the hud but that doesnt seem possible
			return false
		end
	else
		mod:RemoveEntityIndex(tookDamage)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEntityTakeDamage, EntityType.ENTITY_PLAYER)

function mod:PlayerDeath(e)
	local d = mod:GetEntityIndex(e)
	if not pDataTable[d].IsIllusion then
		for _,p in ipairs(Isaac.FindByType(EntityType.ENTITY_PLAYER,-1,e.SubType)) do
			local index = mod:GetEntityIndex(p)
			if pDataTable[index].IsIllusion then
				if GetPtrHash(p.Parent) == GetPtrHash(e) then
					p:Kill()
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.PlayerDeath, EntityType.ENTITY_PLAYER)

function mod:AfterDeath(e)
	if e.Type == EntityType.ENTITY_PLAYER then
		mod:RemoveEntityIndex(e)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.AfterDeath)

function mod:GetMaxCollectibleID()
    return Isaac.GetItemConfig():GetCollectibles().Size -1
end

function mod:GetEntityIndex(entity)
	if entity then
		if entity.Type == EntityType.ENTITY_PLAYER then
			local player = entity:ToPlayer()
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
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
			return index
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			if not pDataTable[index] then
				pDataTable[index] = {}
			end
			return index
		end
	end
	return nil
end

function mod:RemoveEntityIndex(entity)
	if entity then
		if entity.Type == EntityType.ENTITY_PLAYER then
			local player = entity:ToPlayer()
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
				player = player:GetOtherTwin()
			end
			local id = 1
			if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
				id = 2
			end
			local index = player:GetCollectibleRNG(id):GetSeed()
			pDataTable[index] = nil
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			pDataTable[index] = nil
		end
	end
end