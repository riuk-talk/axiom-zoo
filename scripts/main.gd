extends Node2D
# AXIOM Zoo - prototype Android jouable sans publicité ni énergie.
const SAVE := "user://axiom_zoo_save.json"
const W := 64.0
const H := 32.0
const SECTOR := 12
const BUILDINGS := {"path": 20, "tree": 45, "habitat": 200, "shop": 350, "water": 80}
const NAMES := {"path": "Chemin", "tree": "Arbre", "habitat": "Habitat", "shop": "Boutique", "water": "Bassin"}
const SPECIES := {"zebra": {"name": "Zèbre", "cost": 400, "symbol": "Z"}, "flamingo": {"name": "Flamant", "cost": 250, "symbol": "F"}, "giraffe": {"name": "Girafe", "cost": 600, "symbol": "G"}, "penguin": {"name": "Manchot", "cost": 500, "symbol": "M"}}
var coins := 2500
var tiles: Dictionary = {}
var animals: Dictionary = {}
var parcels: Array[Vector2i] = [Vector2i.ZERO]
var choice := "habitat"
var selected_species := "zebra"
var tool := "build"
var origin := Vector2(625, 170)
var scale_factor := 0.85
var label_coins: Label
var label_status: Label
var label_summary: Label
var status := "Bienvenue dans AXIOM Zoo !"
var elapsed := 0.0
var touch_down := Vector2.ZERO
var moved := false
var dragging := false
var ui_top: PanelContainer
var ui_side: PanelContainer
var ui_bottom: PanelContainer
var ui_grid: GridContainer
var map_area := Rect2()

func _ready() -> void:
    load_game()
    make_ui()
    get_viewport().size_changed.connect(layout_ui)
    layout_ui()
    update_ui()
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed >= 10.0:
        elapsed = 0.0
        var gain := animals.size() * 2 + count_type("shop") * 3
        if gain > 0:
            coins += gain
            status = "+%d pièces de revenus." % gain
            save_game()
            update_ui()

func count_type(kind: String) -> int:
    var result := 0
    for v in tiles.values():
        if v == kind:
            result += 1
    return result

func make_button(parent: Node, title: String, action: Callable) -> void:
    var b := Button.new()
    b.text = title
    b.custom_minimum_size = Vector2(140, 72)
    b.add_theme_font_size_override("font_size", 20)
    b.pressed.connect(action)
    parent.add_child(b)

func make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var top := PanelContainer.new()
    ui_top = top
    top.position = Vector2(10, 10)
    top.size = Vector2(1260, 74)
    layer.add_child(top)
    var bar := HBoxContainer.new()
    top.add_child(bar)
    var title := Label.new()
    title.text = " AXIOM ZOO  "
    bar.add_child(title)
    label_coins = Label.new()
    bar.add_child(label_coins)
    label_summary = Label.new()
    bar.add_child(label_summary)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.add_child(spacer)
    make_button(bar, "Gagner +150", earn)
    make_button(bar, "Sauver", save_game)
    make_button(bar, "Recentrer", recenter)
    var panel := PanelContainer.new()
    ui_side = panel
    panel.position = Vector2(10, 95)
    panel.size = Vector2(210, 545)
    layer.add_child(panel)
    var scroll := ScrollContainer.new()
    panel.add_child(scroll)
    var buttons := GridContainer.new()
    ui_grid = buttons
    scroll.add_child(buttons)
    for key in BUILDINGS:
        var kind: String = key
        make_button(buttons, "%s (%d)" % [NAMES[kind], BUILDINGS[kind]], func(): choose_build(kind))
    make_button(buttons, "Acheter parcelle", func(): set_tool("expand"))
    make_button(buttons, "Supprimer", func(): set_tool("erase"))
    make_button(buttons, "Inspecter", func(): set_tool("inspect"))
    for key in SPECIES:
        var species: String = key
        make_button(buttons, "%s (%d)" % [SPECIES[species]["name"], SPECIES[species]["cost"]], func(): choose_animal(species))
    var bottom := PanelContainer.new()
    ui_bottom = bottom
    bottom.position = Vector2(10, 650)
    bottom.size = Vector2(1260, 58)
    layer.add_child(bottom)
    label_status = Label.new()
    bottom.add_child(label_status)

