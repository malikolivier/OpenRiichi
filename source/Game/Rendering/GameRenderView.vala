using Engine;
using Gee;

public class GameRenderView : View3D, IGameRenderer
{
    private RenderTile[] tiles { get { return scene.tiles; } }
    private RenderPlayer[] players { get { return scene.players; } }

    private GameScene scene;
    private RenderTile? mouse_down_tile;
    private ArrayList<TileSelectionGroup>? select_groups = null;

    private Sound hover_sound;

    private RoundStartInfo info;
    private int observer_index;
    private int dealer_index;
    private Options options;
    private RoundScoreState score;
    private AnimationTimings timings;

    public GameRenderView(RoundStartInfo info, int observer_index, int dealer_index, Options options, RoundScoreState score, AnimationTimings timings)
    {
        this.info = info;
        this.observer_index = observer_index;
        this.dealer_index = dealer_index;
        this.options = options;
        this.score = score;
        this.timings = timings;
    }

    public override void added()
    {
        scene = new GameScene(options, observer_index, dealer_index, info.wall_index, store.audio_player, score, timings);

        WorldLight light1 = new WorldLight();
        WorldLight light2 = new WorldLight();
        world.add_object(light1);
        world.add_object(light2);

        light1.intensity = 20;
        light2.intensity = 4;
        light1.position = Vec3(0, 20, 0);
        light2.position = Vec3(0, 20, 0);
        
        world.add_object(scene);

        WorldObject target = new WorldObject();
        world.add_object(target);
        target.position = Vec3(0, -5, 0);

        WorldCamera camera = new TargetWorldCamera(target);
        scene.players[observer_index != -1 ? observer_index : 0].add_object(camera);
        world.active_camera = camera;
        camera.position = Vec3(0, 10, 10);

        buffer_action(new RenderActionDelay(new AnimationTime.preset(0.5f)));
        buffer_action(new RenderActionSplitDeadWall(timings.split_wall));

        hover_sound = store.audio_player.load_sound("mouse_over");

        int index = dealer_index;

        foreach (RenderTile tile in scene.tiles)
        {
            tile.on_mouse_over.connect(tile_hover);
            tile.on_focus_lost.connect(tile_unhover);
        }
        world.do_picking = true;

        for (int i = 0; i < 3; i++)
        {
            for (int p = 0; p < 4; p++)
            {
                buffer_action(new RenderActionInitialDraw(timings.initial_draw, players[index % 4], 4));
                index++;
            }
        }

        for (int p = 0; p < 4; p++)
        {
            buffer_action(new RenderActionInitialDraw(timings.initial_draw, players[index % 4], 1));
            index++;
        }

        buffer_action(new RenderActionFlipDora());
    }

    public void load_options(Options options)
    {
        scene.load_options(options);
    }

    private void game_finished(RoundFinishResult results)
    {
        switch (results.result)
        {
        case RoundFinishResult.RoundResultEnum.DRAW:
            draw(results.tenpai_indices, results.draw_type);
            break;
        case RoundFinishResult.RoundResultEnum.RON:
            ron(results.winner_indices, results.loser_index, results.discard_tile, results.riichi_return_index, true);
            break;
        case RoundFinishResult.RoundResultEnum.TSUMO:
            tsumo(results.winner_indices[0]);
            break;
        }
    }

    private void ron(int[] winner_indices, int discard_player_index, int tile_ID, int return_riichi_index, bool allow_dora_flip)
    {
        RenderPlayer? discard_player = null;
        if (discard_player_index != -1)
            discard_player = players[discard_player_index];

        RenderPlayer? return_riichi_player = null;
        if (return_riichi_index != -1)
            return_riichi_player = players[return_riichi_index];

        RenderTile? tile = null;

        if (tile_ID != -1)
        {
            tile = tiles[tile_ID];
            discard_player.rob_tile(tile);
        }

        RenderPlayer[] winners = new RenderPlayer[winner_indices.length];
        for (int i = 0; i < winners.length; i++)
            winners[i] = players[winner_indices[i]];

        buffer_action(new RenderActionRon(timings.win, winners, discard_player, tile, return_riichi_player, allow_dora_flip));
    }

