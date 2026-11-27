--!strict
-- WRITTEN BY blender/build_all.py from the Blender exports: don't edit by hand.
-- Every SHIFT model: its size and origin (studs) and, for each MeshPart,
-- its size, centre (relative to the model's bottom-centre origin) and look.
-- Meshes.luau uses this to place uploaded meshes exactly where the
-- primitive parts they replace stand.
return {
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
	ceiling_tile = {
		tris = 1144,
		size = Vector3.new(20.26, 0.28, 20.26),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Tiles", size = Vector3.new(19.82, 0.22, 19.82), centre = Vector3.new(0, 0.17, 0), look = "ceiling", material = "Plaster", surface = "SHIFT_CeilingTile", colour = Color3.fromRGB(206, 201, 178), transparency = 0, shadow = true, attach = "" },
			{ name = "Grid", size = Vector3.new(20.26, 0.08, 20.26), centre = Vector3.new(0, 0.04, 0), look = "painted_metal", material = "Metal", surface = "SHIFT_PaintedMetal", colour = Color3.fromRGB(150, 146, 128), transparency = 0, shadow = true, attach = "" },
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
		tris = 704,
		size = Vector3.new(19.96, 0.12, 19.96),
		origin = Vector3.new(0, 0, 0), -- where the origin sits in the frame the script modelled it in
		parts = {
			{ name = "Carpet", size = Vector3.new(19.96, 0.12, 19.96), centre = Vector3.new(0, 0.06, 0), look = "carpet", material = "Carpet", surface = "SHIFT_Carpet", colour = Color3.fromRGB(128, 110, 62), transparency = 0, shadow = true, attach = "" },
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
}
