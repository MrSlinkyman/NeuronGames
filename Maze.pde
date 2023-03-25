/**
 * Maze is used to define the maze that the creatures will move around in
 * TODO: create maze for Barrier
 * TODO: create maze for Challenge
 * TODO: Determine size of maze within display area
 */
import java.util.HashSet;
import java.util.Set;
import java.util.Stack;

class Maze {
  MazeCell[][] grid;
  int cols, rows;
  int cellWidth, cellHeight;
  Stack<MazeCell> mazeStack;
  MazeCell start, end;
    //double xFactor = (barrierType.hasArgs()) ? barrierType.getArg(0) : 0;
    //double yFactor = (barrierType.hasArgs()) ? barrierType.getArg(1) : 0;

  Maze(int c, int r) {
    this.cols = c;
    this.rows = r;
    //cols = rows = (width - 1) / cellSize;
    grid = new MazeCell[cols][rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j] = new MazeCell(i, j); // pass i, j, and w as arguments
      }
    }
    mazeStack = new Stack<MazeCell>();
    // select random cells for start and end positions
    //start = grid[(int) random(cols)][0];
    //end = grid[(int) random(cols)][rows-1];
    start = grid[0][0];
    end = grid[cols-1][rows-1];

    // remove walls to create openings
    start.setWall(Wall.NORTH, false);
    end.setWall(Wall.SOUTH, false);
    System.out.println("Generating Maz...");
    generateMaze();
    System.out.println("...Generated");
  }

  public MazeCell getStart() {
    return start;
  }

  public MazeCell getEnd() {
    return end;
  }

  // getter methods
  public int getRows() {
    return rows;
  }

  public int getCols() {
    return cols;
  }

  public MazeCell getCell(int col, int row) {
    return grid[col][row];
  }
  //public boolean draw() {
  //  boolean finished = false;
  //  background(255);
  //  for (int i = 0; i < cols; i++) {
  //    for (int j = 0; j < rows; j++) {
  //      grid[i][j].draw(x_offset, y_offset);
  //    }
  //  }
  // while(!finished)
  //  current.visited = true;
  //  Cell next = current.getRandomUnvisitedNeighbor(this);
  //  if (next != null) {
  //    mazeStack.push(current);
  //    current.removeWall(next);
  //    current = next;
  //    finished = false;
  //  } else if (mazeStack.size() > 0) {
  //    current = mazeStack.pop();
  //    finished = false;
  //  } else {
  //    // draw start and end markers
  //    // draw start and end markers
  //    noStroke();
  //    fill(0, 255, 0, 125);
  //    rect(start.x+x_offset, start.y + y_offset, cellWidth, cellHeight);
  //    fill(255, 0, 0, 125);
  //    rect(end.x + x_offset, end.y + y_offset, cellWidth, cellHeight);
  //    finished = true;
  //  }

  //  return finished;
  //}

  private void generateMaze() {
    boolean finished = false;
    MazeCell current = start;
    while (!finished) {
      current.setVisited(true);
      MazeCell next = current.getRandomUnvisitedNeighbor(this);
      if (next != null) {
        mazeStack.push(current);
        current.removeWall(next);
        current = next;
        finished = false;
      } else if (mazeStack.size() > 0) {
        current = mazeStack.pop();
        finished = false;
      } else {
        finished = true;
      }
    }
  }
}

static class MazeInstance {
  private static List<Maze> instances = new ArrayList<Maze>();
  
  public static Maze getInstance(){
    assert instances.size() > 0 : String.format("No maze was initialized");
    return instances.get(0);
  }

  public static Maze getInstance(NeuronGames n, int c, int r){
    if(instances.size() == 0){
      instances.add(n.new Maze(c,r));
    } 
    return instances.get(0);
  }
}
