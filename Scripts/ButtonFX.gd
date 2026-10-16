extends Node

func apply_bounce(button: BaseButton) -> void:
	button.button_down.connect(func():
		AudioManager.play_sfx(AudioManager.sfx_click)
		button.pivot_offset = button.size / 2
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(0.88, 0.88), 0.08)
	)
	button.button_up.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
	)
