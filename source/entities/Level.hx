package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import hxnoise.*;
import scenes.*;

typedef Walker = {
    var x:Int;
    var y:Int;
    var direction:String;
}

typedef Cell = {
    var tileX:Int;
    var tileY:Int;
}

class Level extends Entity {
    public static inline var TILE_SIZE = 8;

    private var walkers:Array<Walker>;
    private var grid:Grid;
    private var tiles:Tilemap;
    private var perlin:Perlin;
    private var diamondSquare:DiamondSquare;

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

    private function connectAllRooms() {
        while(countRooms() > 1) {
            connectTwoRooms(getRooms());
        }
    }

    private function connectTwoRooms(rooms:Array<Array<Int>>) {
        // Pick two random cells in different rooms
        var c1:Cell = getRandomCell();
        while(rooms[c1.tileX][c1.tileY] == 0) {
            c1 = getRandomCell();
        }
        var c2:Cell = getRandomCell();
        while(
            rooms[c2.tileX][c2.tileY] == 0
            || rooms[c1.tileX][c1.tileY] == rooms[c2.tileX][c2.tileY]
        ) {
            c2 = getRandomCell();
        }

        // Get c1 and c2 as close as possible without leaving their rooms
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                var here = new Vector2(tileX, tileY);
                if(rooms[tileX][tileY] == rooms[c1.tileX][c1.tileY]) {
                    var c1Vector = new Vector2(c1.tileX, c1.tileY);
                    var c2Vector = new Vector2(c2.tileX, c2.tileY);
                    if(c1Vector.distance(c2Vector) > c2Vector.distance(here)) {
                        c1 = {tileX: tileX, tileY: tileY};
                    }
                }
                if(rooms[tileX][tileY] == rooms[c2.tileX][c2.tileY]) {
                    var c1Vector = new Vector2(c1.tileX, c1.tileY);
                    var c2Vector = new Vector2(c2.tileX, c2.tileY);
                    if(c1Vector.distance(c2Vector) > c1Vector.distance(here)) {
                        c2 = {tileX: tileX, tileY: tileY};
                    }
                }
            }
        }

        // Dig a tunnel between the two cells
        var cDig:Cell = {tileX: c1.tileX, tileY: c1.tileY};
        cDig = moveCellTowardsCell(cDig, c2);
        while (cDig != c2 && rooms[cDig.tileX][cDig.tileY] == 0) {
            grid.setTile(cDig.tileX, cDig.tileY, false);
            cDig = moveCellTowardsCell(cDig, c2);
        }
    }

    private function moveCellTowardsCell(move:Cell, towards:Cell) {
        if (move.tileX < towards.tileX) {
            move.tileX = move.tileX + 1;
        }
        else if (move.tileX > towards.tileX) {
            move.tileX = move.tileX - 1;
        }
        else if (move.tileY < towards.tileY) {
            move.tileY = move.tileY + 1;
        }
        else if (move.tileY > towards.tileY) {
            move.tileY = move.tileY - 1;
        }
        return move;
    }

    private function getRandomCell() {
        var randomCell:Cell = {
            tileX: Std.random(grid.columns),
            tileY: Std.random(grid.rows)
        };
        return randomCell;
    }

    private function getRooms() {
        return getRoomsAndCount().rooms;
    }

    private function countRooms() {
        return getRoomsAndCount().count;
    }

    private function getRoomsAndCount() {
        // Finds and numbers all discrete rooms,
        // then returns a 2D array of integers the size of the map,
        // where each cell contains its rooms number (0 for walls)
        var roomCount = 0;
        var rooms = [
            for (x in 0...grid.columns) [for (y in 0...grid.rows) 0]
        ];
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                if(!grid.getTile(tileX, tileY) && rooms[tileX][tileY] == 0) {
                    roomCount++;
                    floodFill(tileX, tileY, rooms, roomCount);
                }
            }
        }
        return {rooms: rooms, count: roomCount};
    }

    private function floodFill(
        fillX:Int, fillY:Int, rooms:Array<Array<Int>>, fillWith:Int
    ) {
        if(
            isWithinMap(fillX, fillY)
            && !grid.getTile(fillX, fillY)
            && rooms[fillX][fillY] == 0
        ) {
            rooms[fillX][fillY] = fillWith;
            floodFill(fillX + 1, fillY, rooms, fillWith);
            floodFill(fillX - 1, fillY, rooms, fillWith);
            floodFill(fillX, fillY + 1, rooms, fillWith);
            floodFill(fillX, fillY - 1, rooms, fillWith);
        }
    }

    private function isWithinMap(tileX:Int, tileY:Int) {
        return (
            tileX >= 0 && tileX < grid.columns
            && tileY >= 0 && tileY < grid.rows
        );
    }

    private function clear() {
        grid.clearRect(0, 0, grid.columns, grid.rows);
    }

    private function fill() {
        grid.setRect(0, 0, grid.columns, grid.rows);
    }

    private function perlinNoise(zoom:Float = 1) {
        perlin = new Perlin();
        var shift = new Vector2(
            Std.random(2147483647), Std.random(2147483647)
        );
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                var position = new Vector2(tileX, tileY);
                position.scale(zoom);
                position.add(shift);
                var noise = perlin.OctavePerlin(
                    position.x, position.y, 0.1, 5, 0.5, 0.25
                );
                grid.setTile(tileX, tileY, noise < 0.5);
            }
        }
    }

    private function diamondSquareNoise() {
        diamondSquare = new DiamondSquare(
            grid.columns, grid.rows, TILE_SIZE, 3, randFunc
        );
        diamondSquare.diamondSquare();
        for(tileX in 0...grid.columns) {
            for(tileY in 0...grid.rows) {
                var noise = diamondSquare.getValue(tileX, tileY);
                grid.setTile(tileX, tileY, noise < 0.5);
            }
        }
    }

    private function randFunc() {
        return Math.random() - 0.5;
    }

    override public function update() {
        if(Key.pressed(Key.N)) {
            connectAllRooms();
        }
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
        if(Key.pressed(Key.V)) {
            diamondSquareNoise();
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
        if(Key.pressed(Key.DIGIT_6)) {
            perlinNoise(2);
        }
        if(Key.pressed(Key.DIGIT_7)) {
            perlinNoise(1);
        }
        if(Key.pressed(Key.DIGIT_8)) {
            perlinNoise(0.5);
        }
        if(Key.pressed(Key.DIGIT_9)) {
            perlinNoise(0.1);
        }
        if(Key.pressed(Key.DIGIT_0)) {
            perlinNoise(0.03);
        }
        if(Key.pressed(Key.ANY)) {
            updateGraphic();
        }
        super.update();
    }
}
