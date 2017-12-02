using Engine;
using Gee;

public class RenderTile : WorldObjectTransformable
{
    private bool _hovered = false;
    private bool _indicated = false;
    private float _scale;

    private Color _front_color = Color.white();
    private Color _back_color = Color.black();

    public RenderTile()
    {
        tile_type = new Tile(0, TileType.BLANK, false);
        _scale = 1;

        selectable = true;
    }

    protected override void added()
    {
        reload();
    }

    public void reload()
    {
        RenderGeometry3D tile = store.load_geometry_3D("tile_" + quality_to_string(model_quality), false);
        set_object(tile);

        transform.scale = Vec3(scale, scale, scale);
        front = ((RenderObject3D)tile.geometry[0]);
        back  = ((RenderObject3D)tile.geometry[1]);
        obb = Vec3(front.model.size.x, front.model.size.y + back.model.size.y, front.model.size.z);

        load_material();
    }

    private void load_material()
    {
        MaterialSpecification spec = front.material.spec;
        spec.ambient_color = UniformType.STATIC;
        spec.diffuse_color = UniformType.STATIC;
        spec.target_color = UniformType.DYNAMIC;
        spec.static_ambient_color = Color.white();
        spec.static_diffuse_color = Color.white();
        front.material = store.load_material(spec);
        front.material.textures[0] = get_texture();

        spec = back.material.spec;
        spec.textures = 0;
        spec.ambient_color = UniformType.STATIC;
        spec.diffuse_color = UniformType.STATIC;
        spec.target_color = UniformType.DYNAMIC;
        spec.static_ambient_color = Color.black();
        spec.static_diffuse_color = Color.black();
        back.material = store.load_material(spec);

        set_diffuse_color();
    }

    private RenderTexture get_texture()
    {
        string tex = tile_texture_type_to_string(texture_type);
        string name = "Tiles/" + tex + "/" + TILE_TYPE_TO_STRING(tile_type.tile_type);

        if (tile_type.dora)
        {
            RenderTexture? texture = store.load_texture(name + "-Dora");
            if (texture != null)
                return texture;
        }

        return store.load_texture(name);
    }

    public void set_absolute_location(Vec3 position, Quat rotation)
    {
        cancel_buffered_animations();
        transform.rotation = rotation;
        transform.position = position;
    }

    public void animate_towards(Vec3 position, Quat rotation)
    {
        animate_towards_with_time(position, rotation, 0.15f);
    }

    public void animate_towards_with_time(Vec3 position, Quat rotation, float time)
    {
        WorldObjectAnimation animation = new WorldObjectAnimation(new AnimationTime.preset(time));
        Path3D path = new LinearPath3D(position);
        animation.do_absolute_position(path);
        PathQuat rot = new LinearPathQuat(rotation);
        animation.do_absolute_rotation(rot);

        animation.curve = new SmoothApproachCurve();
        
        cancel_buffered_animations();
        animate(animation, true);
    }

    private void set_diffuse_color()
    {
        /*front.material.diffuse_color = front_color;
        back.material.diffuse_color = back_color;
        back.material.diffuse_material_strength = 0;*/

        Color amb = indicated ? Color(-1.0f, 1.0f, -1.0f, 0.3f) : Color.none();

        float target = 0f;
        if (hovered)
        {
            target = 0.5f;
            amb = Color(0.3f, 0.3f, 0.2f, 0.5f);
        }

        Color col = Color(1, 1, 0, 1);
        /*front.material.set_uniform("target_color", new ColorUniformData(col));
        back.material.set_uniform("target_color", new ColorUniformData(col));
        front.material.set_uniform("target_color_strength", new FloatUniformData(target));
        back.material.set_uniform("target_color_strength", new FloatUniformData(target));*/
        front.material.target_color = col;
        back.material.target_color = col;
        front.material.target_color_strength = target;
        back.material.target_color_strength = target;
        /*
        float strength = 0.4f;
        //front.material.ambient_color = Color(strength * 1.5f, strength * 1.5f, strength, 0);
        //back.material.ambient_color = Color(strength * 1.5f, strength * 1.5f, strength, 0);

        if (hovered)
        {
            amb = ;
            //front.material.ambient_color = Color(strength * 1.5f, strength * 1.5f, strength, 1);
            //back.material.ambient_color = Color(strength * 1.5f, strength * 1.5f, strength, 1);
            //front.material.ambient_color = Color(.a = 1.0f;
            //back.material.ambient_color.a = 1.0f;* /
        }
        else
        {
            amb = Color.none();
            //front.material.ambient_color = front_color;
            //back.material.ambient_color = back_color;
            //front.material.diffuse_color = front_color;
            //back.material.diffuse_color = back_color;
        }*/

        /*front.material.ambient_color = Color
        (
            front_color.r + amb.r,
            front_color.g + amb.g,
            front_color.b + amb.b,
            front.material.ambient_material_strength / 2 + amb.a
        );

        back.material.ambient_color = Color
        (
            back_color.r + amb.r,
            back_color.g + amb.g,
            back_color.b + amb.b,
            back.material.ambient_material_strength / 2 + amb.a
        );*/
    }

    public Color front_color
    {
        get { return _front_color; }
        set
        {
            _front_color = value;
            set_diffuse_color();
        }
    }

    public Color back_color
    {
        get { return _back_color; }
        set
        {
            _back_color = value;
            set_diffuse_color();
        }
    }

    public float alpha
    {
        get { return front.material.alpha; }
        set
        {
            front.material.alpha = value;
            back.material.alpha = value;
        }
    }

    private RenderObject3D front { get; private set; }
    private RenderObject3D back { get; private set; }
    public Tile tile_type { get; set; }
    public ModelQuality model_quality { get; set; }
    public TextureType texture_type { get; set; }

    public new float scale
    {
        get { return _scale; }
        set
        {
            _scale = value;
            transform.scale = Vec3(value, value, value);
        }
    }

    public bool hovered
    {
        get { return _hovered; }
        set
        {
            _hovered = value;
            set_diffuse_color();
        }
    }

    public bool indicated
    {
        get { return _indicated; }
        set
        {
            _indicated = value;
            set_diffuse_color();
        }
    }

    public enum ModelQuality
    {
        LOW,
        HIGH
    }

    public enum TextureType
    {
        REGULAR,
        BLACK
    }

    private static string quality_to_string(ModelQuality quality)
    {
        return quality == ModelQuality.LOW ? "low" : "high";
    }

    private static string tile_texture_type_to_string(TextureType texture_type)
    {
        return texture_type == TextureType.BLACK ? "black" : "regular";
    }

    public static ArrayList<RenderTile> sort_tiles(ArrayList<RenderTile> list)
    {
        ArrayList<RenderTile> tiles = new ArrayList<RenderTile>();
        tiles.add_all(list);

        tiles.sort
        (
            (t1, t2) =>
            {
                int a = (int)t1.tile_type.tile_type;
                int b = (int)t2.tile_type.tile_type;
                return (int) (a > b) - (int) (a < b);
            }
        );

        return tiles;
    }
}
