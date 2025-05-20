-- Changes light aquifers to heavy locally post embark
-- SWD basically inversion of hack/scripts/light-aquifers-only.lua
local help = [====[

heavy-aquifers-only
===================
Modified by SWD from the light-aquifers-only script.

Pre embark: Nothing, unlike light-aquifers-only.

Post embark, changes the aquifers at the embark site to heavy aquifer.

This script is based on logic revealed by ToadyOne in a FotF answer:
http://www.bay12forums.com/smf/index.php?topic=169696.msg8099138#msg8099138
Basically the Drainage is used as an "RNG" to cause an aquifer to be heavy
about 5% of the time. The script shifts the matching numbers to a neighboring
one, which does not result in any change of the biome.

Post embark:
Sets the flags that mark aquifer tiles as heavy or not, converting them to heavy.
]====]

function heavyaqonly (arg)
  if arg and arg:match('help') then
    print(help)
    return
  end
  if not dfhack.isWorldLoaded () or not dfhack.isMapLoaded () then
    qerror ("Error: This script requires a world and a map to be loaded.")
  end

  if dfhack.isMapLoaded () then
    for i, block in ipairs (df.global.world.map.map_blocks) do
      if block.flags.has_aquifer then
        for k = 0, 15 do
          for l = 0, 15 do
            -- if (block.occupancy [k] [l].heavy_aquifer == true) then
            --   dfhack.print ("H")
	    -- else
            --   dfhack.print ("L")
	    -- end
            block.occupancy [k] [l].heavy_aquifer = true
          end
          -- dfhack.println();
        end
        -- dfhack.println();
      end
    end
  end
end

heavyaqonly (...)
