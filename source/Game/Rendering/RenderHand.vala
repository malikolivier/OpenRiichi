using Engine;
using Gee;

private class RenderHand : WorldObject
{
    private int drawn;
    private Vec3 tile_size;
    private WorldObject wrap;

    public RenderHand(Vec3 tile_size, float view_angle)
    {
        tiles = new ArrayList<RenderTile>();
        this.tile_size = tile_size;
        this.view_angle = view_angle;
        winning_tile = null;
    }

    public override void added()
    {
        rotation = new Quat.from_euler(0, 0.5f -view_angle, 0);
        wrap = new WorldObject();
        add_object(wrap);
        wrap.position = Vec3(0, tile_size.y / 2, -tile_size.z / 2);
    }

    public void draw_tile(RenderTile tile)
    {
        wrap.convert_object(tile);
        winning_tile = null;
        drawn++;

        if (tiles.size > 1 && drawn >= 14)
        {
            sort_hand();
            order_hand(true);
            order_draw_tile(tile);
            tiles.add(tile);
        }
        else
        {
            tiles.add(tile);
            sort_hand();
            order_hand(true);
        }
    }

    public void remove(RenderTile tile)
    {
        tiles.remove(tile);
        sort_hand();
        order_hand(true);
    }

    public ArrayList<RenderTile> get_tiles_type(TileType type)
    {
        ArrayList<RenderTile> tiles = new ArrayList<RenderTile>();

        foreach (RenderTile tile in this.tiles)
            if (tile.tile_type.tile_type == type)
                tiles.add(tile);

        return tiles;
    }

    public void sort_hand()
    {
        tiles = RenderTile.sort_tiles(tiles);
    }

    public void order_hand(bool animate)
    {
        for (int i = 0; i < tiles.size; i++)
            order_tile(tiles[i], i, animate);

        if (winning_tile != null)
            order_tile(winning_tile, tiles.size + 0.5f, animate);
    }

    private void order_tile(RenderTile tile, float tile_position, bool animate)
    {
        Vec3 pos = Vec3((tile_position - (tiles.size - 1) / 2.0f) * tile_size.x, 0, 0);

        if (animate)
            tile.animate_towards(pos, new Quat());
        else
            tile.set_absolute_location(pos, new Quat());
    }

    private void order_draw_tile(RenderTile tile)
    {
        Vec3 pos = Vec3
        (
            (tiles.size / 2.0f - 1) * tile_size.x,
            0,
            -(tile_size.z + tile_size.x) / 2
        );

        Quat rot = new Quat.from_euler(0.5f, 0, 0);

        tile.animate_towards(pos, rot);
    }

    public ArrayList<RenderTile> tiles { get; private set; }
    public float view_angle { get; set; }
    public RenderTile? winning_tile { get; set; }
    public bool open { get; set; }  // Open riichi
}