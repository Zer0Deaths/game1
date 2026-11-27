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
