extends Control


@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var progress_bar: ProgressBar = %ProgressBar

var currently_loading_scene: String = ""

func _process(_delta: float) -> void:
	if currently_loading_scene.is_empty():
		set_process(false)
		return
	
	_handle_loading_progress()

#region logic

func change_scene(scene_path: String, block: Callable = func() -> void: pass) -> void:
	progress_bar.value = 0.0
	animation_player.play("fade_out")
	await animation_player.animation_finished
	block.call()
	currently_loading_scene = scene_path
	ResourceLoader.load_threaded_request(currently_loading_scene)
	set_process(true)

func _handle_loading_progress() -> void:
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(currently_loading_scene, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = 100 * progress[0]
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var new_scene: PackedScene = ResourceLoader.load_threaded_get(currently_loading_scene)
			progress_bar.value = 100
			get_tree().change_scene_to_packed(new_scene)
			animation_player.play("fade_in")
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			progress_bar.value = 95
			push_error("Failed to load scene: %s" %currently_loading_scene)
			currently_loading_scene = ""
			animation_player.play("fade_in")
			

#endregion logic
