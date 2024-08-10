extends Node

## The Global autoload of Pixelorama.
##
## This Autoload contains signals, enums, constants, variables and
## references to many UI elements used within Pixelorama.

signal pixelorama_opened  ## Emitted as soon as Pixelorama fully opens up.
signal pixelorama_about_to_close  ## Emitted just before Pixelorama is about to close.
signal project_created(project: Project)  ## Emitted when a new project class is initialized.
signal project_about_to_switch  ## Emitted before a project is about to be switched
signal project_switched  ## Emitted whenever you switch to some other project tab.
signal cel_switched  ## Emitted whenever you select a different cel.
signal project_data_changed(project: Project)  ## Emitted when project data is modified.

enum LayerTypes { PIXEL, GROUP, THREE_D }
enum GridTypes { CARTESIAN, ISOMETRIC, ALL }
## ## Used to tell whether a color is being taken from the current theme,
## or if it is a custom color.
enum ColorFrom { THEME, CUSTOM }
enum ButtonSize { SMALL, BIG }
enum MeasurementMode { NONE, MOVE }

## Enumeration of items present in the File Menu.
enum FileMenu { NEW, OPEN, OPEN_LAST_PROJECT, RECENT, SAVE, SAVE_AS, EXPORT, EXPORT_AS, QUIT }
## Enumeration of items present in the Edit Menu.
enum EditMenu { UNDO, REDO, COPY, CUT, PASTE, PASTE_IN_PLACE, DELETE, NEW_BRUSH, PREFERENCES }
## Enumeration of items present in the View Menu.
enum ViewMenu {
	TILE_MODE,
	TILE_MODE_OFFSETS,
	GREYSCALE_VIEW,
	MIRROR_VIEW,
	SHOW_GRID,
	SHOW_PIXEL_GRID,
	SHOW_RULERS,
	SHOW_GUIDES,
	SHOW_MOUSE_GUIDES,
	DISPLAY_LAYER_EFFECTS,
	SNAP_TO,
}
## Enumeration of items present in the Window Menu.
enum WindowMenu { WINDOW_OPACITY, PANELS, LAYOUTS, MOVABLE_PANELS, ZEN_MODE, FULLSCREEN_MODE }
## Enumeration of items present in the Image Menu.
enum ImageMenu {
	PROJECT_PROPERTIES,
	RESIZE_CANVAS,
	SCALE_IMAGE,
	CROP_TO_SELECTION,
	CROP_TO_CONTENT,
}
## Enumeration of items present in the Effects menu.
enum EffectsMenu {
	OFFSET_IMAGE,
	FLIP,
	ROTATE,
	OUTLINE,
	DROP_SHADOW,
	INVERT_COLORS,
	DESATURATION,
	HSV,
	BRIGHTNESS_SATURATION,
	PALETTIZE,
	PIXELIZE,
	POSTERIZE,
	GRADIENT,
	GRADIENT_MAP,
	SHADER
}
## Enumeration of items present in the Select Menu.
enum SelectMenu { SELECT_ALL, CLEAR_SELECTION, INVERT, TILE_MODE }
## Enumeration of items present in the Help Menu.
enum HelpMenu {
	VIEW_SPLASH_SCREEN,
	ONLINE_DOCS,
	ISSUE_TRACKER,
	OPEN_EDITOR_DATA_FOLDER,
	CHANGELOG,
	ABOUT_PIXELORAMA,
	SUPPORT_PIXELORAMA
}

const LANGUAGES_DICT := {
	"en_US": ["English", "English"],
	"cs_CZ": ["Czech", "Czech"],
	"da_DK": ["Dansk", "Danish"],
	"de_DE": ["Deutsch", "German"],
	"el_GR": ["Ελληνικά", "Greek"],
	"eo_UY": ["Esperanto", "Esperanto"],
	"es_ES": ["Español", "Spanish"],
	"fr_FR": ["Français", "French"],
	"id_ID": ["Indonesian", "Indonesian"],
	"it_IT": ["Italiano", "Italian"],
	"lv_LV": ["Latvian", "Latvian"],
	"pl_PL": ["Polski", "Polish"],
	"pt_BR": ["Português Brasileiro", "Brazilian Portuguese"],
	"pt_PT": ["Português", "Portuguese"],
	"ru_RU": ["Русский", "Russian"],
	"zh_CN": ["简体中文", "Chinese Simplified"],
	"zh_TW": ["繁體中文", "Chinese Traditional"],
	"nb_NO": ["Norsk Bokmål", "Norwegian Bokmål"],
	"hu_HU": ["Magyar", "Hungarian"],
	"ro_RO": ["Română", "Romanian"],
	"ko_KR": ["한국어", "Korean"],
	"tr_TR": ["Türkçe", "Turkish"],
	"ja_JP": ["日本語", "Japanese"],
	"uk_UA": ["Українська", "Ukrainian"],
}

## The file path used for the [member config_cache] file.
const CONFIG_PATH := "user://config.ini"
## The file used to save preferences that use [method _save_to_override_file].
const OVERRIDE_FILE := "override.cfg"
## The name of folder containing Pixelorama preferences.
const HOME_SUBDIR_NAME := "pixelorama"
## The name of folder that contains subdirectories for users to place brushes, palettes, patterns.
const CONFIG_SUBDIR_NAME := "pixelorama_data"
## The path of the directory where the UI layouts are being stored.
const LAYOUT_DIR := "user://layouts"
const VALUE_SLIDER_V2_TSCN := preload("res://src/UI/Nodes/ValueSliderV2.tscn")
const GRADIENT_EDIT_TSCN := preload("res://src/UI/Nodes/GradientEdit.tscn")

## It is path to the executable's base drectory.
var root_directory := "."
## The path where preferences and other subdirectories for stuff like layouts, extensions, logs etc.
## will get stored by Pixelorama.
var home_data_directory := OS.get_data_dir().path_join(HOME_SUBDIR_NAME)
## Only read from these directories. This is an [Array] of directories potentially containing
## stuff such as Brushes, Palettes and Patterns in sub-directories.[br]
## ([member home_data_directory] and [member root_directory] are also included in this array).
var data_directories: PackedStringArray = [home_data_directory]
## The config file used to get/set preferences, tool settings etc.
var config_cache := ConfigFile.new()
var loaded_locales: PackedStringArray = LANGUAGES_DICT.keys()

var projects: Array[Project] = []  ## Array of currently open projects.
var current_project: Project  ## The project that currently in focus.
## The index of project that is currently in focus.
var current_project_index := 0:
	set(value):
		if value >= projects.size():
			return
		canvas.selection.transform_content_confirm()
		current_project_index = value
		project_about_to_switch.emit()
		current_project = projects[value]
		project_switched.connect(current_project.change_project)
		project_switched.emit()
		project_switched.disconnect(current_project.change_project)
		cel_switched.emit()
var default_layouts: Array[DockableLayout] = [
	preload("res://assets/layouts/Default.tres"),
	preload("res://assets/layouts/Tallscreen.tres"),
]
var layouts: Array[DockableLayout] = []

