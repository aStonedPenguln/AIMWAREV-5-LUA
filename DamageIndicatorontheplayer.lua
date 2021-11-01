local ref = gui.Reference("Visuals", "World", "Extra");
local hitmarkerCheckbox = gui.Checkbox(ref, "lua_hitmarker", "Hit Indicators", true); 
local fadeTime = gui.Slider(ref, "lua_hitmarker_size_combo", "Fade Time", 1, 0.2, 5);


hitPositions = {};
hitTimes = {};
hitTypes = {};
hitText = {};
bulletImpactPositions = {};
deltaTimes = {};

local hitCount = 0;
local newHitCount = 0;
local bulletImpactCount = 0;
local hitFlag = false;



local function AddHit(hitPos, type, text)
    table.insert(hitPositions, hitPos);
    table.insert(hitTimes, globals.CurTime());
    table.insert(hitTypes, type);
	table.insert(hitText, text);
    hitCount = hitCount + 2;
end

local function RemoveHit(index)
    table.remove(hitPositions, index);
    table.remove(hitTimes, index);
    table.remove(hitTypes, index);
    table.remove(deltaTimes, index);
	table.remove(hitText, index);
    newHitCount = newHitCount - 1;
end

local function GetClosestImpact(point)
    local bestImpactIndex;
    local bestDist = 11111111111;
    for i = 0, bulletImpactCount, 1 do
        if (bulletImpactPositions[i] ~= nil) then
            local delta = bulletImpactPositions[i] - point;
            local dist = delta:Length();
            if (dist < bestDist) then
                bestDist = dist;
                bestImpactIndex = i;
            end
        end
    end

    return bulletImpactPositions[bestImpactIndex];
end

local function hFireGameEvent(GameEvent)
	local dmg = GameEvent:GetInt("dmg_health");
    if (GameEvent:GetName() == "bullet_impact") then
        local attacker = entities.GetByUserID(GameEvent:GetInt("userid"));
        if (attacker ~= nil and attacker:GetName() == entities.GetLocalPlayer():GetName()) then
            hitFlag = true;
            local hitPos = Vector3(GameEvent:GetFloat("x"), GameEvent:GetFloat("y"), GameEvent:GetFloat("z"));
            table.insert(bulletImpactPositions, hitPos);
            bulletImpactCount = bulletImpactCount + 1;
        end

    elseif (GameEvent:GetName() == "player_hurt") then
        local victim = entities.GetByUserID(GameEvent:GetInt("userid"));
        local attacker = entities.GetByUserID(GameEvent:GetInt("attacker"));
        if (attacker ~= nil and victim ~= nil and attacker:GetName() == entities.GetLocalPlayer():GetName() and victim:GetTeamNumber() ~= entities.GetLocalPlayer():GetTeamNumber()) then
            local hitGroup = GameEvent:GetInt("hitgroup");
            if (hitFlag) then
                hitFlag = false;
                local impact = GetClosestImpact(victim:GetHitboxPosition(hitGroup));
                AddHit(impact, 0, tostring(dmg));
                bulletImpactPositions = {};
                bulletImpactCount = 0;
            end
        end
    end
end



fonttap = draw.CreateFont("Impact", 16)
local function hDraw()
    if (hitmarkerCheckbox:GetValue() and entities.GetLocalPlayer() ~= nil) then
        newHitCount = hitCount;
        for i = 0, hitCount, 1 do
            if (hitTimes[i] ~= nil and hitPositions[i] ~= nil and hitTypes[i] ~= nil) then
                local deltaTime = globals.CurTime() - hitTimes[i];
                if (deltaTime > fadeTime:GetValue()) then
                    RemoveHit(i);
                    goto continue;
                end

                if (hitTypes[i] == 1) then
                    hitPositions[i].z = hitPositions[i].z + deltaTime / headshotSpeed;
                end

                local xHit, yHit = client.WorldToScreen(hitPositions[i]);
                if xHit ~= nil and yHit ~= nil then
                    local alpha;
                    if (deltaTime > fadeTime:GetValue() / 2) then
                        alpha = (1 - (deltaTime - deltaTimes[i]) / fadeTime:GetValue() * 2) * 255;
                        if (alpha < 0) then
                            alpha = 0
                        end
                    else
                        table.insert(deltaTimes, i, deltaTime)
                        alpha = 255;
                    end
						draw.SetFont(fonttap)
						draw.Color(23, 23, 23, 255);
						draw.Text(xHit + 1, yHit + 2, hitText[i])
                        draw.Color(0, 255, 0, 255);
						draw.Text(xHit, yHit, hitText[i])
				end
            end

            ::continue::
        end

        hitCount = newHitCount;
    end
end

client.AllowListener("bullet_impact");
client.AllowListener("player_hurt");
callbacks.Register("FireGameEvent", hFireGameEvent);
callbacks.Register("Draw", hDraw);
