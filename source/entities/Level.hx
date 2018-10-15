package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;

class Level extends Entity {
    public function new(x:Float, y:Float) {
        super(x, y);

        // Create map data
        var grid = new Grid(640, 360, 8, 8);
        
        // Create tilemap from map data
        var tiles = new Tilemap(
            'graphics/tiles.png',
            grid.width, grid.height, grid.tileWidth, grid.tileHeight
        );
        tiles.loadFromString(grid.saveToString(',', '\n', '1', '0'));

        // Set collision mask to map data and graphic to tilemap
        mask = grid;
        graphic = tiles;
    }
}