# Canvas related stuff
## Tells if the user allowed to draw on the canvas. Usually it is temporarily set to
## [code]false[/code] when we are moving some gizmo and don't want the current tool to accidentally
## start drawing.[br](This does not depend on layer invisibility or lock/unlock status).
var can_draw := true
## (Intended to be used as getter only) Tells if the user allowed to move the guide while on canvas.
var move_guides_on_canvas := true

var play_only_tags := true  ## If [code]true[/code], animation plays only on frames of the same tag.
## (Intended to be used as getter only) Tells if the x-symmetry guide ( -- ) is visible.
var show_x_symmetry_axis := false
## (Intended to be used as getter only) Tells if the y-symmetry guide ( | ) is visible.
var show_y_symmetry_axis := false

# Preferences
## Found in Preferences. If [code]true[/code], the last saved project will open on startup.
var open_last_project := false
## Found in Preferences. If [code]true[/code], asks for permission to quit on exit.
var quit_confirmation := false
## Found in Preferences. Refers to the ffmpeg location path.
var ffmpeg_path := ""
## Found in Preferences. If [code]true[/code], the zoom is smooth.
var smooth_zoom := true
## Found in Preferences. If [code]true[/code], the zoom is restricted to integral multiples of 100%.
var integer_zoom := false:
	set(value):
		if value == integer_zoom:
			return
		integer_zoom = value
		var zoom_slider: ValueSlider = top_menu_container.get_node("%ZoomSlider")
		if value:
			zoom_slider.min_value = 100
			zoom_slider.snap_step = 100
			zoom_slider.step = 100
		else:
			zoom_slider.min_value = 1
			zoom_slider.snap_step = 1
			zoom_slider.step = 1
		zoom_slider.value = zoom_slider.value  # to trigger signal emission

## Found in Preferences. The scale of the interface.
var shrink := 1.0
## Found in Preferences. The font size used by the interface.
var font_size := 16
## Found in Preferences. If [code]true[/code], the interface dims on popups.
var dim_on_popup := true
## Found in Preferences. If [code]true[/code], the native file dialogs of the
## operating system are being used, instead of Godot's FileDialog node.
var use_native_file_dialogs := false:
	set(value):
		if value == use_native_file_dialogs:
			return
		use_native_file_dialogs = value
		if not is_inside_tree():
			await tree_entered
			await get_tree().process_frame
		get_tree().set_group(&"FileDialogs", "use_native_dialog", value)
## Found in Preferences. If [code]true[/code], subwindows are embedded in the main window.
var single_window_mode := true:
	set(value):
		if value == single_window_mode:
			return
		single_window_mode = value
		_save_to_override_file()
## Found in Preferences. The modulation color (or simply color) of icons.
var modulate_icon_color := Color.GRAY
## Found in Preferences. Determines if [member modulate_icon_color] uses custom or theme color.
var icon_color_from := ColorFrom.THEME:
	set(value):
		if value == icon_color_from:
			return
		icon_color_from = value
		if icon_color_from == ColorFrom.THEME:
			var current_theme := Themes.themes[Themes.theme_index]
			modulate_icon_color = current_theme.get_color("modulate_color", "Icons")
		else:
			modulate_icon_color = custom_icon_color
		Themes.change_icon_colors()
## Found in Preferences. Color of icons when [member icon_color_from] is set to use custom colors.
var custom_icon_color := Color.GRAY:
	set(value):
		if value == custom_icon_color:
			return
		custom_icon_color = value
		if icon_color_from == ColorFrom.CUSTOM:
			modulate_icon_color = custom_icon_color
			Themes.change_icon_colors()
## Found in Preferences. The modulation color (or simply color) of canvas background
## (aside from checker background).
var modulate_clear_color := Color.GRAY:
	set(value):
		if value == modulate_clear_color:
			return
		modulate_clear_color = value
		Themes.change_clear_color()
## Found in Preferences. Determines if [member modulate_clear_color] uses custom or theme color.
var clear_color_from := ColorFrom.THEME:
	set(value):
		if value == clear_color_from:
			return
		clear_color_from = value
		Themes.change_clear_color()
## Found in Preferences. The selected size mode of tool buttons using [enum ButtonSize] enum.
var tool_button_size := ButtonSize.SMALL:
	set(value):
		if value == tool_button_size:
			return
		tool_button_size = value
		Tools.set_button_size(tool_button_size)
## Found in Preferences. The left tool color.
var left_tool_color := Color("0086cf"):
	set(value):
		if value == left_tool_color:
			return
		left_tool_color = value
		if not is_instance_valid(Tools._tool_buttons):
			await get_tree().process_frame
		for child in Tools._tool_buttons.get_children():
			var background: NinePatchRect = child.get_node("BackgroundLeft")
			background.modulate = value
		Tools._slots[MOUSE_BUTTON_LEFT].tool_node.color_rect.color = value
## Found in Preferences. The right tool color.
var right_tool_color := Color("fd6d14"):
	set(value):
		if value == right_tool_color:
			return
		right_tool_color = value
		if not is_instance_valid(Tools._tool_buttons):
			await get_tree().process_frame
		for child in Tools._tool_buttons.get_children():
			var background: NinePatchRect = child.get_node("BackgroundRight")
			background.modulate = value
		Tools._slots[MOUSE_BUTTON_RIGHT].tool_node.color_rect.color = value

var default_width := 64  ## Found in Preferences. The default width of startup project.
var default_height := 64  ## Found in Preferences. The default height of startup project.
## Found in Preferences. The fill color of startup project.
var default_fill_color := Color(0, 0, 0, 0)
## Found in Preferences. The distance to the guide or grig below which cursor snapping activates.
var snapping_distance := 32.0
## Found in Preferences. The grid type defined by [enum GridTypes] enum.
var grid_type := GridTypes.CARTESIAN:
	set(value):
		if value == grid_type:
			return
		grid_type = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. The size of rectangular grid.
var grid_size := Vector2i(2, 2):
	set(value):
		if value == grid_size:
			return
		grid_size = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. The size of isometric grid.
var isometric_grid_size := Vector2i(16, 8):
	set(value):
		if value == isometric_grid_size:
			return
		isometric_grid_size = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. The grid offset from top-left corner of the canvas.
var grid_offset := Vector2i.ZERO:
	set(value):
		if value == grid_offset:
			return
		grid_offset = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. If [code]true[/code], The grid draws over the area extended by
## tile-mode as well.
var grid_draw_over_tile_mode := false:
	set(value):
		if value == grid_draw_over_tile_mode:
			return
		grid_draw_over_tile_mode = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. The color of grid.
var grid_color := Color.BLACK:
	set(value):
		if value == grid_color:
			return
		grid_color = value
		if is_instance_valid(canvas.grid):
			canvas.grid.queue_redraw()
## Found in Preferences. The minimum zoom after which pixel grid gets drawn if enabled.
var pixel_grid_show_at_zoom := 1500.0:  # percentage
	set(value):
		if value == pixel_grid_show_at_zoom:
			return
		pixel_grid_show_at_zoom = value
		if is_instance_valid(canvas.pixel_grid):
			canvas.pixel_grid.queue_redraw()
