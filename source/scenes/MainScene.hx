package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import entities.*;

class MainScene extends Scene {
    override public function begin() {
        add(new Level(0, 0));
        var text = new Text("
R: Randomize
A: Cellular Automata
F: Fill All
D: Drunken Walk
I: Invert
C: Clear All
        ");
    text.color = 0x00FF00;
    text.smooth = false;
    text.setBorder();
    addGraphic(text);
    }
}
