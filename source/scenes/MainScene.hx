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
A: Cellular Automata
F: Fill All
D: Drunken Walk (Connected)
U: Drunken Walk (Unconnected)
I: Invert
C: Clear All
1: Reset size
2 - 5: Scale up
        ");
        text.color = 0x00FF00;
        text.smooth = false;
        text.setBorder();
        addGraphic(text);
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
        if(camera.scale == 1) {
            resetCamera();
        }
        camera.anchor(cameraAnchor);
        super.update();
        lastMouse = new Vector2(Mouse.mouseX, Mouse.mouseY);
    }
}
