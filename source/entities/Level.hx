package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;

class Level extends Entity {
    private var grid:Grid;
    private var tiles:Tilemap;

    public function new(x:Float, y:Float) {
        super(x, y);

        // Create map data
        grid = new Grid(640, 360, 8, 8);
        randomize();
        cellularAutomata();
        
        // Create tilemap from map data
        tiles = new Tilemap(
            'graphics/tiles.png',
            grid.width, grid.height, grid.tileWidth, grid.tileHeight
        );
        tiles.loadFromString(grid.saveToString(',', '\n', '1', '0'));

        // Set collision mask to map data and graphic to tilemap
        mask = grid;
        graphic = tiles;
    }

    public function randomize(wallChance:Float = 0.45) {
        // Randomize the map by setting each tile to a wall or a floor
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                grid.setTile(tileX, tileY, wallChance > Math.random());
            }
        }
    }

    public function cellularAutomata(minNeighbors:Int = 3, maxNeighbors:Int = 4) {
        // Performs an iteration of cellular automata on the map
        var cloneGrid = grid.clone();
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                if(countNeighbors(tileX, tileY) > maxNeighbors) {
                    cloneGrid.setTile(tileX, tileY, true);
                }
                else if(countNeighbors(tileX, tileY) < minNeighbors) {
                    cloneGrid.setTile(tileX, tileY, false);
                }
            }
        }
        grid = cloneGrid;
    }

    public function countNeighbors(tileX:Int, tileY:Int) {
        var count = 0;
        for(neighborX in [tileX - 1, tileX, tileX + 1]) {
            for(neighborY in [tileY - 1, tileY, tileY + 1]) {
                if(neighborX == tileX && neighborY == tileY) {
                    // Don't count the tile we're checking as a neighbor
                    continue;
                }
                if(grid.getTile(neighborX, neighborY)) {
                    count++;
                }
            }
        }
        return count;
    }

    override public function update() {
        if(Key.pressed(Key.R)) {
            randomize();
        }
        if(Key.pressed(Key.C)) {
            cellularAutomata();
        }
        if(Key.pressed(Key.ANY)) {
            tiles.loadFromString(grid.saveToString(',', '\n', '1', '0'));
        }
        super.update();
    }
}