## Found in Preferences. The color of pixel grid.
var pixel_grid_color := Color("21212191"):
	set(value):
		if value == pixel_grid_color:
			return
		pixel_grid_color = value
		if is_instance_valid(canvas.pixel_grid):
			canvas.pixel_grid.queue_redraw()
## Found in Preferences. The color of guides.
var guide_color := Color.PURPLE:
	set(value):
		if value == guide_color:
			return
		guide_color = value
		for guide in canvas.get_children():
			if guide is Guide:
				guide.set_color(guide_color)
## Found in Preferences. The size of checkers in the checker background.
var checker_size := 10:
	set(value):
		if value == checker_size:
			return
		checker_size = value
		transparent_checker.update_rect()
## Found in Preferences. The color of first checker.
var checker_color_1 := Color(0.47, 0.47, 0.47, 1):
	set(value):
		if value == checker_color_1:
			return
		checker_color_1 = value
		transparent_checker.update_rect()
## Found in Preferences. The color of second checker.
var checker_color_2 := Color(0.34, 0.35, 0.34, 1):
	set(value):
		if value == checker_color_2:
			return
		checker_color_2 = value
		transparent_checker.update_rect()
## Found in Preferences. The color of second checker.
var checker_follow_movement := false:
	set(value):
		if value == checker_follow_movement:
			return
		checker_follow_movement = value
		transparent_checker.update_rect()
## Found in Preferences. If [code]true[/code], the checker follows zoom.
var checker_follow_scale := false:
	set(value):
		if value == checker_follow_scale:
			return
		checker_follow_scale = value
		transparent_checker.update_rect()
## Found in Preferences. Opacity of the sprites rendered on the extended area of tile-mode.
var tilemode_opacity := 1.0:
	set(value):
		if value == tilemode_opacity:
			return
		tilemode_opacity = value
		if is_instance_valid(canvas.tile_mode):
			canvas.tile_mode.queue_redraw()

## Found in Preferences. If [code]true[/code], layers get selected when their buttons are pressed.
var select_layer_on_button_click := false
## Found in Preferences. The onion color of past frames.
var onion_skinning_past_color := Color.RED:
	set(value):
		if value == onion_skinning_past_color:
			return
		onion_skinning_past_color = value
		if is_instance_valid(canvas.onion_past):
			canvas.onion_past.blue_red_color = value
			canvas.onion_past.queue_redraw()
## Found in Preferences. The onion color of future frames.
var onion_skinning_future_color := Color.BLUE:
	set(value):
		if value == onion_skinning_future_color:
			return
		onion_skinning_future_color = value
		if is_instance_valid(canvas.onion_future):
			canvas.onion_future.blue_red_color = value
			canvas.onion_future.queue_redraw()

## Found in Preferences. If [code]true[/code], the selection rect has animated borders.
var selection_animated_borders := true:
	set(value):
		if value == selection_animated_borders:
			return
		selection_animated_borders = value
		if is_instance_valid(canvas.selection):
			var marching_ants: Sprite2D = canvas.selection.marching_ants_outline
			marching_ants.material.set_shader_parameter("animated", selection_animated_borders)
## Found in Preferences. The first color of border.
var selection_border_color_1 := Color.WHITE:
	set(value):
		if value == selection_border_color_1:
			return
		selection_border_color_1 = value
		if is_instance_valid(canvas.selection):
			var marching_ants: Sprite2D = canvas.selection.marching_ants_outline
			marching_ants.material.set_shader_parameter("first_color", selection_border_color_1)
			canvas.selection.queue_redraw()
## Found in Preferences. The second color of border.
var selection_border_color_2 := Color.BLACK:
	set(value):
		if value == selection_border_color_2:
			return
		selection_border_color_2 = value
		if is_instance_valid(canvas.selection):
			var marching_ants: Sprite2D = canvas.selection.marching_ants_outline
			marching_ants.material.set_shader_parameter("second_color", selection_border_color_2)
			canvas.selection.queue_redraw()

## Found in Preferences. If [code]true[/code], Pixelorama pauses when unfocused to save cpu usage.
var pause_when_unfocused := true
## Found in Preferences. The max fps, Pixelorama is allowed to use (does not limit fps if it is 0).
var fps_limit := 0:
	set(value):
		if value == fps_limit:
			return
		fps_limit = value
		Engine.max_fps = fps_limit
## Found in Preferences. Affects the per_pixel_transparency project setting.
## If [code]true[/code], it allows for the window to be transparent.
## This affects performance, so keep it [code]false[/code] if you don't need it.
var update_continuously := false:
	set(value):
		update_continuously = value
		OS.low_processor_usage_mode = !value
var window_transparency := false:
	set(value):
		if value == window_transparency:
			return
		window_transparency = value
		_save_to_override_file()

## Found in Preferences. The time (in minutes) after which backup is created (if enabled).
var autosave_interval := 1.0:
	set(value):
		if value == autosave_interval:
			return
		autosave_interval = value
		OpenSave.update_autosave()
## Found in Preferences. If [code]true[/code], generation of backups get enabled.
var enable_autosave := true:
	set(value):
		if value == enable_autosave:
			return
		enable_autosave = value
		OpenSave.update_autosave()
## Found in Preferences. The index of tablet driver used by Pixelorama.
var tablet_driver := 0:
	set(value):
		if value == tablet_driver:
			return
		tablet_driver = value
		var tablet_driver_name := DisplayServer.tablet_get_driver_name(tablet_driver)
		DisplayServer.tablet_set_current_driver(tablet_driver_name)

# Tools & options
## Found in Preferences. If [code]true[/code], the cursor's left tool icon is visible.
var show_left_tool_icon := true
## Found in Preferences. If [code]true[/code], the cursor's right tool icon is visible.
var show_right_tool_icon := true
## Found in Preferences. If [code]true[/code], the left tool's brush indicator is visible.
var left_square_indicator_visible := true
## Found in Preferences. If [code]true[/code], the right tool's brush indicator is visible.
var right_square_indicator_visible := true
## Found in Preferences. If [code]true[/code], native cursors are used instead of default cursors.
var native_cursors := false:
	set(value):
		if value == native_cursors:
			return
		if DisplayServer.get_name() == "headless":
			return
		native_cursors = value
		if native_cursors:
			Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS, Vector2(15, 15))
		else:
			control.set_custom_cursor()
## Found in Preferences. If [code]true[/code], cursor becomes cross shaped when hovering the canvas.
var cross_cursor := true

# View menu options
## If [code]true[/code], the canvas is in greyscale.
var greyscale_view := false
## If [code]true[/code], the content of canvas is flipped.
var mirror_view := false
## If [code]true[/code], the grid is visible.
var draw_grid := false
## If [code]true[/code], the pixel grid is visible.
var draw_pixel_grid := false
## If [code]true[/code], the rulers are visible.
var show_rulers := true
## If [code]true[/code], the guides are visible.
var show_guides := true
## If [code]true[/code], the mouse guides are visible.
var show_mouse_guides := false
var display_layer_effects := true:
	set(value):
		if value == display_layer_effects:
			return
		display_layer_effects = value
		if is_instance_valid(top_menu_container):
			top_menu_container.view_menu.set_item_checked(ViewMenu.DISPLAY_LAYER_EFFECTS, value)
			canvas.queue_redraw()
