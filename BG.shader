// TODO: Figure out smooth palette transitions.
// Enabling filter causes the wrong colors to be
// used sometimes, because the smoothing causes
// colors to bleed into each other. For example,
// the background for circles should always be
// orange, but with filtering enabled, it can
// occasionally turn red/yellow because the colors
// are bleeding into each other.

// I need to either find a way to only filter on
// the Y axis to smooth animations, or a better
// workflow for creating palettes so I can make
// them with proper gradients.

shader_type canvas_item;

// Variables related to the palette

// The palette texture to use.
uniform sampler2D palette : hint_albedo;

// The speed of the palette animation.
uniform float palette_speed = 0.05;

// Uniforms related to horizontal effects.

// The amplitude of the sin function.
// Increase for more intense waves, decrease
// for less.
uniform float h_amp = 0.05;

// Distance between the waves.
uniform float h_freq = 4.0;

// Speed of the waves.
uniform float h_speed = 5.0;

// If true, the image will squash/stretch
// instead of wave.
uniform bool h_squash = false;

// If true, every X number of rows
// will have a different offset,
// giving a weird sort of pseudo-
// transparency effect.
uniform bool h_interleaved = false;

// The number of rows that need to pass
// before the interleaving happens.
uniform float h_interleaved_period = 2.0;

// The 
uniform float h_interleaved_amount = -1.0;

// Identical to the horizontal versions,
// but apply vertically instead.
uniform float v_amp = 0.05;
uniform float v_freq = 4.0;
uniform float v_speed = 5.0;
uniform bool v_squash = false;
uniform bool v_interleaved = false;
uniform float v_interleaved_period = 2.0;
uniform float v_interleaved_amount = -1.0;

// Scale of the background image.
uniform vec2 background_scale = vec2(5.0, 5.0);

// Aspect ratio of the image.
// Whenever the image is resized, set this
// to the window height / window width
// to avoid the background texture being squished.
uniform float aspect_ratio = 0.5;

// The offset of the background image.
// Update this uniform in your code if you
// want the background image to be scrolled
uniform vec2 offset = vec2(0, 0);

void fragment() {
	// Apply scale & aspect ratio to the UVs
	vec2 tiled_uvs = (UV + offset) * background_scale;
	tiled_uvs.y *= aspect_ratio;
	
	// Decide the UV direction we're using for the distortion.
	// If you use the opposite axis, you get a waving effect.
	// If you use the same axis, you get the stretching effect.
	float h_axis = mix(tiled_uvs.y, tiled_uvs.x, float(h_squash));
	float v_axis = mix(tiled_uvs.x, tiled_uvs.y, float(v_squash));
	
	// Next, calculate the actual offset based on the freq, amp, and speed
	// params.
	float h_offset = h_amp * sin((h_freq * h_axis) + (TIME * h_speed));
	float v_offset = v_amp * sin((v_freq * v_axis) + (TIME * v_speed));
	
	// Apply interleaving
	
	// Get the period to use, depending on whether or not we're actually
	// using interleaving.
	float h_actual_period = mix(0.0, h_interleaved_period, float(h_interleaved));
	
	// Calculate whether or not this line is being interleaved.
	float h_interleaving = abs(mod(FRAGCOORD.y, h_actual_period));
	
	// Invert h_offset if we are
	h_offset = mix(h_offset, h_offset * h_interleaved_amount, float(h_interleaving > 1.0));
	
	// Duplicate the same code for vertical interleaving.
	float v_actual_period = mix(0.0, v_interleaved_period, float(v_interleaved));
	float v_interleaving = abs(mod(FRAGCOORD.x, v_actual_period));
	v_offset = mix(v_offset, v_offset * v_interleaved_amount, float(v_interleaving > 1.0));
	
	// Get the color from the texture, using our warped UVs.
	vec4 col = texture(TEXTURE, tiled_uvs + vec2(h_offset, v_offset));
	
	vec2 palette_size = vec2(textureSize(palette, 0));
	
	// Do some weird math stuff.
	// This remaps 0.0 .. 1.0 from being in the range of 0 .. 255,
	// to 0 .. palette_size (or frames)
	float palette_entry = (col.r*255.0)/(palette_size.x - 0.001);
	float current_frame = (255.0)/(palette_size.y - 0.0001) + mod(TIME * palette_speed, 1.0);
	
	vec2 uvs = vec2(palette_entry, current_frame) * palette_size;
	
	float current_frame_int = trunc(uvs.y);
	float current_frame_decimal = uvs.y - current_frame_int;
	
	// Get the color from the palette, and pass it to the shader output.
	vec4 output1 = texture(palette, vec2(uvs.x, uvs.y - 1.0) / palette_size);
	vec4 output2 = texture(palette, vec2(uvs.x, uvs.y) / palette_size);
	COLOR = mix(output1, output2, current_frame_decimal);
}