    private void tsumo(int player_index)
    {
        RenderPlayer player = players[player_index];
        buffer_action(new RenderActionTsumo(timings.win, player));
    }

    private void draw(int[] tenpai_indices, GameDrawType draw_type)
    {
        if (draw_type == GameDrawType.TRIPLE_RON)
        {
            ron(tenpai_indices, -1, -1, -1, false);
            return;
        }

        if (draw_type == GameDrawType.EMPTY_WALL ||
            draw_type == GameDrawType.FOUR_RIICHI ||
            draw_type == GameDrawType.VOID_HAND ||
            draw_type == GameDrawType.TRIPLE_RON)
        {
            ArrayList<RenderPlayer> tenpai_players = new ArrayList<RenderPlayer>();
            foreach (int i in tenpai_indices)
                tenpai_players.add(players[i]);

            buffer_action(new RenderActionGameDraw(new AnimationTime.zero(), tenpai_players, draw_type));
        }
    }

    private void tile_assignment(Tile tile)
    {
        RenderTile t = tiles[tile.ID];
        t.tile_type = tile;
        t.reload();
    }

    private void tile_draw(int player_index)
    {
        RenderPlayer player = players[player_index];
        buffer_action(new RenderActionDraw(timings.tile_draw, player));

        /*if (tile_draw.dead_wall)
            player.draw_tile(scene.wall.draw_dead_wall());
        else
            player.draw_tile(scene.wall.draw_wall());*/
    }

    public void dead_tile_draw(int player_index)
    {
        RenderPlayer player = players[player_index];
        buffer_action(new RenderActionDrawDeadWall(timings.tile_draw, player));
    }

    private void tile_discard(int player_index, int tile_ID)
    {
        RenderPlayer player = players[player_index];
        RenderTile tile = tiles[tile_ID];
        buffer_action(new RenderActionDiscard(timings.tile_discard, player, tile));
    }

    private void flip_dora()
    {
        scene.wall.flip_dora();
    }

    /*private void server_dead_tile_add()
    {
        scene.wall.dead_tile_add();
    }*/

    private void riichi(int player_index, bool open)
    {
        RenderPlayer player = players[player_index];
        buffer_action(new RenderActionRiichi(timings.riichi, player, open));
    }

    private void late_kan(int player_index, int tile_ID)
    {
        RenderPlayer player = players[player_index];
        RenderTile tile = tiles[tile_ID];
        buffer_action(new RenderActionLateKan(timings.call, player, tile));
    }

    private void closed_kan(int player_index, TileType type)
    {
        RenderPlayer player = players[player_index];
        buffer_action(new RenderActionClosedKan(timings.call, player, type));
    }

    private void open_kan(int player_index, int discard_player_index, int tile_ID, int tile_1_ID, int tile_2_ID, int tile_3_ID)
    {
        RenderPlayer player = players[player_index];
        RenderPlayer discard_player = players[discard_player_index];

        RenderTile tile   = tiles[tile_ID];
        RenderTile tile_1 = tiles[tile_1_ID];
        RenderTile tile_2 = tiles[tile_2_ID];
        RenderTile tile_3 = tiles[tile_3_ID];

        buffer_action(new RenderActionOpenKan(timings.call, player, discard_player, tile, tile_1, tile_2, tile_3));

        dead_tile_draw(player_index);
    }

    private void pon(int player_index, int discard_player_index, int tile_ID, int tile_1_ID, int tile_2_ID)
    {
        RenderPlayer player = players[player_index];
        RenderPlayer discard_player = players[discard_player_index];

        RenderTile tile   = tiles[tile_ID];
        RenderTile tile_1 = tiles[tile_1_ID];
        RenderTile tile_2 = tiles[tile_2_ID];

        buffer_action(new RenderActionPon(timings.call, player, discard_player, tile, tile_1, tile_2));
    }

