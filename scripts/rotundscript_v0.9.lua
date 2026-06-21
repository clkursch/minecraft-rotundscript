local pehkui = require('scripts.api.Pehkui')

-- IMPORTANT NOTE!!! For this script to work you need to go into your figura settings, and under the "dev" section and turn "CHAT MESSAGES" to "ON"
-- Also Don't foget to click "Upload Avatar to Cloud" in the figura menu, so other players can see your avatar
-- Ctrl-F and search for "-- ((CONFIGURE)) --" to find places in the script with configurables you may want to edit

-- ((CONFIGURE)) --
local crouchSqzEnabled = true --SET THIS TO "false" IF YOU DON'T WANT THE CROUCH-SQUEEZING FEATURE
local squeezeLoop = sounds["sounds.squeezesLOOP1"]:loop(true) --THIS IS THE SQUEEZE SFX FILE NAME. YOU CAN REPLACE IT WITH YOUR OWN .OGG FILE IF YOU WANT. IF IT'S TOO BIG YOU MIGHT NEED TO COMPRESS IT

local complexFoodTracking = false --Only enable this if using the "AlwaysEat" and "Saturation_Plus" mods AND the hungerLimitsSaturation gamerule is true (/gamerule hungerLimitsSaturation true)
--If you are using the default food tracking, or have unlimited saturation with mods, keep this as "false"

