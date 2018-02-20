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
        last_drawn_tile = null;
    }

    public override void added()
    {
        rotation = Quat.from_euler(0, 0.5f - view_angle, 0);
        wrap = new WorldObject();
        add_object(wrap);
        wrap.position = Vec3(0, tile_size.y / 2, -tile_size.z / 2);
    }

    public void draw_tile(RenderTile tile)
    {
        last_drawn_tile = null;
        wrap.convert_object(tile);
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

        last_drawn_tile = tile;
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

        if (last_drawn_tile != null)
            order_tile(last_drawn_tile, tiles.size + 0.5f, animate);
    }

    public void ron(RenderTile tile)
    {
        tsumo();
    }

    public void tsumo()
    {
        order_tile(last_drawn_tile, tiles.size + 0.5f, true);
        
        WorldObjectAnimation animation = new WorldObjectAnimation(new AnimationTime.preset(0.5f));
        PathQuat rot = new LinearPathQuat(Quat());
        animation.do_absolute_rotation(rot);
        animation.curve = new SmoothDepartCurve();
        
        cancel_buffered_animations();
        animate(animation, true);
    }

    public void open_hand()
    {
        open = true;
        tsumo();
    }

    public void close_hand()
    {
        WorldObjectAnimation animation = new WorldObjectAnimation(new AnimationTime.preset(0.5f));
        PathQuat rot = new LinearPathQuat(Quat.from_euler(0, 1, 0));
        animation.do_absolute_rotation(rot);
        animation.curve = new SmoothDepartCurve();
        cancel_buffered_animations();
        animate(animation, true);

        animation = new WorldObjectAnimation(new AnimationTime.preset(0.5f));
        Path3D path = new LinearPath3D(Vec3(0, -tile_size.y / 2, -tile_size.z / 2));
        animation.do_absolute_position(path);
        animation.curve = new SmoothDepartCurve();
        wrap.animate(animation, true);
    }

    public void animate_angle(float angle)
    {
        if (open)
            return;

        WorldObjectAnimation animation = new WorldObjectAnimation(new AnimationTime.preset(2));
        PathQuat rot = new LinearPathQuat(Quat.from_euler(0, 0.5f - angle, 0));
        animation.do_absolute_rotation(rot);
        animation.curve = new SCurve(0.5f);

        cancel_buffered_animations();
        animate(animation, true);
    }

    private void order_tile(RenderTile tile, float tile_position, bool animate)
    {
        Vec3 pos = Vec3((tile_position - (tiles.size - 1) / 2.0f) * tile_size.x, 0, 0);

        if (animate)
            tile.animate_towards(pos, Quat());
        else
            tile.set_absolute_location(pos, Quat());
    }

    private void order_draw_tile(RenderTile tile)
    {
        Vec3 pos = Vec3
        (
            (tiles.size / 2.0f - 1) * tile_size.x,
            0,
            -(tile_size.z + tile_size.x) / 2
        );

        Quat rot = Quat.from_euler(0.5f, 0, 0);

        tile.animate_towards(pos, rot);
    }

    public ArrayList<RenderTile> tiles { get; private set; }
    public float view_angle { get; set; }
    public RenderTile? last_drawn_tile { get; private set; }
    public bool open { get; set; }  // Open riichi
}