## If [code]true[/code], cursor snaps to the boundary of rectangular grid boxes.
var snap_to_rectangular_grid_boundary := false
## If [code]true[/code], cursor snaps to the center of rectangular grid boxes.
var snap_to_rectangular_grid_center := false
## If [code]true[/code], cursor snaps to regular guides.
var snap_to_guides := false
## If [code]true[/code], cursor snaps to perspective guides.
var snap_to_perspective_guides := false

# Onion skinning options
var onion_skinning := false  ## If [code]true[/code], onion skinning is enabled.
var onion_skinning_past_rate := 1  ## Number of past frames shown when onion skinning is enabled.
## Number of future frames shown when onion skinning is enabled.
var onion_skinning_future_rate := 1
var onion_skinning_blue_red := false  ## If [code]true[/code], then blue-red mode is enabled.

## The current version of pixelorama
var current_version: String = ProjectSettings.get_setting("application/config/version")

# Nodes
## The [PackedScene] of the button used by layers in the timeline.
var layer_button_node := preload("res://src/UI/Timeline/LayerButton.tscn")
## The [PackedScene] of the button used by cels in the timeline.
var cel_button_scene: PackedScene = load("res://src/UI/Timeline/CelButton.tscn")

## The control node (aka Main node). It has the [param Main.gd] script attached.
@onready var control := get_tree().current_scene as Control

## The project tabs bar. It has the [param Tabs.gd] script attached.
@onready var tabs: TabBar = control.find_child("TabBar")
## Contains viewport of the main canvas. It has the [param ViewportContainer.gd] script attached.
@onready var main_viewport: SubViewportContainer = control.find_child("SubViewportContainer")
## The main canvas node. It has the [param Canvas.gd] script attached.
@onready var canvas: Canvas = main_viewport.find_child("Canvas")
## Contains viewport of the second canvas preview.
## It has the [param ViewportContainer.gd] script attached.
@onready var second_viewport: SubViewportContainer = control.find_child("Second Canvas")
## The panel container of the canvas preview.
## It has the [param CanvasPreviewContainer.gd] script attached.
@onready var canvas_preview_container: Container = control.find_child("Canvas Preview")
## The global tool options. It has the [param GlobalToolOptions.gd] script attached.
@onready var global_tool_options: PanelContainer = control.find_child("Global Tool Options")
## Contains viewport of the canvas preview.
@onready var small_preview_viewport: SubViewportContainer = canvas_preview_container.find_child(
	"PreviewViewportContainer"
)
## Camera of the main canvas.
@onready var camera: CanvasCamera = main_viewport.find_child("Camera2D")
## Camera of the second canvas preview.
@onready var camera2: CanvasCamera = second_viewport.find_child("Camera2D2")
## Camera of the canvas preview.
@onready var camera_preview: CanvasCamera = control.find_child("CameraPreview")
## Array of cameras used in Pixelorama.
@onready var cameras := [camera, camera2, camera_preview]
## Horizontal ruler of the main canvas. It has the [param HorizontalRuler.gd] script attached.
@onready var horizontal_ruler: BaseButton = control.find_child("HorizontalRuler")
## Vertical ruler of the main canvas. It has the [param VerticalRuler.gd] script attached.
@onready var vertical_ruler: BaseButton = control.find_child("VerticalRuler")
## Transparent checker of the main canvas. It has the [param TransparentChecker.gd] script attached.
@onready var transparent_checker: ColorRect = control.find_child("TransparentChecker")

## The perspective editor. It has the [param PerspectiveEditor.gd] script attached.
@onready var perspective_editor := control.find_child("Perspective Editor")
## The top menu container. It has the [param TopMenuContainer.gd] script attached.
@onready var top_menu_container: Panel = control.find_child("TopMenuContainer")
## The label indicating cursor position.
@onready var cursor_position_label: Label = top_menu_container.find_child("CursorPosition")
## The animation timeline. It has the [param AnimationTimeline.gd] script attached.
@onready var animation_timeline: Panel = control.find_child("Animation Timeline")
## The timer used by the animation timeline.
@onready var animation_timer: Timer = animation_timeline.find_child("AnimationTimer")
## The container of frame buttons
@onready var frame_hbox: HBoxContainer = animation_timeline.find_child("FrameHBox")
## The container of layer buttons
@onready var layer_vbox: VBoxContainer = animation_timeline.find_child("LayerVBox")
## At runtime HBoxContainers containing cel buttons get added to it.
@onready var cel_vbox: VBoxContainer = animation_timeline.find_child("CelVBox")
## The container of animation tags.
@onready var tag_container: Control = animation_timeline.find_child("TagContainer")

## The brushes popup dialog used to display brushes.
## It has the [param BrushesPopup.gd] script attached.
@onready var brushes_popup: Popup = control.find_child("BrushesPopup")
## The patterns popup dialog used to display patterns
## It has the [param PatternsPopup.gd] script attached.
@onready var patterns_popup: Popup = control.find_child("PatternsPopup")
## Dialog used to navigate and open images and projects.
@onready var open_sprites_dialog: FileDialog = control.find_child("OpenSprite")
## Dialog used to save (.pxo) projects.
@onready var save_sprites_dialog: FileDialog = control.find_child("SaveSprite")
## Dialog used to export images. It has the [param ExportDialog.gd] script attached.
@onready var export_dialog: AcceptDialog = control.find_child("ExportDialog")
## An error dialog to show errors.
@onready var error_dialog: AcceptDialog = control.find_child("ErrorDialog")


func _init() -> void:
	# Load settings from the config file
	config_cache.load(CONFIG_PATH)
	loaded_locales.sort()  # Make sure locales are always sorted
	var saved_locale := OS.get_locale()
	# Load language
	if config_cache.has_section_key("preferences", "locale"):
		saved_locale = config_cache.get_value("preferences", "locale")
	set_locale(saved_locale, false)  # If no language is saved, OS' locale is used
	if OS.has_feature("template"):
		root_directory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "macOS":
		data_directories.append(
			root_directory.path_join("../Resources").path_join(CONFIG_SUBDIR_NAME)
		)
	data_directories.append(root_directory.path_join(CONFIG_SUBDIR_NAME))
	if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
		# Checks the list of files var, and processes them.
		if OS.has_environment("XDG_DATA_DIRS"):
			var raw_env_var := OS.get_environment("XDG_DATA_DIRS")  # includes empties.
			var unappended_subdirs := raw_env_var.split(":", true)
			for unapp_subdir in unappended_subdirs:
				data_directories.append(unapp_subdir.path_join(HOME_SUBDIR_NAME))
		else:
			# Create defaults
			for default_loc in ["/usr/local/share", "/usr/share"]:
				data_directories.append(default_loc.path_join(HOME_SUBDIR_NAME))
	if ProjectSettings.get_setting("display/window/tablet_driver") == "winink":
		tablet_driver = 1
	single_window_mode = ProjectSettings.get_setting("display/window/subwindows/embed_subwindows")
	window_transparency = ProjectSettings.get_setting(
		"display/window/per_pixel_transparency/allowed"
	)


