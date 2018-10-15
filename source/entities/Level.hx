package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;

class Level extends Entity {
    private var grid:Grid;

    public function new(x:Float, y:Float) {
        super(x, y);

        // Create map data
        grid = new Grid(640, 360, 8, 8);
        randomize();
        
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

    public function randomize(wallChance:Float = 0.5) {
        // Randomize the map by setting each tile to a wall or a floor
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                grid.setTile(tileX, tileY, wallChance < Math.random());
            }
        }
    }
}
