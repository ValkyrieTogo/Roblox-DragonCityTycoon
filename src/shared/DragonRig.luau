--!strict
-- Bone names of the Meshy dragon in Shared/Assets/Dragon.rbxm, used by the
-- costume (mouth) and the client animator (wings, legs, tail, neck). Meshy
-- numbers bones automatically, so if the model is re-imported with a new
-- rig, update this file from the new bone tree. Positions below are in the
-- model's own units (it is 1.7 tall before the costume scales it).

local DragonRig = {}

-- The model's height in its own units, for converting offsets to studs.
DragonRig.ModelHeight = 1.7

-- Last bone of the head chain, at the top of the skull. The mouth is a child
-- bone placed MouthOffset from it: down to the jaw, forward to the snout.
DragonRig.MouthBone = "Bone_039"
DragonRig.MouthOffset = Vector3.new(0, -0.24, -0.3)

DragonRig.Hips = "Bone_001"
DragonRig.Neck = "Bone_043"
DragonRig.Head = "Bone_040"

-- Shoulder to tip, one chain per wing.
DragonRig.Wings = {
	{ "Bone_047", "Bone_046", "Bone_045", "Bone_044" },
	{ "Bone_051", "Bone_050", "Bone_049", "Bone_048" },
} :: { { string } }

-- Upper and lower bone of each leg.
DragonRig.FrontLegs = {
	{ "Bone_032", "Bone_031" },
	{ "Bone_038", "Bone_037" },
} :: { { string } }
DragonRig.BackLegs = {
	{ "Bone_011", "Bone_010" },
	{ "Bone_017", "Bone_016" },
} :: { { string } }

-- Base to tip.
DragonRig.Tail = {
	"Bone_026",
	"Bone_025",
	"Bone_024",
	"Bone_023",
	"Bone_022",
	"Bone_021",
	"Bone_020",
	"Bone_019",
	"Bone_018",
} :: { string }

return DragonRig
