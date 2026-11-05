--!strict
-- Finds where a character's fire comes from. The costume records it in an
-- ObjectValue named "Mouth" on the character (a Bone on the mesh dragon, an
-- Attachment on the blocky one); older characters have Head.Mouth. Under the
-- mouth live a "Flame" ParticleEmitter and a "Glow" PointLight.

local Mouth = {}

function Mouth.Find(character: Model): Attachment?
	local ref = character:FindFirstChild("Mouth")
	if ref and ref:IsA("ObjectValue") then
		local value = ref.Value
		if value and value:IsA("Attachment") then
			return value
		end
	end
	local head = character:FindFirstChild("Head")
	local mouth = if head then head:FindFirstChild("Mouth") else nil
	return if mouth and mouth:IsA("Attachment") then mouth else nil
end

function Mouth.Flame(character: Model): ParticleEmitter?
	local mouth = Mouth.Find(character)
	local flame = if mouth then mouth:FindFirstChild("Flame") else nil
	return if flame and flame:IsA("ParticleEmitter") then flame else nil
end

return Mouth
