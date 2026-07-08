--
-- Apply item effectlist entries to combat tracker when equipped (carried == 2).
--

local CARRIED_EQUIPPED = 2;

local _tEffectEditFields = {
	"effect_description",
	"label",
	"durmod",
	"durunit",
	"visibility",
	"actiononly",
};

function onInit()
	if not Session.IsHost then
		return;
	end

	for _, sItemListNodeName in pairs(ItemManager.getInventoryPaths("charsheet")) do
		registerInventoryHandlers("charsheet.*." .. sItemListNodeName);
	end
end

function onTabletopInit()
	if not Session.IsHost then
		return;
	end

	for _, nodeChar in ipairs(DB.getChildList("charsheet")) do
		ItemEffectsManager.refreshEquippedEffectsDisplay(nodeChar);
	end
end

function registerInventoryHandlers(sItemList)
	DB.addHandler(sItemList .. ".*.carried", "onUpdate", onInventoryCarriedChanged);
	DB.addHandler(sItemList .. ".*.isidentified", "onUpdate", onInventoryIdentifiedChanged);

	for _, sField in ipairs(_tEffectEditFields) do
		DB.addHandler(sItemList .. ".*.effectlist.*." .. sField, "onUpdate", onItemEffectEdited);
	end

	DB.addHandler(sItemList .. ".*.effectlist", "onChildAdded", onItemEffectListChanged);
	DB.addHandler(sItemList .. ".*.effectlist", "onChildDeleted", onItemEffectListChildDeleted);
	DB.addHandler(sItemList, "onChildDeleted", onInventoryItemDeleted);
end

function refreshEquippedEffectsDisplay(nodeChar)
	if not nodeChar then
		return;
	end

	local tLines = {};

	for _, sItemListNodeName in pairs(ItemManager.getInventoryPaths("charsheet")) do
		for _, nodeItem in ipairs(DB.getChildList(nodeChar, sItemListNodeName)) do
			if DB.getValue(nodeItem, "carried", 0) == CARRIED_EQUIPPED then
				local bIdentified = DB.getValue(nodeItem, "isidentified", 1) == 1;
				if bIdentified or Session.IsHost then
					local sItemName = DB.getValue(nodeItem, "name", "");
					for _, nodeRecordEffect in ipairs(DB.getChildList(nodeItem, "effectlist")) do
						local sVisibility = StringManager.trim(DB.getValue(nodeRecordEffect, "visibility", "")):lower();
						if Session.IsHost or sVisibility ~= "hide" then
							local sEffect = ItemEffectsManager.getEffectName(nodeRecordEffect);
							if sEffect ~= "" then
								if sItemName ~= "" then
									table.insert(tLines, sItemName .. ": " .. sEffect);
								else
									table.insert(tLines, sEffect);
								end
							end
						end
					end
				end
			end
		end
	end

	DB.setValue(nodeChar, "equippedeffects", "string", table.concat(tLines, "\n"));
end

function getEffectName(nodeRecordEffect)
	local sEffect = DB.getValue(nodeRecordEffect, "effect_description", "");
	if (sEffect or "") == "" then
		sEffect = DB.getValue(nodeRecordEffect, "label", "");
	end
	if (sEffect or "") == "" then
		return "";
	end
	return sEffect:gsub("%[", ""):gsub("%]", "");
end

function getGMOnlyFlag(rActor, nodeRecordEffect, bIdentified)
	if not bIdentified then
		return 1;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT and not ActorManager.isPC(rActor) and (DB.getValue(nodeCT, "tokenvis", 0) ~= 1) then
		return 1;
	end

	local sVisibility = StringManager.trim(DB.getValue(nodeRecordEffect, "visibility", "")):lower();
	if sVisibility == "hide" then
		return 1;
	end

	return 0;
end

function resolveActor(nodeItem)
	if not nodeItem then
		return;
	end

	local rActor = ActorManager.resolveActor(DB.getChild(nodeItem, "...")) or ActorManager.resolveActor(nodeItem);
	if not rActor then
		return;
	end

	ItemEffectsManager.updateItemEffects(rActor, nodeItem);
end

function updateItemEffects(rActor, nodeItem)
	if not rActor or not nodeItem then
		return;
	end

	local bEquipped = (DB.getPath(nodeItem):match("inventorylist") == nil) or (DB.getValue(nodeItem, "carried", 0) == CARRIED_EQUIPPED);
	local bIdentified = (DB.getPath(nodeItem):match("inventorylist") == nil) or (DB.getValue(nodeItem, "isidentified", 1) == 1);

	for _, nodeRecordEffect in ipairs(DB.getChildList(nodeItem, "effectlist")) do
		ItemEffectsManager.updateItemEffect(rActor, nodeRecordEffect, bEquipped, bIdentified);
	end
end

