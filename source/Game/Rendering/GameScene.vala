using Engine;
using Gee;

class GameScene : WorldObject
{
    private Options options;
    private int observer_index;
    private int dealer;
    private int wall_index;
    private RoundScoreState score;
    private AnimationTimings timings;

    private AudioPlayer audio;
    private Sound slide_sound;
    private Sound flip_sound;
    private Sound discard_sound;
    private Sound draw_sound;
    private Sound ron_sound;
    private Sound tsumo_sound;
    private Sound riichi_sound;
    private Sound kan_sound;
    private Sound pon_sound;
    private Sound chii_sound;
    private Sound reveal_sound;

    //private float table_length;
    //private Vec3 tile_size;

    private RenderTable table;

    private Mutex action_lock;
    private ArrayList<RenderAction> actions = new ArrayList<RenderAction>();
    private RenderAction? current_action = null;
    private float action_start_time;

    public GameScene(Options options, int observer_index, int dealer, int wall_index, AudioPlayer audio, RoundScoreState score, AnimationTimings timings)
    {
        this.options = options;
        this.observer_index = observer_index;
        this.dealer = dealer;
        this.wall_index = wall_index;
        this.audio = audio;
        this.score = score;
        this.timings = timings;
    }

    public override void added()
    {
        slide_sound = audio.load_sound("slide");
        flip_sound = audio.load_sound("flip");
        discard_sound = audio.load_sound("discard");
        draw_sound = audio.load_sound("draw");
        ron_sound = audio.load_sound("ron");
        tsumo_sound = audio.load_sound("tsumo");
        riichi_sound = audio.load_sound("riichi");
        kan_sound = audio.load_sound("kan");
        pon_sound = audio.load_sound("pon");
        chii_sound = audio.load_sound("chii");
        reveal_sound = audio.load_sound("reveal");

        //int index = player_index == -1 ? 0 : player_index;

        //float tile_scale = 1.74f;
        string extension = Options.quality_enum_to_string(options.model_quality);

        //table = new RenderTable(extension, tile_size, round_wind, -(float)index / 2, score);
        //add_object(table);

        /*table_length = table.player_offset;
        float wall_offset = (tile_size.x * 19 + tile_size.z) / 2;

        for (int i = 0; i < tiles.length; i++)
        {
            RenderTile t = new RenderTile();
            add_object(t);
            t.tile_type = new Tile(i, TileType.BLANK, false);
            t.front_color = options.tile_fore_color;
            t.back_color = options.tile_back_color;
            tiles[i] = t;
        }

        wall = new RenderWall(tiles, tile_size, wall_offset, dealer, wall_index);
        add_object(wall);

        for (int i = 0; i < players.length; i++)
        {
            players[i] = new RenderPlayer(i, i == dealer, table_length, wall_offset, tile_size, i == index, round_wind);
            add_object(players[i]);
        }

        observer = players[index];

        float camera_height = table_length * 1.8f;
        float camera_dist = table_length * 1.0f;

        WorldCamera camera = new TargetWorldCamera(table);
        table.add_object(camera);
        camera.position = Vec3(0, camera_height, camera_dist);
        //camera.yaw = (float)observer.seat / 2;*/

        table = new RenderTable(extension, observer_index, dealer, Vec3(0, 0, 0), wall_index, 0, score);
        add_object(table);
    }

    public void load_options(Options options)
    {
        this.options = options;

        string extension = Options.quality_enum_to_string(options.model_quality);

        foreach (RenderTile tile in tiles)
        {
            // extension, options.tile_textures
            tile.reload();
            tile.front_color = options.tile_fore_color;
            tile.back_color = options.tile_back_color;
        }
        table.reload(extension);
    }

    public override void process(DeltaArgs delta)
    {
        if (current_action != null &&
            delta.time - action_start_time > current_action.time.total())
            current_action = null;

        if (current_action == null)
        {
            lock (action_lock)
            {
                if (actions.size != 0)
                {
                    current_action = actions[0];
                    actions.remove_at(0);

                    action_start_time = delta.time;
                    do_action(current_action);
                }
            }
        }
    }

    public void add_action(RenderAction action)
    {
        lock (action_lock)
            actions.add(action);
    }

    private void do_action(RenderAction action)
    {
        if (action is RenderActionSplitDeadWall)
            action_split_dead_wall(action as RenderActionSplitDeadWall);
        else if (action is RenderActionInitialDraw)
            action_initial_draw(action as RenderActionInitialDraw);
        else if (action is RenderActionDraw)
            action_draw(action as RenderActionDraw);
        else if (action is RenderActionDrawDeadWall)
            action_draw_dead_wall(action as RenderActionDrawDeadWall);
        else if (action is RenderActionDiscard)
            action_discard(action as RenderActionDiscard);
        else if (action is RenderActionRon)
            action_ron(action as RenderActionRon);
        else if (action is RenderActionTsumo)
            action_tsumo(action as RenderActionTsumo);
        else if (action is RenderActionRiichi)
            action_riichi(action as RenderActionRiichi);
        else if (action is RenderActionReturnRiichi)
            action_return_riichi(action as RenderActionReturnRiichi);
        else if (action is RenderActionLateKan)
            action_late_kan(action as RenderActionLateKan);
        else if (action is RenderActionClosedKan)
            action_closed_kan(action as RenderActionClosedKan);
        else if (action is RenderActionOpenKan)
            action_open_kan(action as RenderActionOpenKan);
        else if (action is RenderActionPon)
            action_pon(action as RenderActionPon);
        else if (action is RenderActionChii)
            action_chii(action as RenderActionChii);
        else if (action is RenderActionGameDraw)
            action_game_draw(action as RenderActionGameDraw);
        else if (action is RenderActionHandReveal)
            action_hand_reveal(action as RenderActionHandReveal);
        else if (action is RenderActionFlipDora)
            action_flip_dora(action as RenderActionFlipDora);
        else if (action is RenderActionFlipUraDora)
            action_flip_ura_dora(action as RenderActionFlipUraDora);
        else if (action is RenderActionSetActive)
            action_set_active(action as RenderActionSetActive);
    }

