shader_type canvas_item;

uniform int type = 0;
uniform bool selected = false;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (type == 0)
	{
		COLOR = COLOR;
	}
	else if (type == 1)
	{
		//COLOR.r *= 0.25;
		//COLOR.b *= 0.25;
		COLOR = COLOR;
	} else if (type == 2)
	{
		COLOR = COLOR*0.25;	
	}
	
	if (selected)
	{
		COLOR = COLOR*1.5;
	}
	
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
