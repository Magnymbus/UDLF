function init()
	local found = FindShapes("Latch", true) --Only used to get IDs. Indexes are discarded when transferred to Latches.
	latches = {}
	for _,ID in pairs(found) do
		latches[ID] = 0
	end
	AppendLatchData()
end



function AppendLatchData() --Just an initialization step to put everything together.
	for ID, _ in pairs(latches) do
		local lType = GetTagValue(ID, "Latch")
		local oFile = "blank"
		local cFile = "blank"
		if HasTag(ID, "LatchOpenSound") and GetTagValue(ID, "LatchOpenSound") ~= '' then
			oFile = GetTagValue(ID, "LatchOpenSound")
		elseif lType == "Vehicle" then
			oFile = "caropen.ogg"
		elseif lType == "Structure" then
			oFile = "clickdown.ogg"
		end
		if HasTag(ID, "LatchCloseSound") and GetTagValue(ID, "LatchCloseSound") ~= '' then
			cFile = GetTagValue(ID, "LatchCloseSound")
		elseif lType == "Vehicle" then
			cFile = "carclose.ogg"
		elseif lType == "Structure" then
			cFile = "clickup.ogg"
		end
		local oID = LoadSound(oFile)
		local cID = LoadSound(cFile)
		latches[ID] = {
			["Type"] = lType, 
			["CurrentState"] = "Open",
			["OpenPath"] = oFile, 
			["ClosePath"] = cFile, 
			["Open"] = oID, 
			["Close"] = cID }
	end
	CheckLatchDataSanity()
end



function CheckLatchDataSanity()
	for ID,_ in pairs(latches) do
		if latches[ID]["Type"] == nil then DebugPrint("latch type is nil in shape: " .. ID .. " (Check fallback)") end
		if latches[ID]["ClosePath"] == "blank" then DebugPrint("Latch close sound is blank in shape: " .. ID .. " (Check fallback)") end
		if latches[ID]["OpenPath"] == "blank" then DebugPrint("Latch open sound is blank in shape: " .. ID .. " (Check fallback)") end
		if latches[ID]["CurrentState"] ~= "Open" and latches[ID]["CurrentState"] ~= "Close" then DebugPrint("Latch state is invalid in shape: " .. ID) end
	end
end



function tick(dt)
	local grabbing = GetPlayerGrabShape()
	for shape,_ in pairs(latches) do
		local joints = GetShapeJoints(shape)
		local joint = joints[1]
		if IsJointBroken(joint) == false then
			if shape == grabbing and latches[shape]["CurrentState"] == "Close" then						--Unlatch it if it's grabbed
				SetJointMotor(joint, 0, 0)
				PlayIndexedSound(shape, "Open")
				latches[shape]["CurrentState"] = "Open"
			elseif GetJointMovement(joint) < 0.01 and latches[shape]["CurrentState"] == "Open" and shape ~= grabbing then		--Latch if closed and not grabbed
				SetJointMotorTarget(joint, 0)
				PlayIndexedSound(shape, "Close")
				latches[shape]["CurrentState"] = "Close"
			end
		end
	end
end



---@param shape number Shape ID to play at.
---@param stateToQuery string Sound variant to play.
function PlayIndexedSound(shape, stateToQuery)
	local previousState = latches[shape]["CurrentState"]
	if stateToQuery ~= previousState then														--Make sure not to play the sound if it was just played
		local sound = latches[shape][stateToQuery]
		local transform = GetShapeWorldTransform(shape)
		if stateToQuery == "Close" then															--play at a volume related to closing speed
			local parentShape = GetJointOtherShape(GetShapeJoints(shape)[1], shape)
			local bodyVelocityMagnitude = VecLength(GetBodyVelocity(GetShapeBody(shape)))
			local parentVelocityMagnitude = VecLength(GetBodyVelocity(GetShapeBody(parentShape)))
			local relativeVelocity = (bodyVelocityMagnitude - parentVelocityMagnitude)
			local volume = math.abs(math.tanh(relativeVelocity / 5) * 0.875) + 0.125
			PlaySound(sound, transform["pos"], volume)
		else																					--default to max volume if not closing
			PlaySound(sound, transform["pos"], 1)
		end
	end
end


---@param arg1 string Debug type
---@param arg2 string ID (If applicable)
function DoDebug(arg1, arg2)
	if arg1 == "fallback" then
		DebugPrint("Invalid Latch fallback type: " .. arg2 .. ". Check spelling and case.")
	elseif arg1 == "LatchData" then
		if arg2 == nil then
			DebugPrint("Latch Data:")
			for ID,_ in pairs(latches) do
				DoDebug("LatchData", ID)
			end
		end
		DebugPrint(arg2 .. "(" .. latches[arg2]["Type"] .. "): " .. latches[arg2]["CurrentState"])
		DebugPrint(latches[arg2]["OpenPath"] .. "(" .. latches[arg2]["Open"] .. ")")
		DebugPrint(latches[arg2]["ClosePath"] .. "(" .. latches[arg2]["Close"] .. ")")
	else
		DebugPrint("Bad debug type: " .. arg1)
	end
end