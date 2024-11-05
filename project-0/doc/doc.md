<style>
body {
	max-width: 60em;
	line-height: 150%;
	font-family: sans-serif;
	padding: 1em;
	margin: 0 auto;
}
img, video {
	width: 100%;
}
table {
	border-collapse: collapse;
	margin: 1em 3em;
}
th {
	border-bottom: 2px solid #333;
}
td {
	border-bottom: 1px solid #333;
}
th, td {
	padding: 0.25em;
	text-align: left;
}
/* dark mode */
@media (prefers-color-scheme: dark) {
	body {
		color: #cac5be;
		background-color: #181a1b;
	}
	td {
		border-bottom: 1px solid #aaa;
	}
	th {
		border-bottom: 2px solid #aaa;
	}
}
</style>

# Project 0 - A shader for hardwood panels

A configurable shader that can represent many kinds of wood panels. This document contains a video showcasing how the shader parameters influence the output and additionally lists 5 examples of how to configure the shader to imitate a photograph of hardwood panels.

<!-- ## Playable version

<iframe src="../export/index.html">
	Can't load iframe
</iframe> -->

## Showcase video

<video width="90%" alt="some colorful animation" controls>
<source src="videos/parameter-showcase.mp4">

</video>

## Examples

Listed are 5 examples of how to configure the shader parameters to imitate a photograph of hardwood panels. Parameters for color gradients and noise textures are not listed, you need to open the godot project to see their settings.

### Example 1

![Reference photo 1](images/wood_1.jpg)

![Shader output 1](images/render_1.png)

Shader parameters:

| Parameter        | Value      |
| ---------------- | ---------- |
| Planks Num       | (0.5, 3.0) |
| Border Color     | #442e1fc3  |
| Border Thickness | 0.1        |
| Age              | 4.611      |
| Ring Compression | 1          |
| Snarl            | 0.28       |
| Seed             | 0.126      |
| Knot Size        | 0.1        |

### Example 2

![Reference photo 2](images/wood_2.jpg)

![Shader output 2](images/render_2.png)

Shader parameters:

| Parameter        | Value        |
| ---------------- | ------------ |
| Planks Num       | (0.5, 2.785) |
| Border Color     | #cf8d55      |
| Border Thickness | 1.06         |
| Age              | 76.316       |
| Ring Compression | 0            |
| Snarl            | 0.103        |
| Seed             | 0.234        |
| Knot Size        | 0.035        |

### Example 3

![Reference photo 3](images/wood_3.jpg)

![Shader output 3](images/render_3.png)

Shader parameters:

| Parameter        | Value        |
| ---------------- | ------------ |
| Planks Num       | (1.0, 2.785) |
| Border Color     | #ffffffff    |
| Border Thickness | 0            |
| Age              | 15.135       |
| Ring Compression | 0.088        |
| Snarl            | 0.321        |
| Seed             | 1            |
| Knot Size        | 0.1          |

### Example 4

![Reference photo 4](images/wood_4.jpg)

![Shader output 4](images/render_4.png)

Shader parameters:

| Parameter        | Value      |
| ---------------- | ---------- |
| Planks Num       | (1.0, 2.0) |
| Border Color     | #442e1fc3  |
| Border Thickness | 0.45       |
| Age              | 16.026     |
| Ring Compression | 0.053      |
| Snarl            | 0.652      |
| Seed             | 0.947      |
| Knot Size        | 0          |

### Example 5

![Reference photo 5](images/wood_5.jpg)

![Shader output 5](images/render_5.png)

Shader parameters:

| Parameter        | Value        |
| ---------------- | ------------ |
| Planks Num       | (1.435, 4.0) |
| Border Color     | #442e1fc3    |
| Border Thickness | 2            |
| Age              | 5.518        |
| Ring Compression | 0.807        |
| Snarl            | 0.526        |
| Seed             | 0.295        |
| Knot Size        | 0            |