-- ((OK DON'T CONFIGURE THE REST OF THESE))
local myWidthMult = 1
local jumpMod = 1 --THIS ONES EITHER 1 OR 0 DEPENDING ON IF STUCK 
local lastJumpMod = 1
local moveMod = 1 --SAME, 0 OR 1 (why didn't I just make these booleans)
local lastMoveMod = 1
local squeezeVal --DISTANCE BETWEEN OUR HIPS AND THE WALLS. SMALLER NUM MEANS TIGHTER SQUEEZE. 
local isNarrowSqueezed = false
local lastSqueezed = false
local lastWeightStage = -1 --TO FORCE A WEIGHT CHANGE ON LOAD
local struggleFlag = false --DELAYED START TO STRUGGLE WHILE STUCK
local struggleTimer = 0 --HOW MANY FRAMES TO STRUGGLE
local myFoodPoints = 0
local lateUpdateFlag
local crouchSqzTick = 0
local crouchSqz = false
local lastCrouchSqz = false
local lastInWater = false
local mainWidth = 0.6 --TRACK HITBOX WIDTH EXCLUDING CROUCHSEQUEEZE
local lastBoundingX = 0.6
local lastY = 0

local playSqueezeSfx = false
local lastPlaySqueezeSfx = false
local stepTime = 0

local syncPingTimer = 0 -- Used to sync the weight variables with players that joined a server and haven't gotten pinged yet
local prevFood
local prevSaturation

local stored_step_sound
local stored_secondary_step_sound


function updateWeightGraphics(stage)
	
	-- ((CONFIGURE)) --
	--Everything in this function is for graphical changes to your model at each weight stage
	--If you're using the slugcat model I included, then you can keep the script in this function and just change the numbers to your liking
	--If you're using a different model you'll need to replace the script here with script that works with your model
	--If you already handle your resizing elsewhere you can just delete everything in this function and leave it empty
	
	pehkui.setScale("pehkui:model_width", 1) --A QUICK LAZY WAY TO CHANGE THE WIDTH OF YOUR WHOLE MODEL. WORKS ON ANY MODEL
	
	--EVERYTHING ELSE IS SLUGCAT SPECIFIC
	--SHOW THE > < EYES WHEN SQUEEZED 
	models.models.slugcat.FullBody.UpperBody.head.Main.Eyes.Base:setVisible(lastSqueezed == false)
	models.models.slugcat.FullBody.UpperBody.head.Main.Eyes.Squint:setVisible(lastSqueezed) 
	models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setVisible(true) --ASSUME THIS IS TRUE UNLESS TOLD OTHERWISE
	
	
	if stage <= 0 then
	
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setVisible(false)
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(1.0, 1, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.0, 1.0, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(1.0, 1.0, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,1,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.0, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(0.5, 0.5, 0.5) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(1.0, 1, 1.0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(1.0, 1, 1.0)
		-- models.models.slugcat.FullBody.LowerBody.LeftLeg.Main.Base.Upper.Main:setScale(1.7, 1, 1) --NAH JUST MAKE THE MODELS THIGH BIGGER
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-0.5, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(0.5, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(0.0, 0, 0) --RIGHT ARM IS STUCK! TRY AND FIX THAT...
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(0, -0.25, 0)
		-- models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setPos(20, 20, 0) --WON'T MOVE FOR SOME REASON...
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.0, 1.0, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.0, 1.0, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 0.0)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(1.0, 1.0, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(1, 1, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(1, 1, 1)
		
	elseif stage == 1 then
		
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(1.2, 1, 1.3)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.0, 1.0, 1.2)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(1.2, 1.0, 1.4)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,1.5,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.0, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(0.5, 0.5, 0.5) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(1.35, 1, 1.0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(1.35, 1, 1.0)
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-1.0, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(1.0, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(0.5, 0, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(-1, -0.25, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, -15)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 15)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.1, 1.1, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.1, 1.1, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(1.25, 1.25, 1.0)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(0.9, 0.9, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(0.9, 0.9, 1)
		
	elseif stage == 2 then
		
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(1.2, 1, 1.2)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.2, 1.0, 1.4)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(1.44, 1.0, 1.4)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,2,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.0, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(1.0, 0.5, 1.0) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(1.6, 1, 1.25)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(1.6, 1, 1.25)
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-1.5, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(1.5, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(1, 1.0, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(-2, -0.75, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, -30)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 30)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.25, 1.25, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.25, 1.25, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 2.0)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(1.5, 1.5, 1.1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(0.8, 0.8, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(0.8, 0.8, 1)
		
	elseif stage == 3 then
		
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(2.0, 1, 2.0)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.0, 1.0, 1.1)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(2.0, 1.0, 1.8)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,3,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.1, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(1.4, 1.0, 1.4) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-2, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(2, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(2, 1.0, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(-4, -0.75, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, -45)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 45)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.5, 1.5, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.5, 1.5, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 2.5)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(1.8, 1.8, 1.2)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(0.8, 0.8, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(0.8, 0.8, 1)
		
	elseif stage == 4 then
		
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(2.5, 1, 2.5)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.0, 1.0, 1.1)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(2.2, 1.0, 2)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,3,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.2, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(1.8, 1.2, 1.8) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-2, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(2, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(2, 2.25, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(-4, -1, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, -65)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 65)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.5, 1.5, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.5, 1.5, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 3)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(2, 2, 1.2)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(0.8, 0.8, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(0.8, 0.8, 1)
	elseif stage == 5 then
		
		models.models.slugcat.FullBody.UpperBody.Body.Main:setScale(2.5, 1, 2.5)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Gourmand:setScale(1.0, 1.0, 1.1)
		models.models.slugcat.FullBody.UpperBody.Body.Chestplate:setScale(2.2, 1.0, 2)
		models.models.slugcat.FullBody.UpperBody.Body.Main.Bottom:setScale(1,3,1) --UNDERSIDE
		
		models.models.slugcat.FullBody.UpperBody.head.Main.Base:setScale(1.2, 1, 1) --HEAD
		models.models.slugcat.FullBody.UpperBody.head.Main.Gourmand.Snout:setScale(1.8, 1.2, 1.8) --NECK ROLL
		
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setScale(2, 1, 1.5)
		models.models.slugcat.FullBody.LowerBody.LeftLeg:setPos(-2, 0, 0)
		models.models.slugcat.FullBody.LowerBody.RightLeg:setPos(2, 0, 0)
		
		models.models.slugcat.FullBody.UpperBody.Arms:setPos(2, 2.25, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setPos(-4, -1, 0)
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setRot(0, 0, -65)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setRot(0, 0, 65)
		
		models.models.slugcat.FullBody.UpperBody.Arms.LeftArm:setScale(1.5, 1.5, 1)
		models.models.slugcat.FullBody.UpperBody.Arms.RightArm:setScale(1.5, 1.5, 1)
		
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setPos(0, 0, 3)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1:setScale(2, 2, 1.2)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2:setScale(0.8, 0.8, 1)
		models.models.slugcat.FullBody.UpperBody.Body.Tail1.Tail2.Tail3:setScale(0.8, 0.8, 1)
		
		pehkui.setScale("pehkui:model_width", 1.25)
	end
	--FEEL FREE TO PASTE MORE WEIGHT STAGES IN AS NEEDED, OR REMOVE UNWANTED ONES.
	--DON'T FORGET THE NUMBER OF WEIGHT STAGES IN HERE SHOULD MATCH THE NUMBER OF WEIGHT STAGES DOWN IN THE "updateWeightStats" AND "weightStage" FUNCTIONS
	
end



--KEYBINDS
-- ((CONFIGURE)) -- CROUCH-SQUEEZE IS BOUND TO THE SNEAK KEY BY DEFAULT, BUT YOU COULD CHANGE IT TO ANYTHING! FOR EXAMPLE: REPLACING  keybinds:getVanillaKey("key.sneak")  WITH  "key.keyboard.h"
local crSqueezeKey = keybinds:newKeybind("Crouchsqueeze", keybinds:getVanillaKey("key.sneak")) 
local struggleKey = keybinds:newKeybind("Struggle", keybinds:getVanillaKey("key.jump"))
local crSqueezeKeyState = false

--RUNS ON STARTUP AND RELOAD
function events.entity_init()
    prevFood = player:getFood()
	prevSaturation = player:getSaturation()
	myFoodPoints = player:getFood() + player:getSaturation()
	-- struggleKey.press = pings.strugglePing --OKAY DON'T ATTACH PINGS DIRECTLY TO A KEYBIND
	struggleKey.press = struggleCheck
	crSqueezeKey.press = function() crSqueezeKeyState = true end
	crSqueezeKey.release = function() crSqueezeKeyState = false end
	lastWeightStage = -1 --TO FORCE A WEIGHT CHANGE ON LOAD
	setWeight()
	-------------
end


function events.tick()
	
	isNarrowSqueezed = updateNarrowSqueezed() --OKAY WE SHOULD ONLY BE RUNNING THIS ONCE A TICK NOW IT'S SO EXPENSIVE
	
	--OK FR, THIS ONLY NEEDS TO BE RUN BY THE HOST
	if host:isHost() then
		--RESET OUR FOOD AND WEIGHT LEVELS ON DEATH
		if player:isAlive() == false then
			prevFood = 20
			prevSaturation = 5
			myFoodPoints = 0
			return end --AND THEN SKIP EVERYTHING UNDER THIS
		
		
		if struggleTimer > -10 then --GIVE US A CHANCE TO JUMP AFTER STRUGGLING WHILE STANDING STILL
			struggleTimer = struggleTimer - 1
		end
		
		--ALLOW US TO SHRINK OUR HITBOX SLIGHTLY IF WE CROUCH LONG ENOUGH.
		lastCrouchSqz = crouchSqz
		if crSqueezeKeyState and crouchSqzEnabled then --player:getPose() == "CROUCHING" 
			crouchSqzTick = crouchSqzTick + 1
			if crouchSqzTick >= 20 then
				crouchSqz = true
			end
		elseif crouchSqz and canUncrouch() then
			crouchSqz = false
			crouchSqzTick = 0
		end
		
		
		----- WEIGHT GAIN SCRIPT ---------
		syncPingTimer = syncPingTimer + 1
		if (syncPingTimer >= 80 and isNarrowSqueezed == false) then
			setWeight()
			syncPingTimer = 0
		end
		
		--COMPLEX FOOD TRACKING FOR FOOD EATEN PAST MAX
		if complexFoodTracking then
			-- Gain weight through food consumption
			if (player:getFood() > prevFood or player:getSaturation() > prevSaturation) or 
				((player:getFood() < prevFood and player:getFood() < 20) or (player:getSaturation() < prevSaturation and player:getSaturation() < 20)) then --MODIFIED TO ACCOUNT FOR WEIGHT LOSS TOO
				local amount = player:getFood() - prevFood + player:getSaturation() - prevSaturation -- Get number of points increased
				myFoodPoints = myFoodPoints + amount
				-- print("FOOD POINTS: " .. tostring(myFoodPoints))
			end
			prevFood = player:getFood()
			prevSaturation = player:getSaturation()
			
			--SLOWLY LOSE WEIGHT IF ABOVE THE NORMAL CAP
			if myFoodPoints > (player:getFood() + player:getSaturation()) and syncPingTimer == 0 then 
				-- CONFIGURE -- (ONLY IF USING COMPLEX FOOD TRACKING) ADJUST HOW FAST YOU LOSE EXCESS WEIGHT
				local lossRate = 1.0 --SUBTRACT THIS MANY FOOD POINTS EVERY ~4 SECONDS
				--local lossRate = 1.0 * weightStage() --YOU MIGHT CONSIDER SOMETHING LIKE THIS IF YOU WANT TO LOSE WEIGHT FASTER AT HIGHER WEIGHT STAGES
				myFoodPoints = myFoodPoints - lossRate
			end
		end
		----------------------------------
		
		
		-- KEEP TRACK OF OUR MODEL'S CANON WIDTH. THE SIZING PROCESS TWEENS SO WE HAVE TO CHECK THIS EVERY TICK :/
		if crouchSqz == false and player:getBoundingBox().x == lastBoundingX then --DON'T RUN IF THE VALUE IS CHANGING. WAIT UNTIL THE TWEEN IS DONE
			mainWidth = player:getBoundingBox().x
		elseif crouchSqz == true then
			lastBoundingX = mainWidth
		else
			lastBoundingX = player:getBoundingBox().x
		end
		
		if lastSqueezed ~= isNarrowSqueezed then
			lateUpdateFlag = true --OKAY THIS WAS GONNA BOTHER ME. AVOID RUNNING THE UPDATE 2 TICKS IN A ROW WHEN CHANGING SQUEEZE STATES
		end
		
		if lastWeightStage ~= weightStage() or lastJumpMod ~= jumpMod or lastMoveMod ~= moveMod or lastCrouchSqz ~= crouchSqz or lastInWater ~= player:isInWater() then
			setWeight()
		end
		
		
		if isNarrowSqueezed then
			--ONLY PLAY THE SQUEEZE SOUND WHILE MOVING
			if isKindaMoving() then
				playSqueezeSfx = true
			else
				playSqueezeSfx = false
			end
			
			--IF ONLY LIGHTLY SQUEEZED, WE DON'T COME TO A HALT
			if squeezeVal <= 0.14 and struggleTimer <= 0 then --STUCK. UNTIL THE TIMER RESETS WHEN WE AREN'T SQUEEZED
				moveMod = 0
				if isKindaMoving() == false and struggleTimer <= -10 then
					jumpMod = 0 --STOP JUMPING UNTIL WE SQUEEZE FREE
				end
			end
		else
			moveMod = 1
			jumpMod = 1
			playSqueezeSfx = false
		end
		
		
		
		--OKAY NOW RUN A SQUEEZE RELATED WEIGHT UPDATE, IF WE DIDN'T ALREADY
		if lateUpdateFlag then
			setWeight()
		end
		
		if struggleFlag then
			if struggleFlag then --and player:getPose() ~= "SWIMMING" then
				jumpMod = 1
			end
			struggleFlag = false
		end
		
		--ONLY PING THE SQUEEZE SFX IF IT CHANGED
		if lastPlaySqueezeSfx ~= playSqueezeSfx then
			pings.squeezeSfxPing(playSqueezeSfx)
			lastPlaySqueezeSfx = playSqueezeSfx
		end
	end
	
	-- THE REST OF THIS RUNS FOR ALL PLAYERS --
	
	--OKAY FINE RUN IT EVERY TICK THEN. FUCK YOU
	if playSqueezeSfx then
		squeezeLoop:play()
		squeezeLoop:setPos(player:getPos())
		--ADJUST PITCH AND VOLUME BASED ON TIGHTNESS
		if squeezeVal <= 0.08 then
			squeezeLoop:setVolume(1)
			squeezeLoop:setPitch(0.7)
		elseif squeezeVal <= 0.14 then
			squeezeLoop:setVolume(1)
			squeezeLoop:setPitch(0.85)
		else
			squeezeLoop:setVolume(0.6)
			squeezeLoop:setPitch(1)
		end
	else
		squeezeLoop:pause()
	end
	
	
	--IF WE'RE IMMOBILE MINING SPEED IS BROKE FOR SOME REASON. UNDO THAT.
	if mm == 0 and player:isMoving() == false then
		pehkui.setScale("pehkui:mining_speed", 6)
	else
		pehkui.setScale("pehkui:mining_speed", 1)
		pehkui.setScale("pehkui:mining_speed", 1)
	end
	
	
	--RECREATE OUR FOOTSTEPS BECAUSE WE DISABLED THE VANILLA ONES BECAUSE THEY BROKE. MODIFIED FROM THE WG_TEMPLATE
	-- Use a timer to determine step sound times
    if (player:isOnGround()) then
        stepTime = stepTime + player:getVelocity():length()
	elseif player:isClimbing() then --and player:getPos().y - lastY < 0.01  --THE SERVER DOESN'T CALCULATE OUR VELOCITY CORRECTLY ON LADDERS, SO WE HAVE TO CHECK Y VALUES INSTEAD
		stepTime = stepTime + player:getVelocity():length() * 1.5
		lastY = player:getPos().y 
    end
    if (stepTime >= 1.625) then
        stepTime = stepTime % 1.625
		if (player:getVelocity():length() > 0.01) then --AN ATTEMPT TO GET CLIENTS TO STOP RUNNING FOOTSTEPS WHILE STILL --IDK IF IT WORKED...
			PlayFootstep() --MAYBE LATER WE'LL BRING THIS BACK BUT RIGHT NOW OTHER PLAYERS CAN'T EVEN HEAR IT
		end
    end
	
end

function struggleCheck()
	if isNarrowSqueezed then
		if isKindaMoving() == false then 
			struggleTimer = 3 --MODIFY THIS VALUE TO DETERMINE HOW LONG YOUR STRUGGLE BOOSTS LAST
			moveMod = 1
			struggleFlag = true --WE NEED TO DELAY THIS A TICK OTHERWISE WE'LL JUMP
			pehkui.setScale("pehkui:jump_height", 0.0)
		end
	end
end


function isKindaMoving()
	return player:getVelocity():length() >= 0.003  --player:isMoving()
end


function pings.squeezeSfxPing(command)
	playSqueezeSfx = command
end


--CHECK IF A PHYSICAL BLOCK COLLISION EXISTS AT A SPECIFIC COORDINATE
function checkColRaycast(x, y, z)
	
	local startPos = player:getPos()
	local endPos = startPos + vec(x, y, z)
    local hit, rayendpos, side = raycast:block(startPos, endPos)
	
	return rayendpos
end


--DETECT IF THERE ARE BLOCKS AT BOTH SIDES OF EITHER AXIS
function updateNarrowSqueezed()
	
	--WAIT WHAT IF I MEASURED THE DISTANCE INSTEAD......
	local distCheck = 2 + mainWidth --KIND OF ARBITRARY BUT LONG ENOUGH TO NOT BE AN ISSUE AND SHORT ENOUGH TO REDUCE COST
	local yCheck = player:getEyeHeight() * 0.5 --PROBABLY A GOOD INDICATOR OF WHERE THEIR HIPS ARE
	
	local xPass = (checkColRaycast(distCheck, yCheck, 0).x - checkColRaycast(-distCheck, yCheck, 0).x) - mainWidth
	local zPass = (checkColRaycast(0, yCheck, distCheck).z - checkColRaycast(0, yCheck, -distCheck).z) - mainWidth
	local yPass = 2
	
	--BONUS CHECK IF WE'RE CRAWLING, CHECK FOR ROOM ABOVE US
	if player:getPose() == "SWIMMING" then
		distCheck = player:getBoundingBox().y + 2
		yPass = checkColRaycast(0, distCheck, 0).y - checkColRaycast(0, -distCheck, 0).y - player:getBoundingBox().y
	end
	
	squeezeVal = math.min(xPass, zPass, yPass) --TAKE WHICHEVER IS LOWER
	-- print ("GAP " .. squeezeVal)
	
	return (squeezeVal < 0.2)
end

--DETECT IF THERE'S A BLOCK DIRECTLY ABOVE OUR HEAD.
function canUncrouch()
	local distCheck = 0.65 * myWidthMult
	return world.getBlockState(player:getPos():add(distCheck, 1.1, distCheck)):isSolidBlock() == false
		and world.getBlockState(player:getPos():add(-distCheck, 1.1, distCheck)):isSolidBlock() == false
		and world.getBlockState(player:getPos():add(distCheck, 1.1, -distCheck)):isSolidBlock() == false
		and world.getBlockState(player:getPos():add(-distCheck, 1.1, -distCheck)):isSolidBlock() == false
		and squeezeVal > 0
end



--FIRST CALL THE ONE THAT RUNS LOCALLY
function setWeight()
	pings.setWeight(weightStage(), isNarrowSqueezed, moveMod, jumpMod, crouchSqz, wet) --THEN RUN THE PING THAT RUNS ON THE SERVER
end

function pings.setWeight(amount, squeezed, mm, jm, crSqz)
    -- print("pings.setWeight " .. tostring(amount) .. " " .. tostring(squeezed) .. " " .. tostring(mm) .. " " .. tostring(jm) .. " " .. tostring(crSqz))
	updateWeightStats(amount, squeezed, mm, jm, crSqz, player:isInWater())
	isNarrowSqueezed = squeezed --UPDATE FOR OTHER CLIENTS (I don't think it worked)
end


function updateWeightStats(stage, squeezed, mm, jm, crSqz, wet) --OKAY WE NEED TO TAKE OUR SQUEEZED BOOL INTO ACCOUNT AND 'ONLY' RUN MOVEMENT SCALING IN HERE TO AVOID SPEED DESYNCS AND SERVER FALL DAMAGE
	-- print("UPDATE WS " .. tostring(stage))
	local mySpeedMult = 1
	local myHeightMult = 1
	local myJumpMult = 1
	
	--SOME NOTABLE WIDTH VALUES:
	--1.0  default
	--1.08 slightly squeezes in open doorways (slowed, but not stuck)
	--1.14 tight squeezes in open doorways (slowed and stuck)
	--1.28 barely fits through open doorways (slowed more and stuck quicker)
	--1.37 slightly squeezes in 1 block wide gaps (does not fit open doorways)
	--1.45 tight squeezes in 1 block wide gaps
	--1.60 barely fits through 1 block wide gaps
	--(THEN YOU WON'T GET STUCK IN MUCH UNTIL YOU'RE BIG ENOUGH TO GET STUCK IN 2 BLOCK GAPS)
	--2.40 slightly squeezes in open double-doorways
	--2.50 tight squeezes in open double-doorways
	--2.60 barely fits through open double-doorways
	--(ETC.. JUST KEEP INCREASING THE NUMBER)
	
	--WHEN CROUCH-SQUEEZING, TIGHTNESS IS CALCULATED USING YOUR UN-CROUCH-SQUEEZED WEIGHT. SO IF YOU HAVE TO CROUCH-SQUEEZE TO ENTER A GAP IT WILL ALWAYS BE VERY TIGHT
	
	
	-- ((CONFIGURE)) -- WEIGHT STAGES; MODIFY YOUR STATS BELOW TO DETERMINE WHAT YOU GET AT EACH WEIGHT STAGE
	if stage <= 0 then
		mySpeedMult = 1
		myWidthMult = (1)
		myHeightMult = ((crSqz and 0.5) or 0.6) --0.6 IS FOR SLUGCAT HEIGHT. SET TO "1" FOR DEFAULT PLAYER HITBOX HEIGHT
	elseif stage == 1 then
		mySpeedMult = 0.9
		myWidthMult = ((crSqz and 1.0) or 1.14) --THE FIRST NUMBER IS FOR WHEN YOURE CROUCH-SQUEEZING. THE SECOND NUMBER IS FOR EVERYTHING ELSE
		myHeightMult = ((crSqz and 0.5) or 0.6)
	elseif stage == 2 then
		mySpeedMult = 0.85
		myWidthMult = ((crSqz and 1.0) or 1.28)
		myHeightMult = ((crSqz and 0.5) or 0.6)
	elseif stage == 3 then
		mySpeedMult = 0.8
		myWidthMult = ((crSqz and 1.1) or 1.45)
		myHeightMult = ((crSqz and 0.5) or 0.6)
	elseif stage == 4 then
		mySpeedMult = 0.75
		myWidthMult = ((crSqz and 1.28) or 1.60)
		myHeightMult = ((crSqz and 0.5) or 0.6)
	elseif stage == 5 then
		mySpeedMult = 0.5
		myWidthMult = ((crSqz and 1.60) or 2)
		myHeightMult = ((crSqz and 0.5) or 0.6)
	end
	--FEEL FREE TO ADD OR REMOVE WEIGHT STAGES HOWEVER YOU'D LIKE. DON'T FORGET TO MAKE THOSE SAME CHANGES TO THE "weightStage()" FUNCTION BELOW
	--THERE ARE OTHER STATS YOU MIGHT CONSIDER ADDING INTO WEIGHT STAGES TOO...
	-- pehkui.setScale("pehkui:defense", 1)
	-- pehkui.setScale("pehkui:knockback", 1)
	
	
	pehkui.setScale("pehkui:hitbox_height", myHeightMult)
	pehkui.setScale("pehkui:eye_height", myHeightMult)
	
	--REDUCE SPEED VALUES WHEN SQUEEZED
	if squeezed then
		if squeezeVal < 0 then --(YES, IT CAN BE NEGATIVE WHILE CROUCH-SQUEEZED)
			mySpeedMult = mySpeedMult * 0.1
		else
			mySpeedMult = mySpeedMult * 0.4
		end
	end
	
	--REDUCED FRICTION WHEN IN WATER.
	if wet and mm == 0 then
		mySpeedMult = mySpeedMult / 2
		mm = 1 --NO STOPPING COMPLETELY
	end
	
	--SQUEEZE TO A MORE SUDDEN HALT FOR TIGHTER SQUEEZES.
	if mm == 0 and isKindaMoving() then 
		if squeezeVal < 0 then --TIGHTEST SQUEEZE 
			pehkui.setScale("pehkui:motion", 0.1)
			pehkui.setScale("pehkui:motion", 0.1)
		elseif squeezeVal < 0.08 then --TIGHT SQUEEZE 
			pehkui.setScale("pehkui:motion", 0.2)
			pehkui.setScale("pehkui:motion", 0.2)--YES WE HAVE TO RUN THIS TWICE TO SKIP THE TWEEN
		else --MEDIUM SQUEEZE 
			pehkui.setScale("pehkui:motion", 0.4)
			pehkui.setScale("pehkui:motion", 0.4)
		end
		--LIGHT SQUEEZES WON'T RUN THIS
	end
	
	--THANKS TO A PEHKUI BUG, WE CAN'T EVER LET MOTION BE 0 OR WE COULD TRIGGER THE THOUSAND FOOTSTEPS BUG
	pehkui.setScale("pehkui:motion", mySpeedMult * (((mm == 0) and 0.00) or mm))
	pehkui.setScale("pehkui:hitbox_width", myWidthMult)
	
	
	
	--WTF IS IT DOING TO OUR GRAVITY?? FIX THAT
	local speedlerp = (math.lerp(mySpeedMult, 1, 0.3))
	if player:getPose() == "SWIMMING" then --DON'T JUMP IF THERE'S NO ROOM
		myJumpMult = 0 
	else
		myJumpMult = (1/speedlerp)
	end
	pehkui.setScale("pehkui:jump_height", myJumpMult * jm)
	pehkui.setScale("pehkui:jump_height", myJumpMult * jm)
	pehkui.setScale("pehkui:step_height", 1/mySpeedMult)
	pehkui.setScale("pehkui:step_height", 1/mySpeedMult)
	pehkui.setScale("pehkui:falling", (squeezed and 0) or mySpeedMult * mm) --DON'T BREAK OUR ANKLES WHEN SQUEEZING PLEASE
	
	local updateGraphics = false
	if lastWeightStage ~= stage or lastSqueezed ~= squeezed then --THIS IS EXPENSIVE!!! ONLY UPDATE GRAPHICS IF THEY'VE CHANGED
		updateGraphics = true
	end
	
	lastWeightStage = stage
	lastSqueezed = squeezed
	lastJumpMod = jm
	lastMoveMod = mm
	lateUpdateFlag = false
	lastInWater = wet
	
	if updateGraphics then
		updateWeightGraphics(stage)
	end
end



function weightStage()
	-- if true then return 3 end--UNCOMMENT THIS TO FORCE SPECIFIC WEIGHT STAGES FOR TESTING
	
	-- BASED ON YOUR COMBINED FOOD + SATURATION VALUES (MAX 20 POINTS EACH FOR A COMBINED MAX OF 40)
	local foodPoints = player:getFood() + player:getSaturation()
	
	if complexFoodTracking then
		foodPoints = myFoodPoints
	end
	-- print(foodPoints) --UNCOMMENT THIS TO SEE YOUR CURRENT FOOD POINTS IN CHAT
	
	-- ((CONFIGURE)) -- CHOOSE THE FOOD POINT VALUES THAT TRIGGER EACH WEIGHT STAGE
	if foodPoints >= 50 then --(50 WOULD ONLY BE OBTAINABLE WITH MODS. IF YOU HAVE INFINITE EATING/SATURATION MODS YOU CAN MAKE THESE NUMBERS MUCH HIGHER)
		return 5
	elseif foodPoints >= 40 then
		return 4
	elseif foodPoints >= 32 then
		return 3
	elseif foodPoints >= 26 then
		return 2
	elseif foodPoints >= 20 then
		return 1
	else
		return 0
	end
end


--
--ABSORB THE BASE-GAME FOOTSTEP SOUNDS. NEEDED TO FIX THE THOUSAND FOOTSTEP BUG
--FRANKENSTEIN CREATION OF GREEN PIPLUP GUYS FOOTSTEP REPLACER SCRIPT MIXED WITH Tuulikki Unelma'S NEW VERSION 
function events.ON_PLAY_SOUND(id, pos, volume, pitch, loop, category, path)
    if not path then return end -- don't trigger if the sound was played by figura (prevent infinite loop)
	-- if lastSqueezed then return end
    if not player:isLoaded() then return end -- don't trigger if the player isn't loaded
    local nearest,uuid = math.huge,nil -- we will find the nearest player to the sound location
    for _, plr in pairs(world.getPlayers()) do
        local dist = (plr:getPos() - pos):length()
        if dist < nearest then nearest,uuid = dist,plr:getUUID() end
    end
    if player:getUUID() ~= uuid or nearest > 1.2 then return end -- don't trigger if the sound isn't near you

    ---------------------------------------------------------
    -- actual replacing starts here, feel free to edit below:
    -- if id:find(".step") then                                                  -- if sound id contains ".step"
        -- sounds:playSound("minecraft:entity.iron_golem.step", pos, volume, pitch) -- play a custom sound
        -- return true                                                           -- stop the actual step sound
    -- end
	
	--SPLICED WITH THE VERSION THAT STORES THE DATA FOR LATER
	local is_step = (id:find("step$") or id:find("soul_soil.place$") or id:find("_walk$") or id:find("_run$")) ~= nil
    local is_secondary_step = id:find("brush_through$") ~= nil

    if is_step then
        stored_step_sound = {id = id, pos = pos, volume = volume, pitch = pitch,}
    elseif is_secondary_step then
        stored_secondary_step_sound = {id = id, pos = pos, volume = volume, pitch = pitch,}
    end
    return is_step or is_secondary_step
	
end


function PlayFootstep()
	--CHEEKY PITCH MODIFIER FOR HEAVIER FOOTSTEPS
	local pitchmod = 1
	local volmod = 1
	
	-- ((CONFIGURE)) -- OPTIONAL, MODIFY YOUR FOOTSTEPS AT CERTAIN WEIGHTSTAGES. 
	if lastWeightStage >= 3 then
		pitchmod = 0.7
		volmod = 1.4
	elseif lastWeightStage >= 5 then
		pitchmod = 0.5
		volmod = 1.6
	end
	
	if stored_step_sound then
		sounds:playSound(
            stored_step_sound.id,
            stored_step_sound.pos,
            stored_step_sound.volume * volmod,
            stored_step_sound.pitch * pitchmod
        )
        if stored_secondary_step_sound then
            sounds:playSound(
                stored_secondary_step_sound.id,
                stored_secondary_step_sound.pos,
                stored_secondary_step_sound.volume * volmod,
                stored_secondary_step_sound.pitch * pitchmod
            )
            stored_secondary_step_sound = nil
        end
    end
end