func _ready() -> void:
	_initialize_keychain()
	default_width = config_cache.get_value("preferences", "default_width", default_width)
	default_height = config_cache.get_value("preferences", "default_height", default_height)
	default_fill_color = config_cache.get_value(
		"preferences", "default_fill_color", default_fill_color
	)
	var proj_size := Vector2i(default_width, default_height)
	projects.append(Project.new([], tr("untitled"), proj_size))
	current_project = projects[0]
	current_project.fill_color = default_fill_color

	# Load preferences from the config file
	for pref in config_cache.get_section_keys("preferences"):
		if get(pref) == null:
			continue
		var value = config_cache.get_value("preferences", pref)
		set(pref, value)
	if OS.is_sandboxed():
		Global.use_native_file_dialogs = true
	await get_tree().process_frame
	project_switched.emit()


func _initialize_keychain() -> void:
	Keychain.config_file = config_cache
	Keychain.actions = {
		&"new_file": Keychain.InputAction.new("", "File menu", true),
		&"open_file": Keychain.InputAction.new("", "File menu", true),
		&"open_last_project": Keychain.InputAction.new("", "File menu", true),
		&"save_file": Keychain.InputAction.new("", "File menu", true),
		&"save_file_as": Keychain.InputAction.new("", "File menu", true),
		&"export_file": Keychain.InputAction.new("", "File menu", true),
		&"export_file_as": Keychain.InputAction.new("", "File menu", true),
		&"quit": Keychain.InputAction.new("", "File menu", true),
		&"redo": Keychain.InputAction.new("", "Edit menu", true),
		&"undo": Keychain.InputAction.new("", "Edit menu", true),
		&"cut": Keychain.InputAction.new("", "Edit menu", true),
		&"copy": Keychain.InputAction.new("", "Edit menu", true),
		&"paste": Keychain.InputAction.new("", "Edit menu", true),
		&"paste_in_place": Keychain.InputAction.new("", "Edit menu", true),
		&"delete": Keychain.InputAction.new("", "Edit menu", true),
		&"new_brush": Keychain.InputAction.new("", "Edit menu", true),
		&"preferences": Keychain.InputAction.new("", "Edit menu", true),
		&"project_properties": Keychain.InputAction.new("", "Image menu", true),
		&"scale_image": Keychain.InputAction.new("", "Image menu", true),
		&"crop_to_selection": Keychain.InputAction.new("", "Image menu", true),
		&"crop_to_content": Keychain.InputAction.new("", "Image menu", true),
		&"resize_canvas": Keychain.InputAction.new("", "Image menu", true),
		&"offset_image": Keychain.InputAction.new("", "Effects menu", true),
		&"mirror_image": Keychain.InputAction.new("", "Effects menu", true),
		&"rotate_image": Keychain.InputAction.new("", "Effects menu", true),
		&"invert_colors": Keychain.InputAction.new("", "Effects menu", true),
		&"desaturation": Keychain.InputAction.new("", "Effects menu", true),
		&"outline": Keychain.InputAction.new("", "Effects menu", true),
		&"drop_shadow": Keychain.InputAction.new("", "Effects menu", true),
		&"adjust_hsv": Keychain.InputAction.new("", "Effects menu", true),
		&"adjust_brightness_contrast": Keychain.InputAction.new("", "Effects menu", true),
		&"gradient": Keychain.InputAction.new("", "Effects menu", true),
		&"gradient_map": Keychain.InputAction.new("", "Effects menu", true),
		&"palettize": Keychain.InputAction.new("", "Effects menu", true),
		&"pixelize": Keychain.InputAction.new("", "Effects menu", true),
		&"posterize": Keychain.InputAction.new("", "Effects menu", true),
		&"mirror_view": Keychain.InputAction.new("", "View menu", true),
		&"show_grid": Keychain.InputAction.new("", "View menu", true),
		&"show_pixel_grid": Keychain.InputAction.new("", "View menu", true),
		&"show_guides": Keychain.InputAction.new("", "View menu", true),
		&"show_rulers": Keychain.InputAction.new("", "View menu", true),
		&"display_layer_effects": Keychain.InputAction.new("", "View menu", true),
		&"moveable_panels": Keychain.InputAction.new("", "Window menu", true),
		&"zen_mode": Keychain.InputAction.new("", "Window menu", true),
		&"toggle_fullscreen": Keychain.InputAction.new("", "Window menu", true),
		&"clear_selection": Keychain.InputAction.new("", "Select menu", true),
		&"select_all": Keychain.InputAction.new("", "Select menu", true),
		&"invert_selection": Keychain.InputAction.new("", "Select menu", true),
		&"view_splash_screen": Keychain.InputAction.new("", "Help menu", true),
		&"open_docs": Keychain.InputAction.new("", "Help menu", true),
		&"issue_tracker": Keychain.InputAction.new("", "Help menu", true),
		&"open_logs_folder": Keychain.InputAction.new("", "Help menu", true),
		&"changelog": Keychain.InputAction.new("", "Help menu", true),
		&"about_pixelorama": Keychain.InputAction.new("", "Help menu", true),
		&"zoom_in": Keychain.InputAction.new("", "Canvas"),
		&"zoom_out": Keychain.InputAction.new("", "Canvas"),
		&"camera_left": Keychain.InputAction.new("", "Canvas"),
		&"camera_right": Keychain.InputAction.new("", "Canvas"),
		&"camera_up": Keychain.InputAction.new("", "Canvas"),
		&"camera_down": Keychain.InputAction.new("", "Canvas"),
		&"pan": Keychain.InputAction.new("", "Canvas"),
		&"activate_left_tool": Keychain.InputAction.new("", "Canvas"),
		&"activate_right_tool": Keychain.InputAction.new("", "Canvas"),
		&"move_mouse_left": Keychain.InputAction.new("", "Cursor movement"),
		&"move_mouse_right": Keychain.InputAction.new("", "Cursor movement"),
		&"move_mouse_up": Keychain.InputAction.new("", "Cursor movement"),
		&"move_mouse_down": Keychain.InputAction.new("", "Cursor movement"),
		&"reset_colors_default": Keychain.InputAction.new("", "Buttons"),
		&"switch_colors": Keychain.InputAction.new("", "Buttons"),
		&"horizontal_mirror": Keychain.InputAction.new("", "Buttons"),
		&"vertical_mirror": Keychain.InputAction.new("", "Buttons"),
		&"pixel_perfect": Keychain.InputAction.new("", "Buttons"),
		&"alpha_lock": Keychain.InputAction.new("", "Buttons"),
		&"new_layer": Keychain.InputAction.new("", "Buttons"),
		&"remove_layer": Keychain.InputAction.new("", "Buttons"),
		&"move_layer_up": Keychain.InputAction.new("", "Buttons"),
		&"move_layer_down": Keychain.InputAction.new("", "Buttons"),
		&"clone_layer": Keychain.InputAction.new("", "Buttons"),
		&"merge_down_layer": Keychain.InputAction.new("", "Buttons"),
		&"add_frame": Keychain.InputAction.new("", "Buttons"),
		&"remove_frame": Keychain.InputAction.new("", "Buttons"),
		&"clone_frame": Keychain.InputAction.new("", "Buttons"),
		&"move_frame_left": Keychain.InputAction.new("", "Buttons"),
		&"move_frame_right": Keychain.InputAction.new("", "Buttons"),
		&"go_to_first_frame": Keychain.InputAction.new("", "Buttons"),
		&"go_to_last_frame": Keychain.InputAction.new("", "Buttons"),
		&"go_to_previous_frame": Keychain.InputAction.new("", "Buttons"),
		&"go_to_next_frame": Keychain.InputAction.new("", "Buttons"),
		&"go_to_previous_layer": Keychain.InputAction.new("", "Buttons"),
		&"go_to_next_layer": Keychain.InputAction.new("", "Buttons"),
		&"play_backwards": Keychain.InputAction.new("", "Buttons"),
		&"play_forward": Keychain.InputAction.new("", "Buttons"),
		&"onion_skinning_toggle": Keychain.InputAction.new("", "Buttons"),
		&"loop_toggle": Keychain.InputAction.new("", "Buttons"),
		&"onion_skinning_settings": Keychain.InputAction.new("", "Buttons"),
		&"new_palette": Keychain.InputAction.new("", "Buttons"),
		&"edit_palette": Keychain.InputAction.new("", "Buttons"),
		&"brush_size_increment": Keychain.InputAction.new("", "Buttons"),
		&"brush_size_decrement": Keychain.InputAction.new("", "Buttons"),
		&"change_tool_mode": Keychain.InputAction.new("", "Tool modifiers", false),
		&"draw_create_line": Keychain.InputAction.new("", "Draw tools", false),
		&"draw_snap_angle": Keychain.InputAction.new("", "Draw tools", false),
		&"draw_color_picker": Keychain.InputAction.new("Quick color picker", "Draw tools", false),
		&"shape_perfect": Keychain.InputAction.new("", "Shape tools", false),
		&"shape_center": Keychain.InputAction.new("", "Shape tools", false),
		&"shape_displace": Keychain.InputAction.new("", "Shape tools", false),
		&"selection_add": Keychain.InputAction.new("", "Selection tools", false),
		&"selection_subtract": Keychain.InputAction.new("", "Selection tools", false),
		&"selection_intersect": Keychain.InputAction.new("", "Selection tools", false),
		&"transformation_confirm": Keychain.InputAction.new("", "Transformation tools", false),
		&"transformation_cancel": Keychain.InputAction.new("", "Transformation tools", false),
		&"transform_snap_axis": Keychain.InputAction.new("", "Transformation tools", false),
		&"transform_snap_grid": Keychain.InputAction.new("", "Transformation tools", false),
		&"transform_move_selection_only":
		Keychain.InputAction.new("", "Transformation tools", false),
		&"transform_copy_selection_content":
		Keychain.InputAction.new("", "Transformation tools", false),
		&"reference_rotate": Keychain.InputAction.new("", "Reference images", false),
		&"reference_scale": Keychain.InputAction.new("", "Reference images", false),
		&"reference_quick_menu": Keychain.InputAction.new("", "Reference images", false),
		&"cancel_reference_transform": Keychain.InputAction.new("", "Reference images", false)
	}

	Keychain.groups = {
		"Canvas": Keychain.InputGroup.new("", false),
		"Cursor movement": Keychain.InputGroup.new("Canvas"),
		"Buttons": Keychain.InputGroup.new(),
		"Tools": Keychain.InputGroup.new(),
		"Left": Keychain.InputGroup.new("Tools"),
		"Right": Keychain.InputGroup.new("Tools"),
		"Menu": Keychain.InputGroup.new(),
		"File menu": Keychain.InputGroup.new("Menu"),
		"Edit menu": Keychain.InputGroup.new("Menu"),
		"View menu": Keychain.InputGroup.new("Menu"),
		"Select menu": Keychain.InputGroup.new("Menu"),
		"Image menu": Keychain.InputGroup.new("Menu"),
		"Effects menu": Keychain.InputGroup.new("Menu"),
		"Window menu": Keychain.InputGroup.new("Menu"),
		"Help menu": Keychain.InputGroup.new("Menu"),
		"Tool modifiers": Keychain.InputGroup.new(),
		"Draw tools": Keychain.InputGroup.new("Tool modifiers"),
		"Shape tools": Keychain.InputGroup.new("Tool modifiers"),
		"Selection tools": Keychain.InputGroup.new("Tool modifiers"),
		"Transformation tools": Keychain.InputGroup.new("Tool modifiers"),
		"Reference images": Keychain.InputGroup.new("Canvas")
	}
	Keychain.ignore_actions = ["left_mouse", "right_mouse", "middle_mouse", "shift", "ctrl"]