func layout_ui() -> void:
    var v := get_viewport_rect().size
    if v.x < 50 or v.y < 50:
        return
    ui_top.position = Vector2(8, 8)
    ui_top.size = Vector2(v.x - 16, 90)
    ui_bottom.position = Vector2(8, v.y - 65)
    ui_bottom.size = Vector2(v.x - 16, 57)
    if v.y >= v.x:
        var h := clampf(v.y * 0.23, 180, 340)
        ui_side.position = Vector2(8, v.y - h - 74)
        ui_side.size = Vector2(v.x - 16, h)
        ui_grid.columns = maxi(2, int((v.x - 24) / 155))
        map_area = Rect2(8, 108, v.x - 16, v.y - h - 192)
    else:
        var w := clampf(v.x * 0.25, 220, 380)
        ui_side.position = Vector2(8, 108)
        ui_side.size = Vector2(w, v.y - 181)
        ui_grid.columns = 2
        map_area = Rect2(w + 18, 108, v.x - w - 26, v.y - 181)
    recenter()

func update_ui() -> void:
    if label_coins == null:
        return
    label_coins.text = "  Pièces : %d  " % coins
    label_summary.text = "  Animaux : %d | Boutiques : %d | Parcelles : %d" % [animals.size(), count_type("shop"), parcels.size()]
    label_status.text = "  %s | Outil : %s" % [status, tool]

func choose_build(kind: String) -> void:
    choice = kind
    tool = "build"
    status = "Placer : %s" % NAMES[kind]
    update_ui()

func choose_animal(species: String) -> void:
    selected_species = species
    tool = "animal"
    status = "Choisis un habitat pour : %s" % SPECIES[species]["name"]
    update_ui()

func set_tool(value: String) -> void:
    tool = value
    status = "Mode : %s" % value
    update_ui()

func earn() -> void:
    coins += 150
    status = "+150 pièces (activité répétable)."
    save_game()
    update_ui()

