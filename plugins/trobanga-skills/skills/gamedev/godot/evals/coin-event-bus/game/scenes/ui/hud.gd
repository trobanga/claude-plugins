extends CanvasLayer

@onready var score_label: Label = $ScoreLabel


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		score_label.text = "Score: %d" % player.score