## Generates an animated notification label showing [param text].
func notification_label(text: String) -> void:
	var notif := NotificationLabel.new()
	notif.text = tr(text)
	notif.position = main_viewport.global_position
	notif.position.y += main_viewport.size.y
	control.add_child(notif)


## Performs the general, bare minimum stuff needed after an undo is done.
func general_undo(project := current_project) -> void:
	project.undos -= 1
	var action_name := project.undo_redo.get_current_action_name()
	notification_label("Undo: %s" % action_name)


## Performs the general, bare minimum stuff needed after a redo is done.
func general_redo(project := current_project) -> void:
	if project.undos < project.undo_redo.get_version():  # If we did undo and then redo
		project.undos = project.undo_redo.get_version()
	if control.redone:
		var action_name := project.undo_redo.get_current_action_name()
		notification_label("Redo: %s" % action_name)


## Performs actions done after an undo or redo is done. this takes [member general_undo] and
## [member general_redo] a step further. Does further work if the current action requires it
## like refreshing textures, redraw UI elements etc...[br]
## [param frame_index] and [param layer_index] are there for optimizzation. if the undo or redo
## happens only in one cel then the cel's frame and layer should be passed to [param frame_index]
## and [param layer_index] respectively, otherwise the entire timeline will be refreshed.
func undo_or_redo(
	undo: bool, frame_index := -1, layer_index := -1, project := current_project
) -> void:
	if undo:
		general_undo(project)
	else:
		general_redo(project)
	var action_name := project.undo_redo.get_current_action_name()
	if (
		action_name
		in [
			"Draw",
			"Draw Shape",
			"Select",
			"Move Selection",
			"Scale",
			"Center Frames",
			"Merge Layer",
			"Link Cel",
			"Unlink Cel"
		]
	):
		if layer_index > -1 and frame_index > -1:
			canvas.update_texture(layer_index, frame_index, project)
		else:
			for i in project.frames.size():
				for j in project.layers.size():
					canvas.update_texture(j, i, project)

		canvas.selection.queue_redraw()
		if action_name == "Scale":
			for i in project.frames.size():
				for j in project.layers.size():
					var current_cel := project.frames[i].cels[j]
					if current_cel is Cel3D:
						current_cel.size_changed(project.size)
					else:
						current_cel.image_texture.set_image(current_cel.get_image())
			canvas.camera_zoom()
			canvas.grid.queue_redraw()
			canvas.pixel_grid.queue_redraw()
			project.selection_map_changed()
			cursor_position_label.text = "[%s×%s]" % [project.size.x, project.size.y]

	await RenderingServer.frame_post_draw
	canvas.queue_redraw()
	second_viewport.get_child(0).get_node("CanvasPreview").queue_redraw()
	canvas_preview_container.canvas_preview.queue_redraw()
	if !project.has_changed:
		if project == current_project:
			get_window().title = get_window().title + "(*)"
	project.has_changed = true


