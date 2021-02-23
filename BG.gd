tool
extends Control

var offset: Vector2 = Vector2(0, 0)

var direction: Vector2 = Vector2(0, 0)

func _process(delta):
	offset += 0.4 * (direction * delta)
	
	$TextureRect.material.set_shader_param("offset", offset)


func _on_Sprite3_item_rect_changed():
	$TextureRect.material.set_shader_param("aspect_ratio", $Sprite3.scale.y / $Sprite3.scale.x)