    private void chii(int player_index, int discard_player_index, int tile_ID, int tile_1_ID, int tile_2_ID)
    {
        RenderPlayer player = players[player_index];
        RenderPlayer discard_player = players[discard_player_index];

        RenderTile tile   = tiles[tile_ID];
        RenderTile tile_1 = tiles[tile_1_ID];
        RenderTile tile_2 = tiles[tile_2_ID];

        buffer_action(new RenderActionChii(timings.call, player, discard_player, tile, tile_1, tile_2));
    }

    public void set_active(bool active)
    {
        if (active)
            buffer_action(new RenderActionSetActive(active));
        else
            scene.active = active;

        if (!active)
            foreach (RenderTile tile in tiles)
                tile.indicated = false;
    }

    /////////////////////

    private void buffer_action(RenderAction action)
    {
        scene.add_action(action);
    }

    private RenderTile? hover_tile = null;
    private void tile_hover(WorldObject obj)
    {
        RenderTile tile = obj as RenderTile;
        tile.hovered = true;
        hover_tile = tile;
    }

    private void tile_unhover(WorldObject obj)
    {
        RenderTile tile = obj as RenderTile;
        tile.hovered = false;
        hover_tile = null;
    }

    protected override void mouse_move(MouseMoveArgs mouse)
    {
        base.mouse_move(mouse);

        RenderTile? tile = null;
        if (!mouse.handled && scene.active)
            tile = hover_tile;

        bool hovered = false;

        if (tile != null)
        {
            if (select_groups == null)
            {
                if (!tile.hovered)
                    hover_sound.play();

                foreach (RenderTile t in tiles)
                    t.hovered = false;

                tile.hovered = true;
                hovered = true;
            }
            else
            {
                TileSelectionGroup? group = get_tile_selection_group(tile);

                if (group != null)
                {
                    if (!tile.hovered)
                        hover_sound.play();
                    foreach (RenderTile t in tiles)
                        t.hovered = false;
                    foreach (Tile t in group.highlight_tiles)
                        tiles[t.ID].hovered = true;

                    hovered = true;
                }
                else
                    foreach (RenderTile t in tiles)
                        t.hovered = false;
            }
        }
        else
            foreach (RenderTile t in tiles)
                t.hovered = false;

        if (hovered)
        {
            mouse.cursor_type = CursorType.HOVER;
            mouse.handled = true;
        }
    }

    private TileSelectionGroup? get_tile_selection_group(RenderTile? tile)
    {
        if (tile == null || select_groups == null)
            return null;

        foreach (TileSelectionGroup group in select_groups)
            foreach (Tile t in group.selection_tiles)
                if (t.ID == tile.tile_type.ID)
                    return group;

        return null;
    }

    protected override void mouse_event(MouseEventArgs mouse)
    {
        if (mouse.handled || !scene.active)
        {
            mouse_down_tile = null;
            return;
        }

        if (mouse.button == MouseEventArgs.Button.LEFT)
        {
            RenderTile? tile = hover_tile;

            if (mouse.down)
            {
                if (select_groups != null && get_tile_selection_group(tile) == null)
                    tile = null;

                mouse_down_tile = tile;
            }
            else
            {
                if (select_groups != null && get_tile_selection_group(tile) == null)
                    tile = null;

                if (tile != null && tile == mouse_down_tile)
                    tile_selected(tile.tile_type);

                mouse_down_tile = null;
            }
        }
    }

    public void set_tile_select_groups(ArrayList<TileSelectionGroup>? groups)
    {
        foreach (RenderTile tile in scene.tiles)
            tile.indicated = false;

        select_groups = groups;

        if (groups != null)
            foreach (TileSelectionGroup group in groups)
                if (group.group_type != TileSelectionGroup.GroupType.DISCARD)
                    foreach (Tile tile in group.highlight_tiles)
                        tiles[tile.ID].indicated = true;
    }
}