## Use this to prepare Pixelorama before opening a dialog.
func dialog_open(open: bool, is_file_dialog := false) -> void:
	if is_file_dialog and use_native_file_dialogs:
		return
	var dim_color := Color.WHITE
	if open:
		if dim_on_popup:
			dim_color = Color(0.5, 0.5, 0.5)

	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", dim_color, 0.1)


func popup_error(text: String) -> void:
	error_dialog.set_text(text)
	error_dialog.popup_centered()
	dialog_open(true)


## sets the [member BaseButton.disabled] property of the [param button] to [param disable],
## changes the cursor shape for it accordingly, and dims/brightens any textures it may have.
func disable_button(button: BaseButton, disable: bool) -> void:
	button.disabled = disable
	if disable:
		button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if button is Button:
		for c in button.get_children():
			if c is TextureRect:
				c.modulate.a = 0.5 if disable else 1.0
				break


## Changes the texture of the [param texture_rect] to another texture of name [param new_file_name]
## present in the same directory as the old one.
func change_button_texturerect(texture_rect: TextureRect, new_file_name: String) -> void:
	if !texture_rect.texture:
		return
	var file_name := texture_rect.texture.resource_path.get_basename().get_file()
	var directory_path := texture_rect.texture.resource_path.get_basename().replace(file_name, "")
	texture_rect.texture = load(directory_path.path_join(new_file_name))


## Joins each [String] path in [param basepaths] with [param subpath] using
## [method String.path_join]
func path_join_array(basepaths: PackedStringArray, subpath: String) -> PackedStringArray:
	var res := PackedStringArray()
	for _path in basepaths:
		res.append(_path.path_join(subpath))
	return res


func set_locale(locale: String, load_keychain := true) -> void:
	locale = find_nearest_locale(locale)
	if not locale in TranslationServer.get_loaded_locales():
		var translation := load("res://Translations/%s.po" % locale)
		if is_instance_valid(translation) and translation is Translation:
			TranslationServer.add_translation(translation)
		else:
			printerr("Translation %s for locale %s failed to load." % [translation, locale])
			return
		if load_keychain:
			Keychain.load_translation(locale)
	TranslationServer.set_locale(locale)


func find_nearest_locale(locale: String) -> String:
	if locale in loaded_locales:
		return locale
	var max_similarity_score := 0
	var closest_locale := "en_US"
	for loaded_locale in loaded_locales:
		var compared := TranslationServer.compare_locales(locale, loaded_locale)
		if compared > max_similarity_score:
			max_similarity_score = compared
			closest_locale = loaded_locale
	return closest_locale


## Used by undo/redo operations to store compressed images in memory.
## [param redo_data] and [param undo_data] are Dictionaries,
## with keys of type [Image] and [Dictionary] values, coming from [member Image.data].
func undo_redo_compress_images(
	redo_data: Dictionary, undo_data: Dictionary, project := current_project
) -> void:
	for image in redo_data:
		if not image is Image:
			continue
		var new_image: Dictionary = redo_data[image]
		var new_size := Vector2i(new_image["width"], new_image["height"])
		var buffer_size: int = new_image["data"].size()
		var compressed_data: PackedByteArray = new_image["data"].compress()
		project.undo_redo.add_do_method(
			undo_redo_draw_op.bind(image, new_size, compressed_data, buffer_size)
		)
	for image in undo_data:
		if not image is Image:
			continue
		var new_image: Dictionary = undo_data[image]
		var new_size := Vector2i(new_image["width"], new_image["height"])
		var buffer_size: int = new_image["data"].size()
		var compressed_data: PackedByteArray = new_image["data"].compress()
		project.undo_redo.add_undo_method(
			undo_redo_draw_op.bind(image, new_size, compressed_data, buffer_size)
		)


## Decompresses the [param compressed_image_data] with [param buffer_size] to the [param image]
## This is a memory optimization method used while performing undo/redo drawing operations.
func undo_redo_draw_op(
	image: Image, new_size: Vector2i, compressed_image_data: PackedByteArray, buffer_size: int
) -> void:
	var decompressed := compressed_image_data.decompress(buffer_size)
	image.set_data(new_size.x, new_size.y, image.has_mipmaps(), image.get_format(), decompressed)


## This method is used to write project setting overrides to the override.cfg file, located
## in the same directory as the executable.
## We use this method instead of [method ProjectSettings.save_custom] because that copies
## the entire project.godot file into override.cfg, which causes issues
## because software updates will not be able to make changes to the project settings for
## users who have already saved an override.cfg file, leading into confusion.
## To avoid this issue, we just write the lines we want to the override.cfg file.
func _save_to_override_file() -> void:
	var file := FileAccess.open(OVERRIDE_FILE, FileAccess.WRITE)
	file.store_line("[display]\n")
	file.store_line("window/subwindows/embed_subwindows=%s" % single_window_mode)
	file.store_line("window/per_pixel_transparency/allowed=%s" % window_transparency)


