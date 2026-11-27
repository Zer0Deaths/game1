# Entities: making real meshes and animations

**The Tenant now has a Blender model** (`blender/scripts/tenant.py`, 15 R15 body parts, about 6,100 triangles, the 1024 TenantSkin PBR set). Once it's uploaded the game builds the Tenant from it, on the skeleton the script writes into `MeshManifest`; the built body below is the fallback. A model you put in `ServerStorage.SHIFT_Models` (below) still wins over both. New entity ideas are in `docs/entities.md`.

The Tenant and Lampjaw already work with built-in bodies: proper R15-style rigs with a procedural walk, run, idle and attack. Everything below is optional and swaps in your own versions. Nothing breaks if you skip a step; the game falls back to the built-in body or animation on its own.

**The look to aim for:** tall, thin, near-black, featureless. No face, no clothes detail. You glimpse them at the end of a corridor or in a flicker, so a strong silhouette matters more than fine detail.

## 1. Make the mesh (under 20,000 triangles)

**Option A: Roblox Cube (inside Studio)**
1. Open the **Assistant** (View > Assistant) and ask it to generate a mesh, for example:
   *"A very tall, thin humanoid figure, near-black skin, no face, arms hanging past the knees, hunched forward, T-pose, simple and smooth."*
2. It drops a MeshPart into Workspace. Cube meshes are well under 20k triangles.

**Option B: Tripo (tripo3d.ai, in your browser)**
1. Use the same prompt. When you export, pick **FBX**, set **Face limit 20000**, and turn on **textures (PBR)** and **auto-rig (humanoid)** if it offers it.
2. In Studio: **File > Import 3D**, pick the file. The importer shows the triangle count; keep it under 20,000. It also creates a SurfaceAppearance from the PBR textures for you.

## 2. Turn it into an R15 rig

1. Select the mesh, then open **Avatar > Avatar Setup**. It auto-rigs and skins the mesh as R15 (HumanoidRootPart, 15 body parts, joints).
2. Check that the model has a part called **HumanoidRootPart**. The game needs that name.
3. Lampjaw is different: it hangs from a light. Make its HumanoidRootPart the top point (where it meets the fitting) and let the body hang down about 3.5 studs.

## 3. Put it in the game

1. In the Explorer, right-click **ServerStorage** and choose Insert Object > Folder. Name the folder **SHIFT_Models**.
2. Drag your rig into it and rename it exactly **Tenant** (or **Lampjaw**).
3. Save the place, then Play. Output says `[EntityRig] using your Tenant model from ServerStorage.SHIFT_Models`.

(Rojo doesn't touch ServerStorage, so your models stay put through pulls.)

## 4. Animations (Animation Editor)

You can animate your own model, or the built-in rig. To get a copy of the built-in rig, paste this in **View > Command Bar** (not while playing):

    require(game.ServerScriptService.Server.EntityRig).spawnForEditing("Tenant")

Then:
1. **Avatar > Animation Editor**, click the rig, name the animation.
2. Make these (keep them slow and unnatural):
   - Tenant: **idle** (looped; breathing, head slowly turning), **walk** (looped; long slow strides, arms hanging loose), **run** (looped; loping, arms reaching forward), **attack** (not looped, about 0.7 s; a lunge with both arms).
   - Lampjaw: **idle** (looped; neck swaying, jaw chattering), **attack** (not looped; a fast bite downward).
3. For each one: the **...** menu > **Publish to Roblox**, then copy the number it gives you.
4. Paste the numbers into `src/shared/Config.luau` under `ANIMATIONS` (or send them to Claude):

        ANIMATIONS = {
            Tenant = { idle = "123...", walk = "123...", run = "123...", attack = "123..." },
            Lampjaw = { idle = "123...", attack = "123..." },
        },

   Any you leave empty keep using the built-in procedural version.

## 5. What each entity does (for animating to)

- **The Tenant**: hunts by sound. Walks to whatever it hears, stops and shrieks when it sees you, then runs at you. Its cue is a wet clicking breath. Lights near it stutter.
- **Lampjaw**: hides in a flickering light near you and strobes red. Stand under it too long and it bites. It's only visible in the red flashes. Its cue is an electrical crackle with chattering teeth.