    private void action_split_dead_wall(RenderActionSplitDeadWall action)
    {
        slide_sound.play();
        table.split_dead_wall();//action.time);
    }

    private void action_initial_draw(RenderActionInitialDraw action)
    {
        draw_sound.play();
        for (int i = 0; i < action.tiles; i++)
            action.player.draw_tile(wall.draw_wall());//action.time));
    }

    private void action_draw(RenderActionDraw action)
    {
        draw_sound.play();
        action.player.draw_tile(wall.draw_wall());//action.time));

        if (action.player.seat == observer_index)
            active = true;
    }

    private void action_draw_dead_wall(RenderActionDrawDeadWall action)
    {
        wall.flip_dora();
        wall.dead_tile_add();
        draw_sound.play();
        action.player.draw_tile(wall.draw_dead_wall());//action.time));

        if (action.player.seat == observer_index)
            active = true;
    }

    private void action_discard(RenderActionDiscard action)
    {
        discard_sound.play();
        action.player.discard(action.tile);//, action.time);
    }

    private void action_ron(RenderActionRon action)
    {
        ron_sound.play();

        if (action.winners.length == 1 && action.tile != null)
            action.winners[0].ron(action.tile);//, action.time);

        bool flip_ura_dora = false;

        foreach (RenderPlayer player in action.winners)
        {
            if (!player.open)
                add_action(new RenderActionHandReveal(timings.hand_reveal, player));
            if (player.in_riichi)
                flip_ura_dora = true;
        }

        if (action.return_riichi_player != null)
            add_action(new RenderActionReturnRiichi(new AnimationTime.zero(), action.return_riichi_player));

        if (flip_ura_dora && action.allow_dora_flip)
            add_action(new RenderActionFlipUraDora(new AnimationTime.zero()));
    }

    private void action_tsumo(RenderActionTsumo action)
    {
        tsumo_sound.play();
        action.player.tsumo();//action.time);

        if (!action.player.open)
            add_action(new RenderActionHandReveal(timings.hand_reveal, action.player));

        if (action.player.in_riichi)
            add_action(new RenderActionFlipUraDora(new AnimationTime.zero()));
    }

    private void action_riichi(RenderActionRiichi action)
    {
        riichi_sound.play();
        if (action.open)
            reveal_sound.play();

        action.player.riichi(action.open);//, action.time);
    }

    private void action_return_riichi(RenderActionReturnRiichi action)
    {
        action.player.return_riichi(action.time);
    }

    private void action_late_kan(RenderActionLateKan action)
    {
        action.player.late_kan(action.tile, action.time);
        kan_sound.play();
    }

    private void action_closed_kan(RenderActionClosedKan action)
    {
        action.player.closed_kan(action.tile_type, action.time);
        kan_sound.play();
    }

    private void action_open_kan(RenderActionOpenKan action)
    {
        action.discarder.rob_tile(action.tile);
        action.player.open_kan(action.discarder, action.tile, action.tile_1, action.tile_2, action.tile_3);//, action.time);
        kan_sound.play();
    }

    private void action_pon(RenderActionPon action)
    {
        pon_sound.play();
        action.discarder.rob_tile(action.tile);
        action.player.pon(action.discarder, action.tile, action.tile_1, action.tile_2);//, action.time);

        if (action.player.seat == observer_index)
            active = true;
    }

    private void action_chii(RenderActionChii action)
    {
        chii_sound.play();
        action.discarder.rob_tile(action.tile);
        action.player.chii(action.tile, action.tile_1, action.tile_2, action.time);

        if (action.player.seat == observer_index)
            active = true;
    }

    private void action_game_draw(RenderActionGameDraw action)
    {
        bool revealed = false;

        foreach (RenderPlayer player in players)
        {
            if (action.players.contains(player))
            {
                if (!player.open)
                {
                    player.open_hand();//action.time);
                    revealed = true;
                }
            }
            else if (player != observer && action.draw_type != GameDrawType.VOID_HAND)
            {
                player.close_hand();//action.time);
                revealed = true;
            }
        }

        if (revealed)
            reveal_sound.play();
    }

    private void action_hand_reveal(RenderActionHandReveal action)
    {
        reveal_sound.play();
        action.player.open_hand();//action.time);
    }

    private void action_flip_dora(RenderActionFlipDora action)
    {
        flip_sound.play();
        wall.flip_dora();
    }

    private void action_flip_ura_dora(RenderActionFlipUraDora action)
    {
        flip_sound.play();
        wall.flip_ura_dora();
    }

    private void action_set_active(RenderActionSetActive action)
    {
        active = action.active;
    }

    /*private void position_lights(float rotation)
    {
        Vec3 pos;

        pos = Vec3(0, 50, table_length / 2);
        pos = Calculations.rotate_y(Vec3.empty(), rotation, pos);
        light1.position = pos;

        pos = Vec3(0, 50, table_length);
        pos = Calculations.rotate_y(Vec3.empty(), rotation, pos);
        light2.position = pos;
    }*/

    public RenderPlayer[] players { get { return table.players; } }
    public RenderTile[] tiles { get { return table.tiles; } }
    public RenderWall wall { get { return table.wall; } }
    public RenderPlayer observer { get; private set; }
    public Camera camera { get; private set; }
    public bool active { get; set; }
}
