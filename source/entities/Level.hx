package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;

typedef Walker = {
    var x:Int;
    var y:Int;
    var direction:String;
}

class Level extends Entity {
    private var walkers:Array<Walker>;
    private var grid:Grid;
    private var tiles:Tilemap;

    public function new(x:Float, y:Float) {
        super(x, y);

        // Create map data
        grid = new Grid(640, 360, 8, 8);

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

    private function randomize(wallChance:Float = 0.55) {
        // Randomize the map by setting each tile to a wall or a floor
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                grid.setTile(tileX, tileY, wallChance > Math.random());
            }
        }
    }

    private function cellularAutomata(minNeighbors:Int = 4, maxNeighbors:Int = 5) {
        // Performs an iteration of cellular automata on the map
        var cloneGrid = grid.clone();
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                if(countNeighbors(tileX, tileY) < minNeighbors) {
                    // If there are fewer neighboring walls than the minimum,
                    // the tile becomes a floor
                    cloneGrid.setTile(tileX, tileY, false);
                }
                else if(countNeighbors(tileX, tileY) > maxNeighbors) {
                    // If there are more neighboring walls than the maximum,
                    // the tile becomes a wall
                    cloneGrid.setTile(tileX, tileY, true);
                }
            }
        }
        grid = cloneGrid;
    }

    private function countNeighbors(tileX:Int, tileY:Int) {
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

    private function drunkenWalk(
        numberOfSteps:Int = 500,
        changeDirectionChance:Float = 0.5,
        spawnWalkerChance:Float = 0.05,
        destroyWalkerChance:Float = 0.05,
        maxWalkers:Int = 10,
        spawnWalkersFromWalkers:Bool = false
    ) {
        walkers = new Array<Walker>();

        // Create a walker in the center of the map
        walkers.push({
            x: Std.int(grid.columns/2),
            y: Std.int(grid.rows/2),
            direction: HXP.choose('n', 'e', 's', 'w')
        });

        for(i in 0...numberOfSteps) {
            for(walker in walkers) {
                // Create a floor under the walker
                grid.setTile(walker.x, walker.y, false);

                // Move the walker
                if(walker.direction == 'n') {
                    walker.y -= 1;
                }
                else if(walker.direction == 'e') {
                    walker.x += 1;
                }
                else if(walker.direction == 's') {
                    walker.y += 1;
                }
                else if(walker.direction == 'w') {
                    walker.x -= 1;
                }

                if(changeDirectionChance > Math.random()) {
                    // Change the walker's direction
                    var directions = ['n', 'e', 's', 'w'];
                    directions.remove(walker.direction);
                    walker.direction = directions[Std.random(3)];
                }

                if(
                    walkers.length < maxWalkers
                    && spawnWalkerChance > Math.random()
                ) {
                    // Spawn a new walker
                    walkers.push({
                        x: spawnWalkersFromWalkers ?
                            walker.x : Std.random(grid.columns)
                        ,
                        y: spawnWalkersFromWalkers ?
                            walker.y : Std.random(grid.rows)
                        ,
                        direction: HXP.choose('n', 'e', 's', 'w')
                    });
                }

                if(
                    walkers.length > 1
                    && destroyWalkerChance > Math.random()
                ) {
                    // Destroy a walker
                    walkers.remove(walkers[Std.random(walkers.length)]);
                }
            }
        }
    }

    private function invert() {
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                grid.setTile(tileX, tileY, !grid.getTile(tileX, tileY));
            }
        }
    }

    private function clear() {
        grid.clearRect(0, 0, grid.columns, grid.rows);
    }

    private function fill() {
        grid.setRect(0, 0, grid.columns, grid.rows);
    }

    override public function update() {
        if(Key.pressed(Key.R)) {
            randomize();
        }
        if(Key.pressed(Key.A)) {
            cellularAutomata();
        }
        if(Key.pressed(Key.I)) {
            invert();
        }
        if(Key.pressed(Key.C)) {
            clear();
        }
        if(Key.pressed(Key.F)) {
            fill();
        }
        if(Key.pressed(Key.D)) {
            drunkenWalk();
        }
        if(Key.pressed(Key.ANY)) {
            tiles.loadFromString(grid.saveToString(',', '\n', '1', '0'));
        }
        super.update();
    }
}
