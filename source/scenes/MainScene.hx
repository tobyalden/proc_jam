package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.input.*;
import haxepunk.math.*;
import entities.*;

class MainScene extends Scene {
    private var lastMouse:Vector2;
    private var cameraAnchor:Vector2;

    override public function begin() {
        add(new Level(0, 0));
        var text = new Text("
R: Randomize
A: Cellular automata
D: Drunken walk (Connected)
U: Drunken walk (Unconnected)
N: Connect all rooms
V: Diamond-square noise
P: Offset chunks
I: Invert
F: Fill all
C: Clear all
H: Flip horizontally
Q: Repeat last 10 steps
M: Start / Stop Mutating
1: Reset size
2 - 5: Scale up
6 - 0: Perlin noise
        ");
        text.color = 0x00FF00;
        text.smooth = false;
        text.setBorder();
        addGraphic(text, -5);
        var bg = Image.createRect(text.width + 10, text.height, 0x000000);
        bg.alpha = 0.5;
        addGraphic(bg, -2);
        cameraAnchor = new Vector2(HXP.width/2, HXP.height/2);
    }

    public function resetCamera() {
        camera.scale = 1;
        cameraAnchor = new Vector2(HXP.width/2, HXP.height/2);
    }

    override public function update() {
        if(Mouse.mouseDown) {
            var cameraShift = new Vector2(
                (Mouse.mouseX - lastMouse.x) * (1/camera.scale),
                (Mouse.mouseY - lastMouse.y) * (1/camera.scale)
            );
            cameraAnchor.subtract(cameraShift);
        }
        camera.scale += Mouse.mouseWheelDelta * 0.002;
        camera.scale = Math.max(camera.scale, 0.1);
        camera.scale = Math.min(camera.scale, 1);
        camera.anchor(cameraAnchor);
        super.update();
        lastMouse = new Vector2(Mouse.mouseX, Mouse.mouseY);
    }
}