function updateItemEffect(rActor, nodeRecordEffect, bEquipped, bIdentified)
	local sLabel = ItemEffectsManager.getEffectName(nodeRecordEffect);
	if sLabel == "" then
		return;
	end

	local sItemSource = DB.getPath(nodeRecordEffect);
	local bFound = false;

	for _, nodeEffect in ipairs(ActorEffectManager.getCombatantEffectNodes(rActor)) do
		if DB.getValue(nodeEffect, "isactive", 0) ~= 0 then
			if EffectVarManager.getEffectVarFromNode(nodeEffect, "sSource", "") == sItemSource then
				bFound = true;
				if not bEquipped then
					EffectManager.removeEffectByNode(rActor, nodeEffect);
					break;
				end
			end
		end
	end

	if bFound or not bEquipped then
		return;
	end

	-- CoreRPG's DiceManager.evalDice expects a dice table, not a string.
	-- Item effects are permanent while equipped, so use the numeric durmod only.
	local nDuration = tonumber(DB.getValue(nodeRecordEffect, "durmod", 0)) or 0;

	local rEffect = {
		sLabel = sLabel,
		sName = sLabel,
		nDuration = nDuration,
		sUnits = DB.getValue(nodeRecordEffect, "durunit", ""),
		sSource = sItemSource,
		nGMOnly = ItemEffectsManager.getGMOnlyFlag(rActor, nodeRecordEffect, bIdentified),
		bSkipAnnounce = true,
	};

	EffectManager.addEffectByTable(rActor, rEffect);
end

function replaceEffects(rActor, nodeItem)
	if not rActor or not nodeItem then
		return;
	end

	for _, nodeEffect in ipairs(ActorEffectManager.getCombatantEffectNodes(rActor)) do
		local sEffSource = EffectVarManager.getEffectVarFromNode(nodeEffect, "sSource", "");
		local nodeEffSource = DB.findNode(sEffSource);
		if nodeEffSource and sEffSource:match("inventorylist") then
			if DB.getChild(nodeEffSource, "...") == nodeItem then
				EffectManager.removeEffectByNode(rActor, nodeEffect);
			end
		end
	end

	ItemEffectsManager.resolveActor(nodeItem);
end

function checkEffectsAfterDelete(rActor)
	if not rActor then
		return;
	end

	for _, nodeEffect in ipairs(ActorEffectManager.getCombatantEffectNodes(rActor)) do
		local sEffSource = EffectVarManager.getEffectVarFromNode(nodeEffect, "sSource", "");
		if (sEffSource or "") ~= "" and sEffSource:match("inventorylist") and not DB.findNode(sEffSource) then
			EffectManager.removeEffectByNode(rActor, nodeEffect);
		end
	end
end

function refreshEquippedItems(nodeRecord)
	if not nodeRecord then
		return;
	end

	for _, sItemListNodeName in pairs(ItemManager.getInventoryPaths("charsheet")) do
		for _, nodeItem in ipairs(DB.getChildList(nodeRecord, sItemListNodeName)) do
			if DB.getValue(nodeItem, "carried", 0) == CARRIED_EQUIPPED then
				ItemEffectsManager.resolveActor(nodeItem);
			end
		end
	end

	ItemEffectsManager.refreshEquippedEffectsDisplay(nodeRecord);
end

function onInventoryCarriedChanged(nodeField)
	local nodeItem = DB.getParent(nodeField);
	ItemEffectsManager.resolveActor(nodeItem);
	ItemEffectsManager.refreshEquippedEffectsDisplay(DB.getChild(nodeItem, "..."));
end

function onInventoryIdentifiedChanged(nodeField)
	local nodeItem = DB.getParent(nodeField);
	ItemEffectsManager.onItemEquippedChanged(nodeItem);
	ItemEffectsManager.refreshEquippedEffectsDisplay(DB.getChild(nodeItem, "..."));
end

function onItemEffectEdited(nodeField)
	local nodeItem = DB.getChild(nodeField, "....");
	ItemEffectsManager.onItemEquippedChanged(nodeItem);
	ItemEffectsManager.refreshEquippedEffectsDisplay(DB.getChild(nodeItem, "..."));
end

function onItemEffectListChanged(nodeEffectList)
	local nodeItem = DB.getParent(nodeEffectList);
	ItemEffectsManager.onItemEquippedChanged(nodeItem);
	ItemEffectsManager.refreshEquippedEffectsDisplay(DB.getChild(nodeItem, "..."));
end

function onItemEquippedChanged(nodeItem)
	if not nodeItem then
		return;
	end

	if DB.getValue(nodeItem, "carried", 0) ~= CARRIED_EQUIPPED then
		return;
	end

	local rActor = ActorManager.resolveActor(DB.getChild(nodeItem, "..."));
	ItemEffectsManager.replaceEffects(rActor, nodeItem);
end

function onItemEffectListChildDeleted(nodeEffectList)
	local nodeItem = DB.getParent(nodeEffectList);
	local nodeChar = DB.getChild(nodeItem, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	ItemEffectsManager.checkEffectsAfterDelete(rActor);
	ItemEffectsManager.refreshEquippedEffectsDisplay(nodeChar);
end

function onInventoryItemDeleted(nodeInventoryList)
	local nodeChar = DB.getParent(nodeInventoryList);
	local rActor = ActorManager.resolveActor(nodeChar);
	ItemEffectsManager.checkEffectsAfterDelete(rActor);
	ItemEffectsManager.refreshEquippedEffectsDisplay(nodeChar);
end