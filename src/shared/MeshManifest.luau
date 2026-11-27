--!strict
-- WRITTEN BY blender/build_all.py from the Blender exports: don't edit by hand.
-- Every SHIFT model: its size and origin (studs) and, for each MeshPart,
-- its size, centre (relative to the model's bottom-centre origin) and look.
-- Meshes.luau uses this to place uploaded meshes exactly where the
-- primitive parts they replace stand.
return {
	archive_box = {
		tris = 188,
		size = Vector3.new(1.3526, 1.0635, 1.9),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Box", size = Vector3.new(1.31, 0.93, 1.86), centre = Vector3.new(0, 0.465, 0), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(168, 130, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "Lid", size = Vector3.new(1.3526, 0.227, 1.9), centre = Vector3.new(0, 0.95, 0), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(156, 120, 76), transparency = 0, shadow = true, attach = "" },
			{ name = "Holes", size = Vector3.new(0.42, 0.13, 1.9), centre = Vector3.new(0, 0.63, 0), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(40, 30, 22), transparency = 0, shadow = true, attach = "" },
			{ name = "Label", size = Vector3.new(0.8107, 0.3477, 0.01), centre = Vector3.new(0, 0.36, -0.938), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(222, 214, 190), transparency = 0, shadow = true, attach = "" },
		},
	},
	binders = {
		tris = 1080,
		size = Vector3.new(2.0789, 1.3547, 1.035),
		origin = Vector3.new(0.6555, -0.0547, -0.0175), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "BinderRed", size = Vector3.new(0.7633, 1.331, 1.025), centre = Vector3.new(-0.6578, 0.6655, 0.005), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(120, 40, 36), transparency = 0, shadow = true, attach = "" },
			{ name = "BinderBlue", size = Vector3.new(1.49, 1.3, 1.025), centre = Vector3.new(0.2945, 0.7047, 0.005), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 60, 100), transparency = 0, shadow = true, attach = "" },
			{ name = "BinderGreen", size = Vector3.new(0.35, 1.3, 1.025), centre = Vector3.new(0.1045, 0.7047, 0.005), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(60, 80, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "BinderGrey", size = Vector3.new(0.35, 1.3, 1.025), centre = Vector3.new(0.4845, 0.7047, 0.005), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(60, 58, 54), transparency = 0, shadow = true, attach = "" },
			{ name = "Pages", size = Vector3.new(1.9694, 1.2241, 0.9), centre = Vector3.new(0.0098, 0.6727, 0.0575), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(220, 214, 192), transparency = 0, shadow = true, attach = "" },
			{ name = "Labels", size = Vector3.new(1.8565, 0.8439, 0.01), centre = Vector3.new(0.0362, 0.6928, -0.5125), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(232, 226, 206), transparency = 0, shadow = true, attach = "" },
		},
	},
	boiler = {
		tris = 2176,
		size = Vector3.new(6.4, 11.1, 6.005),
		origin = Vector3.new(0.4, 0, -0.2025), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Plinth", size = Vector3.new(5.6, 0.5, 5.6), centre = Vector3.new(-0.4, 0.25, 0.2025), look = "concrete", material = "Concrete", surface = "SHIFT_Concrete", colour = Color3.fromRGB(120, 116, 108), transparency = 0, shadow = true, attach = "" },
			{ name = "Tank", size = Vector3.new(5.14, 8.635, 5.27), centre = Vector3.new(-0.4, 4.7675, 0.1375), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(104, 100, 90), transparency = 0, shadow = true, attach = "" },
			{ name = "Pipes", size = Vector3.new(4.08, 10.25, 3.53), centre = Vector3.new(1.16, 5.975, -1.0825), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(96, 92, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "Wheel", size = Vector3.new(0.0951, 0.86, 0.8384), centre = Vector3.new(2.85, 5.2, 0.2025), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(128, 44, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Gauge", size = Vector3.new(0.9359, 0.96, 0.14), centre = Vector3.new(-0.4, 4, -2.8975), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 146, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "GaugeFace", size = Vector3.new(0.7799, 0.8, 0.02), centre = Vector3.new(-0.4, 4, -2.9775), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(220, 214, 196), transparency = 0, shadow = true, attach = "" },
			{ name = "Needle", size = Vector3.new(0.2793, 0.2081, 0.01), centre = Vector3.new(-0.34, 4.08, -2.9975), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(150, 30, 24), transparency = 0, shadow = true, attach = "" },
		},
	},
	cable_tray = {
		tris = 1224,
		size = Vector3.new(20, 1.2919, 1.95),
		origin = Vector3.new(0, -0.9119, -0.975), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Tray", size = Vector3.new(20, 0.3, 1.56), centre = Vector3.new(0, 1.0619, -0.025), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(130, 130, 124), transparency = 0, shadow = true, attach = "" },
			{ name = "Brackets", size = Vector3.new(15.2, 1.0119, 1.95), centre = Vector3.new(0, 0.5059, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 58, 54), transparency = 0, shadow = true, attach = "" },
			{ name = "Cables", size = Vector3.new(20, 0.32, 0.94), centre = Vector3.new(0, 1.1319, 0.015), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(44, 44, 42), transparency = 0, shadow = true, attach = "" },
		},
	},
	carton = {
		tris = 192,
		size = Vector3.new(2.2, 1.5338, 1.924),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Box", size = Vector3.new(2.2, 1.5338, 1.9), centre = Vector3.new(0, 0.7669, 0), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(168, 130, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "Tape", size = Vector3.new(0.36, 0.508, 1.924), centre = Vector3.new(0, 1.264, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(190, 170, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Marks", size = Vector3.new(1.65, 0.46, 0.01), centre = Vector3.new(0.025, 0.63, -0.956), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(60, 52, 44), transparency = 0, shadow = true, attach = "" },
		},
	},
	ceiling_tile = {
		tris = 336,
		size = Vector3.new(20.13, 0.2, 20.13),
		origin = Vector3.new(-0.065, 0, -0.065), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Tiles", size = Vector3.new(19.86, 0.16, 19.86), centre = Vector3.new(0.065, 0.12, 0.065), look = "ceiling", material = "Plaster", surface = "SHIFT_CeilingTile", colour = Color3.fromRGB(206, 201, 178), transparency = 0, shadow = true, attach = "" },
			{ name = "Grid", size = Vector3.new(20.13, 0.084, 20.13), centre = Vector3.new(0, 0.042, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 146, 128), transparency = 0, shadow = true, attach = "" },
		},
	},
	ceiling_tile_gap = {
		tris = 1068,
		size = Vector3.new(20.13, 5.4156, 20.13),
		origin = Vector3.new(-0.065, -4.0156, -0.065), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Tiles", size = Vector3.new(20.0159, 4.2156, 19.86), centre = Vector3.new(-0.013, 2.1078, 0.065), look = "ceiling", material = "Plaster", surface = "SHIFT_CeilingTile", colour = Color3.fromRGB(206, 201, 178), transparency = 0, shadow = true, attach = "" },
			{ name = "Grid", size = Vector3.new(20.13, 0.084, 20.13), centre = Vector3.new(0, 4.0576, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 146, 128), transparency = 0, shadow = true, attach = "" },
			{ name = "Void", size = Vector3.new(4.9, 1.2, 4.9), centre = Vector3.new(-7.435, 4.8156, -7.435), look = "plaster", material = "Plaster", surface = "", colour = Color3.fromRGB(10, 10, 9), transparency = 0, shadow = false, attach = "" },
			{ name = "Cable", size = Vector3.new(3.4007, 2.2949, 2.7002), centre = Vector3.new(-7.5859, 3.7917, -7.3336), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(40, 38, 36), transparency = 0, shadow = true, attach = "" },
			{ name = "Insulation", size = Vector3.new(1.54, 0.55, 1.1), centre = Vector3.new(-6.535, 4.3656, -8.835), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(176, 150, 96), transparency = 0, shadow = true, attach = "" },
		},
	},
	chair = {
		tris = 952,
		size = Vector3.new(1.7, 3.6442, 1.9505),
		origin = Vector3.new(0, 0, 0.1252), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Upholstery", size = Vector3.new(1.7, 2.1942, 1.8921), centre = Vector3.new(0, 2.5471, -0.0292), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(70, 82, 96), transparency = 0, shadow = true, attach = "" },
			{ name = "Base", size = Vector3.new(1.6289, 2.396, 1.8047), centre = Vector3.new(0, 1.298, 0.0729), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(52, 52, 54), transparency = 0, shadow = true, attach = "" },
			{ name = "Casters", size = Vector3.new(1.6954, 0.18, 1.6124), centre = Vector3.new(0, 0.09, -0.0614), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(34, 34, 36), transparency = 0, shadow = true, attach = "" },
		},
	},
	clipboard = {
		tris = 396,
		size = Vector3.new(1.3, 0.19, 1.8),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Board", size = Vector3.new(1.3, 0.06, 1.8), centre = Vector3.new(0, 0.03, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(120, 90, 56), transparency = 0, shadow = true, attach = "" },
			{ name = "Clip", size = Vector3.new(0.7, 0.125, 0.3), centre = Vector3.new(0, 0.1275, -0.72), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 168, 160), transparency = 0, shadow = true, attach = "" },
			{ name = "Sheet", size = Vector3.new(1.1, 0.077, 1.45), centre = Vector3.new(0, 0.0385, 0.08), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(226, 222, 206), transparency = 0, shadow = true, attach = "" },
		},
	},
	crate_large = {
		tris = 796,
		size = Vector3.new(3, 2.6, 3.06),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Boards", size = Vector3.new(2.84, 2.575, 2.84), centre = Vector3.new(0, 1.3125, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(120, 100, 64), transparency = 0, shadow = true, attach = "" },
			{ name = "Frame", size = Vector3.new(3, 2.6, 3.06), centre = Vector3.new(0, 1.3, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(96, 78, 50), transparency = 0, shadow = true, attach = "" },
		},
	},
	crate_small = {
		tris = 796,
		size = Vector3.new(2.2, 1.9, 2.26),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Boards", size = Vector3.new(2.04, 1.875, 2.04), centre = Vector3.new(0, 0.9625, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(120, 100, 64), transparency = 0, shadow = true, attach = "" },
			{ name = "Frame", size = Vector3.new(2.2, 1.9, 2.26), centre = Vector3.new(0, 0.95, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(96, 78, 50), transparency = 0, shadow = true, attach = "" },
		},
	},
	crt_monitor = {
		tris = 376,
		size = Vector3.new(1.7, 1.285, 1.11),
		origin = Vector3.new(0, -0.66, 0.015), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Casing", size = Vector3.new(1.7, 1.285, 1.09), centre = Vector3.new(0, 0.6425, -0.01), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(196, 190, 172), transparency = 0, shadow = true, attach = "" },
			{ name = "Vents", size = Vector3.new(0.64, 0.02, 0.36), centre = Vector3.new(0, 1.105, -0.375), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(60, 58, 52), transparency = 0, shadow = true, attach = "" },
			{ name = "Screen", size = Vector3.new(1.34, 0.96, 0.1), centre = Vector3.new(0, 0.66, 0.485), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(24, 28, 26), transparency = 0, shadow = true, attach = "" },
			{ name = "Led", size = Vector3.new(0.05, 0.05, 0.02), centre = Vector3.new(0.68, 0.16, 0.545), look = "neon", material = "Neon", surface = "", colour = Color3.fromRGB(90, 200, 90), transparency = 0, shadow = false, attach = "" },
		},
	},
	curtain_rail = {
		tris = 720,
		size = Vector3.new(8.14, 10.08, 0.546),
		origin = Vector3.new(0, 0.95, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Track", size = Vector3.new(8.14, 0.74, 0.32), centre = Vector3.new(0, 9.71, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 172, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "Curtain", size = Vector3.new(7.7, 9.33, 0.546), centre = Vector3.new(0, 4.665, 0), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(150, 176, 168), transparency = 0, shadow = true, attach = "" },
			{ name = "Gliders", size = Vector3.new(7.53, 0.16, 0.08), centre = Vector3.new(-0.075, 9.33, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(210, 210, 204), transparency = 0, shadow = true, attach = "" },
		},
	},
	descent_lift = {
		tris = 1928,
		size = Vector3.new(11.8, 12, 11.8),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Deck", size = Vector3.new(10, 0.2, 10), centre = Vector3.new(0, 0.1, 0), look = "steel_plate", material = "DiamondPlate", surface = "SHIFT_SteelPlate", colour = Color3.fromRGB(70, 70, 74), transparency = 0, shadow = true, attach = "" },
			{ name = "Trim", size = Vector3.new(10.2, 0.22, 10.2), centre = Vector3.new(0, 0.11, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(56, 56, 58), transparency = 0, shadow = true, attach = "" },
			{ name = "Posts", size = Vector3.new(10.8, 12, 10.8), centre = Vector3.new(0, 6, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(128, 116, 74), transparency = 0, shadow = true, attach = "" },
			{ name = "Bolts", size = Vector3.new(10.624, 0.08, 10.6079), centre = Vector3.new(0, 0.3, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(130, 128, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Ropes", size = Vector3.new(2.8, 0.82, 0.5), centre = Vector3.new(0, 11.59, 0), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(40, 40, 38), transparency = 0, shadow = true, attach = "" },
			{ name = "Footings", size = Vector3.new(11.4, 1.1, 11.4), centre = Vector3.new(0, 0.55, 0), look = "concrete", material = "Concrete", surface = "SHIFT_Concrete", colour = Color3.fromRGB(150, 146, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "Kerb", size = Vector3.new(11.8, 0.18, 11.8), centre = Vector3.new(0, 0.09, 0), look = "concrete", material = "Concrete", surface = "SHIFT_Concrete", colour = Color3.fromRGB(140, 136, 126), transparency = 0, shadow = true, attach = "" },
		},
	},
	desk = {
		tris = 328,
		size = Vector3.new(5.2, 2.7, 2.6),
		origin = Vector3.new(0, 0.025, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "DeskTop", size = Vector3.new(5.2, 0.25, 2.6), centre = Vector3.new(0, 2.575, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(150, 120, 82), transparency = 0, shadow = true, attach = "" },
			{ name = "DeskFrame", size = Vector3.new(5.1, 2.45, 2.5), centre = Vector3.new(0, 1.225, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(120, 122, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "DeskHandles", size = Vector3.new(0.6, 0.08, 0.08), centre = Vector3.new(1.55, 2.145, 1.2), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(176, 174, 166), transparency = 0, shadow = true, attach = "" },
		},
	},
	door = {
		tris = 1220,
		size = Vector3.new(10.05, 8.95, 1.46),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Door_Frame", size = Vector3.new(10.05, 8.95, 1.46), centre = Vector3.new(0, 4.475, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
			{ name = "Door_LeafL", size = Vector3.new(4.47, 8.46, 0.18), centre = Vector3.new(-2.25, 4.25, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(88, 98, 90), transparency = 0, shadow = true, attach = "" },
			{ name = "Door_LeafR", size = Vector3.new(4.47, 8.46, 0.18), centre = Vector3.new(2.25, 4.25, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(88, 98, 90), transparency = 0, shadow = true, attach = "" },
			{ name = "Door_Hardware", size = Vector3.new(8.57, 3.6, 0.47), centre = Vector3.new(0, 1.9, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 150, 146), transparency = 0, shadow = true, attach = "" },
		},
	},
	duty_roster = {
		tris = 552,
		size = Vector3.new(2.3, 3, 0.2218),
		origin = Vector3.new(0, 0, -0.0909), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Sheet", size = Vector3.new(2.3, 3, 0.2068), centre = Vector3.new(0, 1.5, -0.0075), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(226, 222, 206), transparency = 0, shadow = true, attach = "" },
			{ name = "Pins", size = Vector3.new(2.04, 0.14, 0.14), centre = Vector3.new(0, 2.85, 0.0409), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 90, 160), transparency = 0, shadow = true, attach = "" },
		},
	},
	exit_lift = {
		tris = 1948,
		size = Vector3.new(10.8, 11, 10.8),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Deck", size = Vector3.new(10, 0.2, 10), centre = Vector3.new(0, 0.1, 0), look = "steel_plate", material = "DiamondPlate", surface = "SHIFT_SteelPlate", colour = Color3.fromRGB(70, 70, 74), transparency = 0, shadow = true, attach = "" },
			{ name = "Trim", size = Vector3.new(10.2, 0.22, 10.2), centre = Vector3.new(0, 0.11, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(56, 56, 58), transparency = 0, shadow = true, attach = "" },
			{ name = "Posts", size = Vector3.new(10.8, 11, 10.8), centre = Vector3.new(0, 5.5, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(90, 88, 80), transparency = 0, shadow = true, attach = "" },
			{ name = "Bolts", size = Vector3.new(10.624, 0.08, 10.6079), centre = Vector3.new(0, 0.3, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(130, 128, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Ropes", size = Vector3.new(2.8, 0.82, 0.5), centre = Vector3.new(0, 10.59, 0), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(40, 40, 38), transparency = 0, shadow = true, attach = "" },
			{ name = "ControlBox", size = Vector3.new(1.0465, 2.9, 1.0465), centre = Vector3.new(4.6, 3.05, 4.6), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(46, 44, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "Buttons", size = Vector3.new(0.3677, 1.02, 0.3677), centre = Vector3.new(4.4515, 3.9, 4.4515), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(190, 170, 60), transparency = 0, shadow = true, attach = "" },
			{ name = "LampGuard", size = Vector3.new(2.5, 0.545, 2.5), centre = Vector3.new(0, 10.3275, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 58, 54), transparency = 0, shadow = true, attach = "" },
		},
	},
	exit_sign = {
		tris = 420,
		size = Vector3.new(3.4, 1.625, 0.4),
		origin = Vector3.new(0, -0.5, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Housing", size = Vector3.new(3.4, 1, 0.4), centre = Vector3.new(0, 0.5, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 42, 38), transparency = 0, shadow = true, attach = "" },
			{ name = "Face", size = Vector3.new(3.15, 0.75, 0.34), centre = Vector3.new(0, 0.5, 0), look = "neon", material = "Neon", surface = "", colour = Color3.fromRGB(70, 120, 80), transparency = 0, shadow = false, attach = "" },
			{ name = "Mount", size = Vector3.new(2.68, 0.625, 0.2663), centre = Vector3.new(0, 1.3125, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(140, 138, 130), transparency = 0, shadow = true, attach = "" },
		},
	},
	fallen_tile = {
		tris = 352,
		size = Vector3.new(5.8838, 0.7813, 5.8988),
		origin = Vector3.new(0.0747, -0.0306, 0.0777), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Tile", size = Vector3.new(5.8838, 0.7813, 5.8988), centre = Vector3.new(0, 0.3906, 0), look = "ceiling", material = "Plaster", surface = "SHIFT_CeilingTile", colour = Color3.fromRGB(198, 190, 166), transparency = 0, shadow = true, attach = "" },
		},
	},
	filing_cabinet = {
		tris = 1136,
		size = Vector3.new(1.8, 4.4, 2.82),
		origin = Vector3.new(0, 0, -0.31), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(1.8, 4.4, 2.14), centre = Vector3.new(0, 2.2, 0.34), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(140, 138, 126), transparency = 0, shadow = true, attach = "" },
			{ name = "Drawers", size = Vector3.new(1.7, 4.06, 0.55), centre = Vector3.new(0, 2.345, -1.035), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 148, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "Handles", size = Vector3.new(0.62, 3.445, 0.6), centre = Vector3.new(0, 2.5975, -1.11), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(180, 178, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "Labels", size = Vector3.new(0.4, 3.25, 0.46), centre = Vector3.new(0, 2.665, -1.107), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(214, 206, 180), transparency = 0, shadow = true, attach = "" },
		},
	},
	fixture = {
		tris = 1008,
		size = Vector3.new(8, 0.65, 2.4931),
		origin = Vector3.new(0, -0.65, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Housing", size = Vector3.new(8, 0.4111, 2.4931), centre = Vector3.new(0, 0.4444, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(176, 172, 160), transparency = 0, shadow = true, attach = "" },
			{ name = "Caps", size = Vector3.new(8, 0.42, 2), centre = Vector3.new(0, 0.21, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(150, 146, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "Tubes", size = Vector3.new(7.4, 0.26, 1.36), centre = Vector3.new(0, 0.17, 0), look = "neon", material = "Neon", surface = "", colour = Color3.fromRGB(252, 236, 186), transparency = 0, shadow = false, attach = "" },
		},
	},
	floor_panel = {
		tris = 160,
		size = Vector3.new(20, 0.054, 20),
		origin = Vector3.new(0, 0.066, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Carpet", size = Vector3.new(20, 0.054, 20), centre = Vector3.new(0, 0.027, 0), look = "carpet", material = "Carpet", surface = "SHIFT_Carpet", colour = Color3.fromRGB(128, 110, 62), transparency = 0, shadow = true, attach = "" },
		},
	},
	floor_panel_damaged = {
		tris = 708,
		size = Vector3.new(20, 0.8132, 20),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Carpet", size = Vector3.new(20, 0.8132, 20), centre = Vector3.new(0, 0.4066, 0), look = "carpet", material = "Carpet", surface = "SHIFT_Carpet", colour = Color3.fromRGB(128, 110, 62), transparency = 0, shadow = true, attach = "" },
			{ name = "Screed", size = Vector3.new(15, 0.04, 15), centre = Vector3.new(-2.5, 0.02, 2.5), look = "concrete", material = "Concrete", surface = "SHIFT_Concrete", colour = Color3.fromRGB(118, 114, 106), transparency = 0, shadow = true, attach = "" },
			{ name = "Adhesive", size = Vector3.new(3.9785, 0.02, 4.277), centre = Vector3.new(2.4893, 0.05, -2.54), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(92, 80, 52), transparency = 0, shadow = true, attach = "" },
		},
	},
	foreman = {
		tris = 7968,
		size = Vector3.new(5.0586, 8.7128, 2.0879),
		origin = Vector3.new(0, -0.019, -0.1614), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "LowerTorso", size = Vector3.new(2.1952, 1.44, 1.2152), centre = Vector3.new(0, 4.119, 0.1614), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(44, 42, 39), transparency = 0, shadow = true, attach = "" },
			{ name = "Belt", size = Vector3.new(2.352, 0.3, 1.464), centre = Vector3.new(0, 4.439, 0.1434), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(36, 31, 27), transparency = 0, shadow = true, attach = "LowerTorso" },
			{ name = "Keys", size = Vector3.new(0.105, 1.4598, 0.576), centre = Vector3.new(1.1825, 3.7191, 0.0414), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 140, 112), transparency = 0, shadow = true, attach = "LowerTorso" },
			{ name = "UpperTorso", size = Vector3.new(4.6269, 3.5598, 1.7158), centre = Vector3.new(0, 6.0619, 0.1262), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(56, 51, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "ChestBand", size = Vector3.new(3.052, 0.336, 1.4388), centre = Vector3.new(0, 5.779, 0.1614), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(176, 176, 166), transparency = 0, shadow = true, attach = "UpperTorso" },
			{ name = "Head", size = Vector3.new(1.656, 0.99, 2.0879), centre = Vector3.new(0, 8.2178, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(178, 162, 112), transparency = 0, shadow = true, attach = "" },
			{ name = "FaceVoid", size = Vector3.new(0.988, 0.9568, 1.04), centre = Vector3.new(0, 7.819, 0.1214), look = "neon", material = "Neon", surface = "", colour = Color3.fromRGB(0, 0, 0), transparency = 0, shadow = true, attach = "Head" },
			{ name = "LeftUpperArm", size = Vector3.new(1.1756, 2.7292, 1.0852), centre = Vector3.new(-1.9102, 5.7144, 0.1044), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(56, 51, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftLowerArm", size = Vector3.new(0.8858, 2.28, 0.9563), centre = Vector3.new(-2.073, 3.819, 0.1324), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(56, 51, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftCuffBand", size = Vector3.new(0.8738, 0.2478, 0.8803), centre = Vector3.new(-2.0924, 3.23, 0.0842), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(176, 176, 166), transparency = 0, shadow = true, attach = "LeftLowerArm" },
			{ name = "LeftHand", size = Vector3.new(0.587, 1.5908, 0.8981), centre = Vector3.new(-2.0564, 2.2976, 0.0332), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(82, 70, 52), transparency = 0, shadow = true, attach = "" },
			{ name = "RightUpperArm", size = Vector3.new(1.1756, 2.7292, 1.0852), centre = Vector3.new(1.9102, 5.7144, 0.1044), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(56, 51, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "RightLowerArm", size = Vector3.new(0.8858, 2.28, 0.9563), centre = Vector3.new(2.073, 3.819, 0.1324), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(56, 51, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "RightCuffBand", size = Vector3.new(0.8738, 0.2478, 0.8803), centre = Vector3.new(2.0924, 3.23, 0.0842), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(176, 176, 166), transparency = 0, shadow = true, attach = "RightLowerArm" },
			{ name = "RightHand", size = Vector3.new(0.587, 1.5908, 0.8981), centre = Vector3.new(2.0564, 2.2976, 0.0332), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(82, 70, 52), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftUpperLeg", size = Vector3.new(1.1617, 2.4187, 1.1646), centre = Vector3.new(-0.561, 3.0396, 0.1589), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(44, 42, 39), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftLowerLeg", size = Vector3.new(0.9, 1.356, 0.9467), centre = Vector3.new(-0.6, 1.704, 0.1365), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(44, 42, 39), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftShinBand", size = Vector3.new(0.87, 0.2434, 0.8789), centre = Vector3.new(-0.6, 1.539, 0.1864), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(176, 176, 166), transparency = 0, shadow = true, attach = "LeftLowerLeg" },
			{ name = "LeftFoot", size = Vector3.new(0.96, 1.209, 1.728), centre = Vector3.new(-0.6, 0.6045, -0.0886), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(30, 28, 26), transparency = 0, shadow = true, attach = "" },
			{ name = "RightUpperLeg", size = Vector3.new(1.1617, 2.4187, 1.1646), centre = Vector3.new(0.561, 3.0396, 0.1589), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(44, 42, 39), transparency = 0, shadow = true, attach = "" },
			{ name = "RightLowerLeg", size = Vector3.new(0.9, 1.356, 0.9467), centre = Vector3.new(0.6, 1.704, 0.1365), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(44, 42, 39), transparency = 0, shadow = true, attach = "" },
			{ name = "RightShinBand", size = Vector3.new(0.87, 0.2434, 0.8789), centre = Vector3.new(0.6, 1.539, 0.1864), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(176, 176, 166), transparency = 0, shadow = true, attach = "RightLowerLeg" },
			{ name = "RightFoot", size = Vector3.new(0.96, 1.209, 1.728), centre = Vector3.new(0.6, 0.6045, -0.0886), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(30, 28, 26), transparency = 0, shadow = true, attach = "" },
		},
		joints = {
			LeftAnkle = Vector3.new(-0.6, 0.72, 0.05),
			LeftElbow = Vector3.new(-2.06, 4.75, 0.02),
			LeftHip = Vector3.new(-0.56, 3.85, 0),
			LeftKnee = Vector3.new(-0.6, 2.25, -0.05),
			LeftShoulder = Vector3.new(-1.86, 6.85, -0.06),
			LeftWrist = Vector3.new(-2.1, 2.85, -0.1),
			Neck = Vector3.new(0, 7.4, 0),
			RightAnkle = Vector3.new(0.6, 0.72, 0.05),
			RightElbow = Vector3.new(2.06, 4.75, 0.02),
			RightHip = Vector3.new(0.56, 3.85, 0),
			RightKnee = Vector3.new(0.6, 2.25, -0.05),
			RightShoulder = Vector3.new(1.86, 6.85, -0.06),
			RightWrist = Vector3.new(2.1, 2.85, -0.1),
			Root = Vector3.new(0, 4, 0),
			Waist = Vector3.new(0, 4.6, 0),
		},
	},
	gurney = {
		tris = 1676,
		size = Vector3.new(2.738, 3.36, 6.61),
		origin = Vector3.new(0.0108, 0, 0.075), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Frame", size = Vector3.new(2.68, 3.115, 6.61), centre = Vector3.new(-0.0108, 1.8025, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 172, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "Castors", size = Vector3.new(2.32, 0.4, 6.1804), centre = Vector3.new(-0.0108, 0.2, 0.005), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(34, 34, 36), transparency = 0, shadow = true, attach = "" },
			{ name = "Mattress", size = Vector3.new(2.4, 0.42, 6.1), centre = Vector3.new(-0.0108, 2.55, -0.075), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(110, 140, 130), transparency = 0, shadow = true, attach = "" },
			{ name = "Pillow", size = Vector3.new(1.7647, 0.356, 1.0974), centre = Vector3.new(0.0892, 2.86, -2.525), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(200, 206, 200), transparency = 0, shadow = true, attach = "" },
			{ name = "Sheet", size = Vector3.new(2.738, 2.1465, 4.3251), centre = Vector3.new(0, 1.86, 0.725), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(196, 204, 198), transparency = 0, shadow = true, attach = "" },
		},
	},
	handrail = {
		tris = 704,
		size = Vector3.new(16.6663, 0.485, 0.59),
		origin = Vector3.new(0, 2.755, -0.295), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Rail", size = Vector3.new(16.6663, 0.28, 0.575), centre = Vector3.new(0, 0.345, -0.0075), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(150, 128, 96), transparency = 0, shadow = true, attach = "" },
			{ name = "Brackets", size = Vector3.new(15.16, 0.45, 0.49), centre = Vector3.new(0, 0.225, 0.05), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 172, 170), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_cashbox = {
		tris = 452,
		size = Vector3.new(1.62, 0.91, 1.265),
		origin = Vector3.new(0, 0, -0.0225), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Box", size = Vector3.new(1.62, 0.84, 1.22), centre = Vector3.new(0, 0.42, 0.0225), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 80, 60), transparency = 0, shadow = true, attach = "" },
			{ name = "Handle", size = Vector3.new(0.84, 0.1, 0.1), centre = Vector3.new(0, 0.86, 0.0225), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(110, 110, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Lock", size = Vector3.new(0.34, 0.3, 0.065), centre = Vector3.new(0, 0.55, -0.6), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 124, 70), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_fan = {
		tris = 1814,
		size = Vector3.new(1.71, 1.805, 0.8037),
		origin = Vector3.new(0, 0, 0.0781), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Guard", size = Vector3.new(1.71, 1.71, 0.4341), centre = Vector3.new(0, 0.95, -0.1848), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(190, 190, 176), transparency = 0, shadow = true, attach = "" },
			{ name = "Blades", size = Vector3.new(1.397, 1.431, 0.2476), centre = Vector3.new(0, 0.95, -0.1781), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 150, 140), transparency = 0, shadow = true, attach = "" },
			{ name = "Body", size = Vector3.new(1, 1.2, 0.72), centre = Vector3.new(0, 0.6, 0.0419), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 62, 58), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_idol = {
		tris = 472,
		size = Vector3.new(1.16, 2.273, 1.16),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Figure", size = Vector3.new(1.16, 2.273, 1.16), centre = Vector3.new(0, 1.1365, 0), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(196, 150, 60), transparency = 0, shadow = true, attach = "" },
			{ name = "Groove", size = Vector3.new(0.05, 0.5, 0.04), centre = Vector3.new(0, 1.78, -0.34), look = "foil", material = "Foil", surface = "", colour = Color3.fromRGB(60, 44, 20), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_pager = {
		tris = 388,
		size = Vector3.new(0.78, 0.36, 1.25),
		origin = Vector3.new(0, 0, -0.045), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(0.78, 0.36, 1.25), centre = Vector3.new(0, 0.18, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 40, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "Screen", size = Vector3.new(0.56, 0.04, 0.36), centre = Vector3.new(0, 0.32, -0.105), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(104, 122, 92), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_phone = {
		tris = 1128,
		size = Vector3.new(1.48, 0.86, 1.16),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(1.36, 0.629, 1.16), centre = Vector3.new(0, 0.3145, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(132, 38, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Handset", size = Vector3.new(1.48, 0.24, 0.32), centre = Vector3.new(0, 0.74, 0.28), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(132, 38, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Dial", size = Vector3.new(0.5909, 0.587, 0.1863), centre = Vector3.new(0, 0.52, -0.38), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 146, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "DialFace", size = Vector3.new(0.4819, 0.4378, 0.1329), centre = Vector3.new(0.0025, 0.4984, -0.4247), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(34, 30, 28), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_reel = {
		tris = 1256,
		size = Vector3.new(0.4266, 1.58, 1.58),
		origin = Vector3.new(0, 0.01, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Flanges", size = Vector3.new(0.4266, 1.58, 1.58), centre = Vector3.new(0, 0.79, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(120, 120, 126), transparency = 0, shadow = true, attach = "" },
			{ name = "Film", size = Vector3.new(0.3, 1.1, 1.1), centre = Vector3.new(0, 0.79, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(48, 38, 30), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_stapler = {
		tris = 316,
		size = Vector3.new(0.56, 0.6022, 1.56),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Base", size = Vector3.new(0.56, 0.44, 1.56), centre = Vector3.new(0, 0.22, 0), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(70, 60, 52), transparency = 0, shadow = true, attach = "" },
			{ name = "Arm", size = Vector3.new(0.46, 0.4723, 1.4397), centre = Vector3.new(0, 0.3661, -0.0502), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(110, 40, 36), transparency = 0, shadow = true, attach = "" },
		},
	},
	item_typewriter = {
		tris = 928,
		size = Vector3.new(2, 1.249, 1.52),
		origin = Vector3.new(0, 0, 0.04), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(2, 0.8928, 1.5), centre = Vector3.new(0, 0.4464, 0.01), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(30, 34, 30), transparency = 0, shadow = true, attach = "" },
			{ name = "Platen", size = Vector3.new(1.9, 0.26, 0.2535), centre = Vector3.new(0, 0.73, 0.46), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(28, 28, 28), transparency = 0, shadow = true, attach = "" },
			{ name = "Keys", size = Vector3.new(1.44, 0.21, 0.5806), centre = Vector3.new(0.05, 0.495, -0.4697), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(196, 188, 164), transparency = 0, shadow = true, attach = "" },
			{ name = "Paper", size = Vector3.new(1.2, 0.5506, 0.1261), centre = Vector3.new(0, 0.9737, 0.5141), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(226, 222, 206), transparency = 0, shadow = true, attach = "" },
		},
	},
	iv_stand = {
		tris = 1120,
		size = Vector3.new(1.7, 6.35, 1.7875),
		origin = Vector3.new(0.08, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Pole", size = Vector3.new(1.5484, 6.201, 1.6281), centre = Vector3.new(-0.0113, 3.2495, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 172, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "Castors", size = Vector3.new(1.7, 0.22, 1.7875), centre = Vector3.new(0, 0.11, 0), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(34, 34, 36), transparency = 0, shadow = true, attach = "" },
			{ name = "Bag", size = Vector3.new(0.8736, 3.6892, 0.2481), centre = Vector3.new(0.2182, 4.1304, 0.044), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(210, 214, 200), transparency = 0.35, shadow = false, attach = "" },
		},
	},
	junction_box = {
		tris = 584,
		size = Vector3.new(1.66, 8.4082, 0.6784),
		origin = Vector3.new(-0.03, 2.6418, -0.3392), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Box", size = Vector3.new(1.66, 2, 0.48), centre = Vector3.new(0, 2.3582, 0.0992), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(90, 96, 90), transparency = 0, shadow = true, attach = "" },
			{ name = "Conduit", size = Vector3.new(1.2866, 7.22, 0.5), centre = Vector3.new(0.03, 4.7982, 0.0792), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(110, 110, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Cable", size = Vector3.new(0.4338, 1.2348, 0.5361), centre = Vector3.new(0.4869, 0.6174, -0.0712), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(36, 34, 32), transparency = 0, shadow = true, attach = "" },
			{ name = "Label", size = Vector3.new(0.5, 0.45, 0.01), centre = Vector3.new(0.03, 2.7082, -0.1508), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(210, 170, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "Mark", size = Vector3.new(0.1573, 0.2529, 0.01), centre = Vector3.new(0.05, 2.7082, -0.1558), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(30, 28, 24), transparency = 0, shadow = true, attach = "" },
		},
	},
	keyboard = {
		tris = 854,
		size = Vector3.new(1.5, 0.107, 0.5004),
		origin = Vector3.new(0, -0.012, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Case", size = Vector3.new(1.5, 0.084, 0.5004), centre = Vector3.new(0, 0.042, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(186, 180, 162), transparency = 0, shadow = true, attach = "" },
			{ name = "Keys", size = Vector3.new(1.285, 0.053, 0.37), centre = Vector3.new(-0.02, 0.0805, -0.0075), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(206, 200, 182), transparency = 0, shadow = true, attach = "" },
		},
	},
	lift_doors = {
		tris = 772,
		size = Vector3.new(9.2, 10, 0.9),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Lift_Frame", size = Vector3.new(9.2, 10, 0.9), centre = Vector3.new(0, 5, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(108, 108, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Lift_LeafL", size = Vector3.new(3.98, 8.45, 0.205), centre = Vector3.new(-2, 4.25, -0.1725), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(130, 128, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Lift_LeafR", size = Vector3.new(3.98, 8.45, 0.205), centre = Vector3.new(2, 4.25, -0.1725), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(130, 128, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Lift_Glass", size = Vector3.new(4.9, 1.6, 0.04), centre = Vector3.new(0, 5.8, -0.24), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(150, 160, 150), transparency = 0.45, shadow = false, attach = "" },
			{ name = "Lift_Indicator", size = Vector3.new(1.2, 0.3, 0.04), centre = Vector3.new(0, 9.7, -0.39), look = "neon", material = "Neon", surface = "", colour = Color3.fromRGB(150, 112, 52), transparency = 0, shadow = false, attach = "" },
		},
	},
	locker = {
		tris = 788,
		size = Vector3.new(2.4, 6.5, 2.15),
		origin = Vector3.new(0, 0, -0.075), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(2.4, 6.5, 2), centre = Vector3.new(0, 3.25, 0.075), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(86, 92, 88), transparency = 0, shadow = true, attach = "" },
			{ name = "Door", size = Vector3.new(2.2, 5.9, 0.08), centre = Vector3.new(0, 3.45, -0.945), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(96, 98, 90), transparency = 0, shadow = true, attach = "" },
			{ name = "Vents", size = Vector3.new(1.3, 5.45, 0.03), centre = Vector3.new(0, 3.59, -0.995), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(30, 30, 28), transparency = 0, shadow = true, attach = "" },
			{ name = "Fittings", size = Vector3.new(2.06, 5.3, 0.16), centre = Vector3.new(-0.14, 3.45, -0.995), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 168, 160), transparency = 0, shadow = true, attach = "" },
		},
	},
	med_cabinet = {
		tris = 1376,
		size = Vector3.new(3, 6.3, 1.54),
		origin = Vector3.new(0, 0, -0.07), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(3, 5.4, 1.47), centre = Vector3.new(0, 2.7, 0.035), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(210, 212, 204), transparency = 0, shadow = true, attach = "" },
			{ name = "Inside", size = Vector3.new(2.8, 2.4, 1.12), centre = Vector3.new(0, 3.8, 0.03), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 154, 150), transparency = 0, shadow = true, attach = "" },
			{ name = "Glass", size = Vector3.new(2.7, 2.27, 0.02), centre = Vector3.new(0, 3.8, -0.66), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(150, 170, 170), transparency = 0.5, shadow = false, attach = "" },
			{ name = "Stock", size = Vector3.new(2.44, 2.2, 0.5), centre = Vector3.new(0, 4.13, 0.04), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(150, 100, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "Boxes", size = Vector3.new(1.6356, 2.045, 0.686), centre = Vector3.new(-0.2322, 4.0525, 0.07), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(214, 210, 196), transparency = 0, shadow = true, attach = "" },
			{ name = "Fittings", size = Vector3.new(0.9, 3.875, 0.14), centre = Vector3.new(0, 3.4375, -0.7), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(176, 176, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "SharpsBin", size = Vector3.new(0.8525, 0.75, 0.6784), centre = Vector3.new(1, 5.775, 0.07), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(200, 170, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "SharpsLid", size = Vector3.new(0.8995, 0.16, 0.7254), centre = Vector3.new(1, 6.22, 0.07), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(160, 40, 34), transparency = 0, shadow = true, attach = "" },
		},
	},
	notice_board = {
		tris = 1516,
		size = Vector3.new(5, 3.5, 0.2572),
		origin = Vector3.new(0, 0, -0.0486), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Cork", size = Vector3.new(4.7, 3.2, 0.1), centre = Vector3.new(0, 1.75, 0.0486), look = "cardboard", material = "Cardboard", surface = "SHIFT_Cardboard", colour = Color3.fromRGB(150, 112, 70), transparency = 0, shadow = true, attach = "" },
			{ name = "Frame", size = Vector3.new(5, 3.5, 0.2), centre = Vector3.new(0, 1.75, 0.0286), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(96, 78, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "Sheets", size = Vector3.new(4.1299, 2.6746, 0.1123), centre = Vector3.new(0.0265, 1.7431, -0.0725), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(222, 216, 196), transparency = 0, shadow = true, attach = "" },
			{ name = "Pins", size = Vector3.new(3.02, 1.82, 0.12), centre = Vector3.new(0.05, 2.08, -0.0514), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(120, 52, 40), transparency = 0, shadow = true, attach = "" },
		},
	},
	oil_drum = {
		tris = 1092,
		size = Vector3.new(2.24, 3.4376, 2.24),
		origin = Vector3.new(0, 0.0124, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Drum", size = Vector3.new(2.24, 3.3751, 2.24), centre = Vector3.new(0, 1.6876, 0), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(70, 84, 70), transparency = 0, shadow = true, attach = "" },
			{ name = "Bungs", size = Vector3.new(1.37, 0.08, 0.9602), centre = Vector3.new(0.015, 3.3976, 0.0101), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(120, 118, 110), transparency = 0, shadow = true, attach = "" },
		},
	},
	papers = {
		tris = 1488,
		size = Vector3.new(4.1902, 0.1734, 3.5188),
		origin = Vector3.new(-0.0922, -0.1284, 0.0501), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Papers", size = Vector3.new(4.1902, 0.1734, 3.5188), centre = Vector3.new(0, 0.0867, 0), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(222, 216, 196), transparency = 0, shadow = true, attach = "" },
		},
	},
	pillar = {
		tris = 260,
		size = Vector3.new(2.8, 11, 2.8),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Pillar", size = Vector3.new(2.4, 11, 2.4), centre = Vector3.new(0, 5.5, 0), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(190, 170, 96), transparency = 0, shadow = true, attach = "" },
			{ name = "Trim", size = Vector3.new(2.8, 10.995, 2.8), centre = Vector3.new(0, 5.4975, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
		},
	},
	pipe_drop = {
		tris = 1176,
		size = Vector3.new(1.7805, 6.66, 1.2871),
		origin = Vector3.new(0.2302, 2.46, -0.6935), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Pipe", size = Vector3.new(1.2471, 6.66, 1.225), centre = Vector3.new(-0.0567, 3.33, 0.031), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(96, 92, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "ValveWheel", size = Vector3.new(1.32, 1.32, 0.1141), centre = Vector3.new(-0.2302, 1.14, -0.5865), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(128, 44, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Gauge", size = Vector3.new(0.7409, 0.76, 0.14), centre = Vector3.new(0.5198, 2.34, -0.1265), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 146, 136), transparency = 0, shadow = true, attach = "" },
			{ name = "GaugeFace", size = Vector3.new(0.624, 0.64, 0.02), centre = Vector3.new(0.5198, 2.34, -0.2065), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(214, 208, 190), transparency = 0, shadow = true, attach = "" },
			{ name = "Needle", size = Vector3.new(0.1696, 0.2273, 0.01), centre = Vector3.new(0.5598, 2.39, -0.2215), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(150, 30, 24), transparency = 0, shadow = true, attach = "" },
		},
	},
	pipe_run = {
		tris = 1740,
		size = Vector3.new(20.06, 1.7, 1.0679),
		origin = Vector3.new(0, -1.2, -0.534), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Pipe", size = Vector3.new(20, 1.3, 0.7114), centre = Vector3.new(0, 0.9, -0.0515), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(96, 92, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "Flanges", size = Vector3.new(20.06, 0.96, 0.9359), centre = Vector3.new(0, 1.2, -0.066), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(80, 74, 66), transparency = 0, shadow = true, attach = "" },
			{ name = "Clamps", size = Vector3.new(15.25, 1.7, 0.67), centre = Vector3.new(0, 0.85, 0.199), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(50, 48, 44), transparency = 0, shadow = true, attach = "" },
		},
	},
	pump = {
		tris = 1728,
		size = Vector3.new(4.64, 6.1, 2.38),
		origin = Vector3.new(-0.03, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Base", size = Vector3.new(4.4, 0.72, 2.38), centre = Vector3.new(0.03, 0.36, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(70, 70, 66), transparency = 0, shadow = true, attach = "" },
			{ name = "Motor", size = Vector3.new(2.35, 2, 1.76), centre = Vector3.new(-1.145, 1.55, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 90, 80), transparency = 0, shadow = true, attach = "" },
			{ name = "Guard", size = Vector3.new(0.6, 0.9, 0.9), centre = Vector3.new(0.38, 1.45, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(170, 140, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "Casing", size = Vector3.new(1.44, 1.75, 1.6742), centre = Vector3.new(1.6, 1.425, 0), look = "rust", material = "CorrodedMetal", surface = "SHIFT_Rust", colour = Color3.fromRGB(90, 70, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "Pipe", size = Vector3.new(0.84, 4.8, 0.84), centre = Vector3.new(1.33, 3.7, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(96, 92, 84), transparency = 0, shadow = true, attach = "" },
			{ name = "Wheel", size = Vector3.new(0.7507, 0.77, 0.5428), centre = Vector3.new(1.33, 3.4, -0.5714), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(128, 44, 34), transparency = 0, shadow = true, attach = "" },
		},
	},
	shelf_rack = {
		tris = 1848,
		size = Vector3.new(8.2, 7.4, 2.6),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Uprights", size = Vector3.new(8.2, 7.4, 2.6), centre = Vector3.new(0, 3.7, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(70, 96, 140), transparency = 0, shadow = true, attach = "" },
			{ name = "Shelves", size = Vector3.new(7.94, 6.85, 2.36), centre = Vector3.new(0, 3.65, 0), look = "steel_plate", material = "DiamondPlate", surface = "SHIFT_SteelPlate", colour = Color3.fromRGB(120, 122, 120), transparency = 0, shadow = true, attach = "" },
			{ name = "Bracing", size = Vector3.new(8.04, 6.6783, 2.3554), centre = Vector3.new(0, 3.7038, 0.0423), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(54, 62, 74), transparency = 0, shadow = true, attach = "" },
			{ name = "Bolts", size = Vector3.new(8.11, 6.7, 2.2466), centre = Vector3.new(0, 3.64, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 150, 146), transparency = 0, shadow = true, attach = "" },
		},
	},
	shop_counter = {
		tris = 2040,
		size = Vector3.new(12, 6.15, 4),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(12, 3.3, 3.74), centre = Vector3.new(0, 1.65, 0.03), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(70, 56, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "Top", size = Vector3.new(11.951, 0.2665, 4), centre = Vector3.new(-0.0245, 3.4, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(96, 74, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "Fittings", size = Vector3.new(8.23, 0.44, 2.7), centre = Vector3.new(0.035, 3.71, 0), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(176, 150, 80), transparency = 0, shadow = true, attach = "" },
			{ name = "Tray", size = Vector3.new(1.2, 0.12, 0.9), centre = Vector3.new(2.6, 3.56, -0.7), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(60, 62, 60), transparency = 0, shadow = true, attach = "" },
			{ name = "ScreenHousing", size = Vector3.new(4.32, 2.7, 0.92), centre = Vector3.new(0, 4.8, 0.29), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 40, 38), transparency = 0, shadow = true, attach = "" },
		},
	},
	supply_locker = {
		tris = 484,
		size = Vector3.new(4.03, 7, 2.14),
		origin = Vector3.new(0, 0, -0.07), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(4, 7, 1.96), centre = Vector3.new(0, 3.5, 0.09), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(70, 84, 76), transparency = 0, shadow = true, attach = "" },
			{ name = "Doors", size = Vector3.new(3.9, 6.3, 0.03), centre = Vector3.new(0, 3.525, -0.925), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(78, 92, 82), transparency = 0, shadow = true, attach = "" },
			{ name = "Stripe", size = Vector3.new(3.6, 0.3, 0.01), centre = Vector3.new(0, 1.2, -0.942), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(180, 150, 50), transparency = 0, shadow = true, attach = "" },
			{ name = "Fittings", size = Vector3.new(4.03, 5.36, 0.175), centre = Vector3.new(0, 3.5, -0.9825), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(150, 148, 140), transparency = 0, shadow = true, attach = "" },
		},
	},
	tenant = {
		tris = 6856,
		size = Vector3.new(2.28, 8.1656, 2.2275),
		origin = Vector3.new(0, 0.0103, -0.7866), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Head", size = Vector3.new(0.5668, 1.5738, 1.4581), centre = Vector3.new(0.0731, 7.1555, -0.3847), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "Face", size = Vector3.new(0.4312, 0.3243, 0.4764), centre = Vector3.new(0.0819, 6.5643, -0.8153), look = "plaster", material = "Plaster", surface = "", colour = Color3.fromRGB(226, 221, 208), transparency = 0, shadow = true, attach = "Head" },
			{ name = "FaceHoles", size = Vector3.new(0.3258, 0.2554, 0.3429), centre = Vector3.new(0.0742, 6.5569, -0.7689), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(8, 7, 7), transparency = 0, shadow = true, attach = "Head" },
			{ name = "UpperTorso", size = Vector3.new(1.9612, 3.184, 1.0433), centre = Vector3.new(0, 6.5737, 0.5386), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LowerTorso", size = Vector3.new(1.02, 1.128, 0.4843), centre = Vector3.new(0, 4.8797, 0.8716), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftUpperArm", size = Vector3.new(0.5094, 2.6262, 0.8318), centre = Vector3.new(-0.8853, 6.3428, 0.0375), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftLowerArm", size = Vector3.new(0.244, 2.9615, 0.8815), centre = Vector3.new(-1.002, 3.8055, 0.1508), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftHand", size = Vector3.new(0.2665, 1.9094, 0.524), centre = Vector3.new(-0.9537, 1.515, 0.5316), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightUpperArm", size = Vector3.new(0.5094, 2.7666, 0.8321), centre = Vector3.new(0.8853, 6.413, 0.0377), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightLowerArm", size = Vector3.new(0.244, 2.9615, 0.8815), centre = Vector3.new(1.002, 3.8055, 0.1508), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightHand", size = Vector3.new(0.2665, 1.9094, 0.524), centre = Vector3.new(0.9537, 1.515, 0.5316), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftUpperLeg", size = Vector3.new(0.4149, 2.5335, 0.6086), centre = Vector3.new(-0.3675, 3.5215, 0.7359), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftLowerLeg", size = Vector3.new(0.29, 2.0014, 0.5414), centre = Vector3.new(-0.415, 1.5368, 0.7296), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "LeftFoot", size = Vector3.new(0.3236, 0.6997, 1.132), centre = Vector3.new(-0.41, 0.3499, 0.4906), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightUpperLeg", size = Vector3.new(0.4149, 2.5335, 0.6086), centre = Vector3.new(0.3675, 3.5215, 0.7359), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightLowerLeg", size = Vector3.new(0.29, 2.0014, 0.5414), centre = Vector3.new(0.415, 1.5368, 0.7296), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
			{ name = "RightFoot", size = Vector3.new(0.3236, 0.6997, 1.132), centre = Vector3.new(0.41, 0.3499, 0.4906), look = "skin", material = "Rubber", surface = "SHIFT_TenantSkin", colour = Color3.fromRGB(20, 18, 18), transparency = 0, shadow = true, attach = "" },
		},
		joints = {
			FaceLight = Vector3.new(0.1212, 5.868, -2.1177),
			LeftAnkle = Vector3.new(-0.4, 0.62, 0.14),
			LeftElbow = Vector3.new(-1, 5.18, -0.96),
			LeftHip = Vector3.new(-0.36, 4.6, 0.06),
			LeftKnee = Vector3.new(-0.42, 2.42, -0.2),
			LeftShoulder = Vector3.new(-0.8, 7.5, -0.5),
			LeftWrist = Vector3.new(-1.02, 2.42, -0.28),
			Neck = Vector3.new(0, 7.64, -0.7),
			RightAnkle = Vector3.new(0.4, 0.62, 0.14),
			RightElbow = Vector3.new(1, 5.18, -0.96),
			RightHip = Vector3.new(0.36, 4.6, 0.06),
			RightKnee = Vector3.new(0.42, 2.42, -0.2),
			RightShoulder = Vector3.new(0.8, 7.64, -0.5),
			RightWrist = Vector3.new(1.02, 2.42, -0.28),
			Root = Vector3.new(0, 4.7, 0.05),
			Waist = Vector3.new(0, 5.2, 0.06),
		},
	},
	vent_grate = {
		tris = 752,
		size = Vector3.new(2.6, 1.3, 0.1265),
		origin = Vector3.new(0, -0.65, -0.0632), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "VentFrame", size = Vector3.new(2.6, 1.3, 0.125), centre = Vector3.new(0, 0.65, 0.0007), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(176, 172, 160), transparency = 0, shadow = true, attach = "" },
			{ name = "VentBack", size = Vector3.new(2.36, 1.06, 0.03), centre = Vector3.new(0, 0.65, 0.0482), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(34, 33, 30), transparency = 0, shadow = true, attach = "" },
			{ name = "Louvres", size = Vector3.new(2.34, 1.029, 0.113), centre = Vector3.new(0, 0.65, -0.0068), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(160, 156, 146), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_clock = {
		tris = 1580,
		size = Vector3.new(2.12, 2.12, 0.31),
		origin = Vector3.new(0, -1.06, 0.005), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Rim", size = Vector3.new(2.12, 2.12, 0.31), centre = Vector3.new(0, 1.06, 0), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 38, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Face", size = Vector3.new(1.84, 1.84, 0.02), centre = Vector3.new(0, 1.06, -0.075), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(214, 208, 188), transparency = 0, shadow = true, attach = "" },
			{ name = "Marks", size = Vector3.new(1.72, 1.72, 0.015), centre = Vector3.new(0, 1.06, -0.09), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(40, 38, 34), transparency = 0, shadow = true, attach = "" },
			{ name = "Hands", size = Vector3.new(0.6779, 0.2187, 0.045), centre = Vector3.new(-0.2819, 1.0107, -0.1175), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(30, 28, 26), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_doorway = {
		tris = 484,
		size = Vector3.new(20, 11, 1.2216),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Wall", size = Vector3.new(20, 11, 1), centre = Vector3.new(0, 5.5, 0), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(201, 181, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Skirting", size = Vector3.new(20, 0.71, 1.2216), centre = Vector3.new(0, 0.355, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_outlet = {
		tris = 292,
		size = Vector3.new(0.55, 0.85, 0.101),
		origin = Vector3.new(0, 0.975, -0.0505), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Plate", size = Vector3.new(0.55, 0.85, 0.1), centre = Vector3.new(0, 0.425, 0.0005), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(226, 220, 200), transparency = 0, shadow = true, attach = "" },
			{ name = "Holes", size = Vector3.new(0.17, 0.5275, 0.01), centre = Vector3.new(-0.04, 0.4412, -0.0455), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(34, 32, 30), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_panel = {
		tris = 44,
		size = Vector3.new(20, 11, 1),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Wall", size = Vector3.new(20, 11, 1), centre = Vector3.new(0, 5.5, 0), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(201, 181, 104), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_panel_peeling = {
		tris = 1276,
		size = Vector3.new(20, 11, 3.2065),
		origin = Vector3.new(0, 0, -0.9924), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Wall", size = Vector3.new(20, 11, 1), centre = Vector3.new(0, 5.5, 0.9924), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(201, 181, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Skirting", size = Vector3.new(20, 0.71, 1.2216), centre = Vector3.new(0, 0.355, 0.9924), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
			{ name = "Plaster", size = Vector3.new(15.6, 9.2, 0.03), centre = Vector3.new(0.7, 5.9, 0.4774), look = "plaster", material = "Plaster", surface = "", colour = Color3.fromRGB(186, 178, 158), transparency = 0, shadow = true, attach = "" },
			{ name = "Peel", size = Vector3.new(10.95, 2.672, 2.0783), centre = Vector3.new(-1.375, 9.1749, -0.5641), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(168, 150, 98), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_panel_skirting = {
		tris = 220,
		size = Vector3.new(20, 11, 1.2216),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Wall", size = Vector3.new(20, 11, 1), centre = Vector3.new(0, 5.5, 0), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(201, 181, 104), transparency = 0, shadow = true, attach = "" },
			{ name = "Skirting", size = Vector3.new(20, 0.71, 1.2216), centre = Vector3.new(0, 0.355, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
		},
	},
	wall_post = {
		tris = 196,
		size = Vector3.new(1.38, 11, 1.38),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Post", size = Vector3.new(1.2, 11, 1.2), centre = Vector3.new(0, 5.5, 0), look = "wallpaper", material = "Plaster", surface = "SHIFT_Wallpaper", colour = Color3.fromRGB(194, 175, 100), transparency = 0, shadow = true, attach = "" },
			{ name = "Skirting", size = Vector3.new(1.38, 0.71, 1.38), centre = Vector3.new(0, 0.355, 0), look = "wood", material = "Wood", surface = "SHIFT_Wood", colour = Color3.fromRGB(112, 94, 54), transparency = 0, shadow = true, attach = "" },
		},
	},
	wardrobe = {
		tris = 1592,
		size = Vector3.new(6.1, 8, 3.27),
		origin = Vector3.new(0, 0, -0.085), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(6.1, 8, 3.1), centre = Vector3.new(0, 4, 0.085), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(80, 74, 64), transparency = 0, shadow = true, attach = "" },
			{ name = "Doors", size = Vector3.new(5.84, 7.1, 0.08), centre = Vector3.new(0, 4, -1.455), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(92, 86, 74), transparency = 0, shadow = true, attach = "" },
			{ name = "Vents", size = Vector3.new(4.36, 6.58, 0.03), centre = Vector3.new(0, 4.15, -1.515), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(30, 28, 26), transparency = 0, shadow = true, attach = "" },
			{ name = "Fittings", size = Vector3.new(6.02, 6, 0.25), centre = Vector3.new(0, 4, -1.51), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 168, 160), transparency = 0, shadow = true, attach = "" },
		},
	},
	wastebin = {
		tris = 1054,
		size = Vector3.new(0.97, 1.4442, 1.215),
		origin = Vector3.new(0, 0, 0.1225), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Bin", size = Vector3.new(0.97, 1.1503, 0.97), centre = Vector3.new(0, 0.5752, -0.1225), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(70, 72, 70), transparency = 0, shadow = true, attach = "" },
			{ name = "Paper", size = Vector3.new(0.8223, 0.7814, 1.073), centre = Vector3.new(0.0359, 1.0535, 0.071), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(226, 222, 206), transparency = 0, shadow = true, attach = "" },
		},
	},
	wastebin_tipped = {
		tris = 984,
		size = Vector3.new(1.6594, 1.0972, 3.4192),
		origin = Vector3.new(-0.0246, -0.1621, -1.1404), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Bin", size = Vector3.new(0.97, 0.97, 1.1595), centre = Vector3.new(0.0246, 0.6121, 1.1298), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(70, 72, 70), transparency = 0, shadow = true, attach = "" },
			{ name = "Paper", size = Vector3.new(1.6594, 0.5141, 2.298), centre = Vector3.new(0, 0.257, -0.5606), look = "paper", material = "Fabric", surface = "SHIFT_Paper", colour = Color3.fromRGB(226, 222, 206), transparency = 0, shadow = true, attach = "" },
		},
	},
	water_cooler = {
		tris = 988,
		size = Vector3.new(1.4, 4.95, 1.47),
		origin = Vector3.new(0, 0, -0.035), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Body", size = Vector3.new(1.4, 3.425, 1.4), centre = Vector3.new(0, 1.7125, 0.035), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(206, 200, 184), transparency = 0, shadow = true, attach = "" },
			{ name = "Bay", size = Vector3.new(1.2, 0.505, 0.515), centre = Vector3.new(0, 2.4725, -0.4075), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(70, 70, 66), transparency = 0, shadow = true, attach = "" },
			{ name = "TapCold", size = Vector3.new(0.2, 0.25, 0.3), centre = Vector3.new(0.3, 2.62, -0.585), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(60, 90, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "TapHot", size = Vector3.new(0.2, 0.25, 0.3), centre = Vector3.new(-0.3, 2.62, -0.585), look = "worn_plastic", material = "Plastic", surface = "SHIFT_AgedPlastic", colour = Color3.fromRGB(170, 50, 40), transparency = 0, shadow = true, attach = "" },
			{ name = "Bottle", size = Vector3.new(1.14, 1.77, 1.14), centre = Vector3.new(0, 4.065, 0.035), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(150, 176, 186), transparency = 0.45, shadow = false, attach = "" },
			{ name = "Water", size = Vector3.new(1.06, 0.756, 1.0334), centre = Vector3.new(0, 3.635, 0.035), look = "glass", material = "Glass", surface = "", colour = Color3.fromRGB(110, 150, 170), transparency = 0.25, shadow = false, attach = "" },
		},
	},
	wheelchair = {
		tris = 1860,
		size = Vector3.new(2.66, 4.04, 3.7487),
		origin = Vector3.new(0, 0, -0.1843), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Frame", size = Vector3.new(2.66, 3.8613, 3.2762), centre = Vector3.new(0, 2.0807, 0.0215), look = "brushed_metal", material = "Metal", surface = "SHIFT_BrushedMetal", colour = Color3.fromRGB(170, 172, 170), transparency = 0, shadow = true, attach = "" },
			{ name = "Upholstery", size = Vector3.new(2.1, 2.12, 2.615), centre = Vector3.new(0, 2.98, 0.5668), look = "fabric", material = "Fabric", surface = "SHIFT_Fabric", colour = Color3.fromRGB(40, 42, 44), transparency = 0, shadow = true, attach = "" },
			{ name = "Tyres", size = Vector3.new(2.4522, 2.6, 3.6587), centre = Vector3.new(0, 1.3, -0.045), look = "rubber", material = "Rubber", surface = "SHIFT_Rubber", colour = Color3.fromRGB(30, 30, 32), transparency = 0, shadow = true, attach = "" },
		},
	},
}