func recenter() -> void:
    origin = map_area.get_center() - Vector2(0, SECTOR * H * scale_factor / 2.0)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.07, 0.13, 0.15))
    draw_rect(map_area, Color(0.12, 0.24, 0.20))
    for parcel in parcels:
        for x in range(SECTOR):
            for y in range(SECTOR):
                var cell := parcel * SECTOR + Vector2i(x, y)
                var p := tile_position(cell)
                var corners := PackedVector2Array([p + Vector2(0, -H * scale_factor / 2), p + Vector2(W * scale_factor / 2, 0), p + Vector2(0, H * scale_factor / 2), p + Vector2(-W * scale_factor / 2, 0)])
                var key := str(cell.x) + "," + str(cell.y)
                var kind: String = tiles.get(key, "")
                var tint := Color(0.24, 0.50, 0.27)
                match kind:
                    "path": tint = Color(0.60, 0.55, 0.43)
                    "tree": tint = Color(0.14, 0.39, 0.17)
                    "habitat": tint = Color(0.55, 0.43, 0.24)
                    "shop": tint = Color(0.35, 0.40, 0.75)
                    "water": tint = Color(0.20, 0.53, 0.82)
                draw_colored_polygon(corners, tint)
                draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), Color(0.10, 0.22, 0.12), 1.0)
                if kind != "":
                    var font := ThemeDB.fallback_font
                    var letter := kind.substr(0, 1).to_upper()
                    if animals.has(key):
                        letter = str(SPECIES.get(str(animals[key]), {"symbol": "?"})["symbol"])
                    draw_string(font, p + Vector2(-5, 5), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func tile_position(cell: Vector2i) -> Vector2:
    return origin + Vector2((cell.x - cell.y) * W * scale_factor / 2.0, (cell.x + cell.y) * H * scale_factor / 2.0)

func cell_at(screen: Vector2) -> Vector2i:
    var p := screen - origin
    var xx := p.x / (W * scale_factor / 2.0)
    var yy := p.y / (H * scale_factor / 2.0)
    return Vector2i(roundi((xx + yy) / 2.0), roundi((yy - xx) / 2.0))

func is_owned(cell: Vector2i) -> bool:
    return Vector2i(floori(float(cell.x) / SECTOR), floori(float(cell.y) / SECTOR)) in parcels

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_down = event.position
            moved = false
            dragging = true
        else:
            dragging = false
            if not moved:
                act_on(event.position)
    elif event is InputEventScreenDrag:
        origin += event.relative
        moved = true
        queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            touch_down = event.position
            moved = false
            dragging = true
        else:
            dragging = false
            if not moved:
                act_on(event.position)
    elif event is InputEventMouseMotion and dragging:
        if event.position.distance_to(touch_down) > 8.0:
            moved = true
        if moved:
            origin += event.relative
            queue_redraw()

func act_on(pos: Vector2) -> void:
    if not map_area.has_point(pos):
        return
    var cell := cell_at(pos)
    var key := str(cell.x) + "," + str(cell.y)
    if tool == "expand":
        var sector := Vector2i(floori(float(cell.x) / SECTOR), floori(float(cell.y) / SECTOR))
        var neighbor := false
        for p in parcels:
            if abs(p.x - sector.x) + abs(p.y - sector.y) == 1:
                neighbor = true
        if sector in parcels:
            status = "Parcelle déjà possédée."
        elif not neighbor:
            status = "Choisis une parcelle voisine."
        elif coins < 900:
            status = "Il faut 900 pièces."
        else:
            coins -= 900
            parcels.append(sector)
            status = "Nouvelle parcelle acquise !"
    elif not is_owned(cell):
        status = "Terrain non acquis."
    elif tool == "erase":
        if animals.has(key):
            animals.erase(key)
            status = "Animal transféré."
        elif tiles.has(key):
            tiles.erase(key)
            status = "Construction supprimée."
        else:
            status = "Case vide."
    elif tool == "inspect":
        if animals.has(key):
            var species: String = animals[key]
            var welfare := 70
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    var near_key := str(cell.x + dx) + "," + str(cell.y + dy)
                    if tiles.get(near_key, "") in ["tree", "water"]:
                        welfare += 5
            status = "%s : bien-être %d/100" % [SPECIES[species]["name"], mini(100, welfare)]
        else:
            status = "Aucun animal sur cette case."
    elif tool == "animal":
        if tiles.get(key, "") != "habitat":
            status = "Sélectionne une case habitat."
        elif animals.has(key):
            status = "Habitat déjà occupé."
        elif coins < int(SPECIES[selected_species]["cost"]):
            status = "Pièces insuffisantes."
        else:
            coins -= int(SPECIES[selected_species]["cost"])
            animals[key] = selected_species
            status = "%s accueilli !" % SPECIES[selected_species]["name"]
    elif tool == "build":
        if tiles.has(key):
            status = "Case déjà occupée."
        elif coins < BUILDINGS[choice]:
            status = "Pièces insuffisantes."
        else:
            coins -= BUILDINGS[choice]
            tiles[key] = choice
            status = "%s construit !" % NAMES[choice]
    save_game()
    update_ui()
    queue_redraw()

func save_game() -> void:
    var parcel_data: Array = []
    for p in parcels:
        parcel_data.append([p.x, p.y])
    var payload := {"coins": coins, "tiles": tiles, "animals": animals, "parcels": parcel_data, "saved_at": int(Time.get_unix_time_from_system())}
    var f := FileAccess.open(SAVE, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(payload))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE):
        return
    var f := FileAccess.open(SAVE, FileAccess.READ)
    if f == null:
        return
    var data = JSON.parse_string(f.get_as_text())
    if not (data is Dictionary):
        return
    coins = int(data.get("coins", data.get("money", 2500)))
    tiles = data.get("tiles", data.get("placed", {}))
    animals = data.get("animals", {})
    var saved_parcels: Array = data.get("parcels", [])
    if saved_parcels.is_empty():
        saved_parcels = data.get("owned", [])
    if not saved_parcels.is_empty():
        parcels.clear()
        for item in saved_parcels:
            if item is Array and item.size() >= 2:
                parcels.append(Vector2i(int(item[0]), int(item[1])))
    if parcels.is_empty():
        parcels.append(Vector2i.ZERO)
    var seconds := maxi(0, int(Time.get_unix_time_from_system()) - int(data.get("saved_at", 0)))
    var ticks := mini(8640, seconds / 10)
    var gain := ticks * (animals.size() * 2 + count_type("shop") * 3)
    if gain > 0:
        coins += gain
        status = "+%d pièces gagnées hors ligne !" % gain
        save_game()
