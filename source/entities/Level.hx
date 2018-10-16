package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import scenes.*;

typedef Walker = {
    var x:Int;
    var y:Int;
    var direction:String;
}

class Level extends Entity {
    public static inline var TILE_SIZE = 8;

    private var walkers:Array<Walker>;
    private var grid:Grid;
    private var tiles:Tilemap;

    public function new(x:Float, y:Float) {
        super(x, y);

        // Create map data
        grid = new Grid(640, 360, TILE_SIZE, TILE_SIZE);
        randomize();

        // Create tilemap from map data
        updateGraphic();

        // Set collision mask to map data
        mask = grid;
    }

    private function updateGraphic() {
        tiles = new Tilemap(
            'graphics/tiles.png',
            grid.width, grid.height, grid.tileWidth, grid.tileHeight
        );
        tiles.loadFromString(grid.saveToString(',', '\n', '1', '0'));
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
        spawnWalkersFromWalkers:Bool = true
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

    private function scale(scaleFactor:Int = 2) {
        var scaledGrid = new Grid(
            grid.width * scaleFactor,
            grid.height * scaleFactor,
            TILE_SIZE, TILE_SIZE
        );
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                for(scaleX in 0...scaleFactor) {
                    for(scaleY in 0...scaleFactor) {
                        scaledGrid.setTile(
                            tileX * scaleFactor + scaleX,
                            tileY * scaleFactor + scaleY,
                            grid.getTile(tileX, tileY)
                        );
                    }
                }
            }
        }
        grid = scaledGrid;
    }

    private function resetMapSize() {
        var newMap = new Grid(640, 360, TILE_SIZE, TILE_SIZE);
        for(tileX in 0...newMap.columns) {
            for(tileY in 0...newMap.rows) {
                newMap.setTile(tileX, tileY, grid.getTile(tileX, tileY));
            }
        }
        grid = newMap;
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
        if(Key.pressed(Key.U)) {
            drunkenWalk(false);
        }
        if(Key.pressed(Key.DIGIT_1)) {
            resetMapSize();
            cast(scene, MainScene).resetCamera();
        }
        if(Key.pressed(Key.DIGIT_2)) {
            scale(2);
        }
        if(Key.pressed(Key.DIGIT_3)) {
            scale(3);
        }
        if(Key.pressed(Key.DIGIT_4)) {
            scale(4);
        }
        if(Key.pressed(Key.DIGIT_5)) {
            scale(5);
        }
        if(Key.pressed(Key.ANY)) {
            updateGraphic();
        }
        super.update();
    }
}
