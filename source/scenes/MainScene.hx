package scenes;

import haxepunk.*;
import haxepunk.graphics.*;
import entities.*;

class MainScene extends Scene {
    override public function begin() {
        add(new Level(0, 0));
    }
}
