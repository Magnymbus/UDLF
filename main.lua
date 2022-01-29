--global variables
--bool debug
--bool verbose
--tabl latches[]


function init()
	debug = GetBool('savegame.mod.debug')
	verbose = GetBool('savegame.mod.verbose')
	local foundLatches = FindShapes("Latch", true) --Only used to get IDs. Indexes are discarded when transferred to Latches.
	latches = {}
	for _,ID in pairs(foundLatches) do
		latches[ID] = 0
	end
	AppendLatchData()
end



function AppendLatchData() --Just an initialization step to put everything together.
	for ID, _ in pairs(latches) do
		local latchType = GetTagValue(ID, "Latch")
		local openPath = "blank"
		local closePath = "blank"
		if HasTag(ID, "LatchOpenSound") and GetTagValue(ID, "LatchOpenSound") ~= '' then
			openPath = GetTagValue(ID, "LatchOpenSound")
		elseif latchType == "Vehicle" then
			openPath = "caropen.ogg"
		elseif latchType == "Structure" then
			openPath = "clickdown.ogg"
		end
		if HasTag(ID, "LatchCloseSound") and GetTagValue(ID, "LatchCloseSound") ~= '' then
			closePath = GetTagValue(ID, "LatchCloseSound")
		elseif latchType == "Vehicle" then
			closePath = "carclose.ogg"
		elseif latchType == "Structure" then
			closePath = "clickup.ogg"
		end
		local openID = LoadSound(openPath)
		local closeID = LoadSound(closePath)
		latches[ID] = {
			["Type"] = latchType,
			["isOpen"] = true,
			["OpenPath"] = openPath,
			["ClosePath"] = closePath,
			["OpenID"] = openID,
			["CloseID"] = closeID }
	end
	if debug then CheckLatchDataSanity() end
end



function CheckLatchDataSanity()
	for ID,_ in pairs(latches) do
		if latches[ID]["Type"] == nil then DebugPrint("Latch type is nil in shape: " .. ID .. " (No latch type was set. Check your tags: Latch=[Type])") end
		if latches[ID]["ClosePath"] == "blank" then DebugPrint("Latch close sound is blank in shape: " .. ID .. " (Path is blank or no latch type was set)") end
		if latches[ID]["OpenPath"] == "blank" then DebugPrint("Latch open sound is blank in shape: " .. ID .. " (Path is blank or no latch type was set)") end
		if verbose then
			DebugPrint("Latch Data:")
			DebugPrint(ID .. "(" .. latches[ID]["Type"] .. "): isOpen = " .. tostring(latches[ID]["isOpen"]) )
			DebugPrint(latches[ID]["OpenPath"] .. "(" .. latches[ID]["OpenID"] .. ")")
			DebugPrint(latches[ID]["ClosePath"] .. "(" .. latches[ID]["CloseID"] .. ")")
		end
	end
end



function tick(dt)
	local grabShape = GetPlayerGrabShape()
	for latchShape,_ in pairs(latches) do
		local shapeJoints = GetShapeJoints(latchShape)
		local latchJoint = shapeJoints[1]
		if IsJointBroken(latchJoint) == false then
			if latchShape == grabShape and latches[latchShape]["isOpen"] == false then	--Unlatch if grabbed
				SetJointMotor(latchJoint, 0, 0)
				PlayIndexedSound(latchShape, true)
				latches[latchShape]["isOpen"] = true
			elseif GetJointMovement(latchJoint) < 0.01 and latches[latchShape]["isOpen"] == true and latchShape ~= grabShape then		--Latch if closed and not grabbed
				SetJointMotorTarget(latchJoint, 0)
				PlayIndexedSound(latchShape, false)
				latches[latchShape]["isOpen"] = false
			end
		end
	end
end



---@param shape number Shape ID to play at.
---@param openQuery string Sound variant to play.
function PlayIndexedSound(shape, openQuery)
	local previousState = latches[shape]["isOpen"]
	if openQuery ~= previousState then																													--Make sure not to play the sound if it was just played
		local soundShape = latches[shape]
		local sound = openQuery and soundShape["OpenID"] or soundShape["CloseID"] 								--ternary: if isOpen then Open else Close. I hate lua ternaries
		local transform = GetShapeWorldTransform(shape)
		if openQuery == false then																																--play at a volume related to closing speed
			local parentShape = GetJointOtherShape(GetShapeJoints(shape)[1], shape)
			local bodyVelocityMagnitude = VecLength(GetBodyVelocity(GetShapeBody(shape)))
			local parentVelocityMagnitude = VecLength(GetBodyVelocity(GetShapeBody(parentShape)))
			local relativeVelocity = (bodyVelocityMagnitude - parentVelocityMagnitude)
			local volume = math.abs(math.tanh(relativeVelocity / 5) * 0.875) + 0.125
			PlaySound(sound, transform["pos"], volume)
		else																																											--default to max volume if not closing
			PlaySound(sound, transform["pos"], 1)
		end
	end
end


