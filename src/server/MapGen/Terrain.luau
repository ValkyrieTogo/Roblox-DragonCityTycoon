--!strict
-- Thin wrapper over Workspace.Terrain for the map generator. Terrain gives
-- smooth, naturally shaded ground with real materials (grass blades, glowing
-- cracked lava, rock, glacier ice), which parts cannot match. Voxels are 4
-- studs, so shapes are sized and placed on that grid where it matters.
-- Ground uses LeafyGrass, not Grass: with Terrain.Decoration on, Grass grows
-- tall blades that hide eggs and dummies, and scripts cannot shorten them.

local Workspace = game:GetService("Workspace")

local Terrain = {}

local terrain = Workspace.Terrain

function Terrain.Clear(center: Vector3, size: Vector3)
	terrain:FillBlock(CFrame.new(center), size, Enum.Material.Air)
end

-- An oriented box. `cframe` is its centre.
function Terrain.Block(cframe: CFrame, size: Vector3, material: Enum.Material)
	terrain:FillBlock(cframe, size, material)
end

function Terrain.Ball(center: Vector3, radius: number, material: Enum.Material)
	terrain:FillBall(center, radius, material)
end

-- A cylinder whose axis is the cframe's Y axis.
function Terrain.Cylinder(cframe: CFrame, height: number, radius: number, material: Enum.Material)
	terrain:FillCylinder(cframe, height, radius, material)
end

-- A cylinder standing upright, centred at `position`.
function Terrain.Column(position: Vector3, height: number, radius: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(position), height, radius, material)
end

-- An irregular boulder: one main ball with a few smaller ones pushed into it.
function Terrain.Boulder(center: Vector3, size: number, material: Enum.Material, rng: Random)
	terrain:FillBall(center, size / 2, material)
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.5), rng:NextNumber(-1, 1)) * size * 0.3
		terrain:FillBall(center + offset, size * rng:NextNumber(0.25, 0.4), material)
	end
end

return Terrain
