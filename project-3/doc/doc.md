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
	max-width: 512px;
}
iframe {
	width: 100%;
	height: 38em;
}
pre {
	border: 1px solid black;
	padding: 1em 2em;
}
/* dark mode */
@media (prefers-color-scheme: dark) {
	body {
		color: #cac5be;
		background-color: #181a1b;
	}
	pre {
		border: 1px solid white;
	}
	h1, h2, h3, h4, h5 {
		border-color: rgba(255, 255, 255, 0.48) !important;
	}
	a {
		color: #6eb2ee;
	}
}
</style>

# Project 3 - A crown, old and new

## Interactive Version

<iframe src="../export/index.html">
	Can't load iframe
</iframe>

- Look around: Left click + move mouse
- Zoom: Scroll

## Video Recording

<video alt="recording" controls>
<source src="videos/recording.webm">

</video>

## Step by Step Documentation

### Crown Mesh Generation

![](images/mesh-combined.png)

The crown mesh consists of multiple parts (from left to right): A curved torus at the top, two torus shapes and a thin flat part. The top part of the mesh is bent slightly outward.

The bent torus follows a Bézier curve defined with the `Path2D` Node in Godot:

![](images/curve2d.png)

The number of tips is configurable as well as the height and the subdivision detail of the mesh.

A crown with reduced subdivision detail and 2 tips:

![](images/mesh-low-detail-2-tips.png)

### Gem Mesh Generation

An algorithm was implemented that can generate different kinds of gems with different parameters. Three gem were created using this algorithm. They have been scaled using the `Node3D`s transform.

![](images/gems.png)

The script `mesh_generation.gd` contains the code for the mesh generation of both the gem and the individual crown parts.

### Gem Placement

![](images/mesh-with-gems.png)

The script `crown.gd` contains the functions `spawn_gems_top`, `spawn_gems_middle`, `spawn_gems_bottom`, which place the gems.

### Metal Material

![](images/gold-material.png)

A gold material was created by setting according albedo, metallic and roughness values.

### Corroded Metal

![](images/gold-corroded.png)

The corroded version of the gold material adds normal detail as well as oxidization.

### Gem Material

![](images/gem-material.gif)

The shader for the gem fakes details of a gem by doing a refraction along the surface normal. The shader then imitates an infinite plane that lies inside the diamond, which is parallel to the currently viewed surface. A cellular noise texture is mapped onto that plane and used to adjust the color and normal of each cell differently.

Additionally a second material is used using the `next_pass` feature of Godot to render the specular highlights of the actual mesh on top of the "inside" of the gem.

The material is configured to imitate an emerald.

### Corroded Gem

![](images/gem-corroded.png)

The corroded version of the gem adds normal detail, changes the roughness and adds dirt.

### Aging Process

![](images/age-blend.gif)

The corroded versions can be blended to the initial version to simulate the aging process.

### Complete interactive Scene

A scene was created to showcase the meshes and materials:

- A [HDRI from Polyhaven](https://polyhaven.com/a/sepulchral_chapel_basement) is used as background.
- Bloom is enabled.
- The crown was placed on a red pillow.
- A spotlight rotates around the crown and illuminates it.
- A weak directional light shines from the top.
- Both lights cast shadows using Godots shadow mapping capabilities.
- A `ReflectionProbe` is placed in the center of the crown to approximate reflections.
- UI elements are available to change the speed of the spotlight, the age of the crown and the number of tips on the crown.
- The camera can be controlled using the mouse.

![](images/scene.png)