func create_ui_for_shader_uniforms(
	shader: Shader,
	params: Dictionary,
	parent_node: Control,
	value_changed: Callable,
	file_selected: Callable
) -> void:
	var code := shader.code.split("\n")
	var uniforms: PackedStringArray = []
	for line in code:
		if line.begins_with("uniform"):
			uniforms.append(line)

	for uniform in uniforms:
		# Example uniform:
		# uniform float parameter_name : hint_range(0, 255) = 100.0;
		var uniform_split := uniform.split("=")
		var u_value := ""
		if uniform_split.size() > 1:
			u_value = uniform_split[1].replace(";", "").strip_edges()
		else:
			uniform_split[0] = uniform_split[0].replace(";", "").strip_edges()

		var u_left_side := uniform_split[0].split(":")
		var u_hint := ""
		if u_left_side.size() > 1:
			u_hint = u_left_side[1].strip_edges()
			u_hint = u_hint.replace(";", "")

		var u_init := u_left_side[0].split(" ")
		var u_type := u_init[1]
		var u_name := u_init[2]
		var humanized_u_name := Keychain.humanize_snake_case(u_name) + ":"

		if u_type == "float" or u_type == "int":
			var label := Label.new()
			label.text = humanized_u_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var slider := ValueSlider.new()
			slider.allow_greater = true
			slider.allow_lesser = true
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var min_value := 0.0
			var max_value := 255.0
			var step := 1.0
			var range_values_array: PackedStringArray
			if "hint_range" in u_hint:
				var range_values: String = u_hint.replace("hint_range(", "")
				range_values = range_values.replace(")", "").strip_edges()
				range_values_array = range_values.split(",")

			if u_type == "float":
				if range_values_array.size() >= 1:
					min_value = float(range_values_array[0])
				else:
					min_value = 0.01

				if range_values_array.size() >= 2:
					max_value = float(range_values_array[1])

				if range_values_array.size() >= 3:
					step = float(range_values_array[2])
				else:
					step = 0.01

				if u_value != "":
					slider.value = float(u_value)
			else:
				if range_values_array.size() >= 1:
					min_value = int(range_values_array[0])

				if range_values_array.size() >= 2:
					max_value = int(range_values_array[1])

				if range_values_array.size() >= 3:
					step = int(range_values_array[2])

				if u_value != "":
					slider.value = int(u_value)
			if params.has(u_name):
				slider.value = params[u_name]
			else:
				params[u_name] = slider.value
			slider.min_value = min_value
			slider.max_value = max_value
			slider.step = step
			slider.value_changed.connect(value_changed.bind(u_name))
			slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var hbox := HBoxContainer.new()
			hbox.add_child(label)
			hbox.add_child(slider)
			parent_node.add_child(hbox)
		elif u_type == "vec2" or u_type == "ivec2" or u_type == "uvec2":
			var label := Label.new()
			label.text = humanized_u_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var vector2 := _vec2str_to_vector2(u_value)
			var slider := VALUE_SLIDER_V2_TSCN.instantiate() as ValueSliderV2
			slider.show_ratio = true
			slider.allow_greater = true
			if u_type != "uvec2":
				slider.allow_lesser = true
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value = vector2
			if params.has(u_name):
				slider.value = params[u_name]
			else:
				params[u_name] = slider.value
			slider.value_changed.connect(value_changed.bind(u_name))
			var hbox := HBoxContainer.new()
			hbox.add_child(label)
			hbox.add_child(slider)
			parent_node.add_child(hbox)
		elif u_type == "vec4":
			if "source_color" in u_hint:
				var label := Label.new()
				label.text = humanized_u_name
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var color := _vec4str_to_color(u_value)
				var color_button := ColorPickerButton.new()
				color_button.custom_minimum_size = Vector2(20, 20)
				color_button.color = color
				if params.has(u_name):
					color_button.color = params[u_name]
				else:
					params[u_name] = color_button.color
				color_button.color_changed.connect(value_changed.bind(u_name))
				color_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				color_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				var hbox := HBoxContainer.new()
				hbox.add_child(label)
				hbox.add_child(color_button)
				parent_node.add_child(hbox)
		elif u_type == "sampler2D":
			if u_name == "selection":
				continue
			if u_name == "palette_texture":
				var palette := Palettes.current_palette
				var palette_texture := ImageTexture.create_from_image(palette.convert_to_image())
				value_changed.call(palette_texture, u_name)
				Palettes.palette_selected.connect(
					func(_name): _shader_change_palette(value_changed, u_name)
				)
				palette.data_changed.connect(
					func(): _shader_update_palette_texture(palette, value_changed, u_name)
				)
				continue
			var label := Label.new()
			label.text = humanized_u_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hbox := HBoxContainer.new()
			hbox.add_child(label)
			if u_name.begins_with("gradient_"):
				var gradient_edit := GRADIENT_EDIT_TSCN.instantiate() as GradientEditNode
				gradient_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if params.has(u_name) and params[u_name] is GradientTexture2D:
					gradient_edit.set_gradient_texture(params[u_name])
				else:
					params[u_name] = gradient_edit.texture
				# This needs to be call_deferred because GradientTexture2D gets updated next frame.
				# Without this, the texture is purple.
				value_changed.call_deferred(gradient_edit.texture, u_name)
				gradient_edit.updated.connect(
					func(_gradient, _cc): value_changed.call(gradient_edit.texture, u_name)
				)
				hbox.add_child(gradient_edit)
			else:
				var file_dialog := FileDialog.new()
				file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
				file_dialog.access = FileDialog.ACCESS_FILESYSTEM
				file_dialog.size = Vector2(384, 281)
				file_dialog.file_selected.connect(file_selected.bind(u_name))
				file_dialog.use_native_dialog = use_native_file_dialogs
				var button := Button.new()
				button.text = "Load texture"
				button.pressed.connect(file_dialog.popup_centered)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				hbox.add_child(button)
				parent_node.add_child(file_dialog)
			parent_node.add_child(hbox)

		elif u_type == "bool":
			var label := Label.new()
			label.text = humanized_u_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var checkbox := CheckBox.new()
			checkbox.text = "On"
			if u_value == "true":
				checkbox.button_pressed = true
			if params.has(u_name):
				checkbox.button_pressed = params[u_name]
			else:
				params[u_name] = checkbox.button_pressed
			checkbox.toggled.connect(value_changed.bind(u_name))
			checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var hbox := HBoxContainer.new()
			hbox.add_child(label)
			hbox.add_child(checkbox)
			parent_node.add_child(hbox)


func _vec2str_to_vector2(vec2: String) -> Vector2:
	vec2 = vec2.replace("uvec2", "vec2")
	vec2 = vec2.replace("ivec2", "vec2")
	vec2 = vec2.replace("vec2(", "")
	vec2 = vec2.replace(")", "")
	var vec_values := vec2.split(",")
	if vec_values.size() == 0:
		return Vector2.ZERO
	var y := float(vec_values[0])
	if vec_values.size() == 2:
		y = float(vec_values[1])
	var vector2 := Vector2(float(vec_values[0]), y)
	return vector2


func _vec4str_to_color(vec4: String) -> Color:
	vec4 = vec4.replace("vec4(", "")
	vec4 = vec4.replace(")", "")
	var rgba_values := vec4.split(",")
	var red := float(rgba_values[0])

	var green := float(rgba_values[0])
	if rgba_values.size() >= 2:
		green = float(rgba_values[1])

	var blue := float(rgba_values[0])
	if rgba_values.size() >= 3:
		blue = float(rgba_values[2])

	var alpha := float(rgba_values[0])
	if rgba_values.size() == 4:
		alpha = float(rgba_values[3])
	var color := Color(red, green, blue, alpha)
	return color


func _shader_change_palette(value_changed: Callable, parameter_name: String) -> void:
	var palette := Palettes.current_palette
	_shader_update_palette_texture(palette, value_changed, parameter_name)
	#if not palette.data_changed.is_connected(_shader_update_palette_texture):
	palette.data_changed.connect(
		func(): _shader_update_palette_texture(palette, value_changed, parameter_name)
	)


func _shader_update_palette_texture(
	palette: Palette, value_changed: Callable, parameter_name: String
) -> void:
	value_changed.call(ImageTexture.create_from_image(palette.convert_to_image()), parameter_name)
