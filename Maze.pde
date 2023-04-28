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
  MazeCell start, end;

  Maze(String[] s) {
  assert s != null && s.length > 0 :
    String.format("Maze.fromString(%s) bad input");
    List<List<MazeCell>> newGrid = new ArrayList<List<MazeCell>>();
    rows = s.length;
    for (int r = 0; r < s.length; r++) {
      String[] rowData = s[r].split(",");
    assert rowData != null && rowData.length > 0 :
      String.format("tried to get row data, but it's bad: %s", s[r]);
      cols = rowData.length;
      newGrid.add(new ArrayList<MazeCell>());
      for (int c = 0; c < rowData.length; c++) {
        newGrid.get(r).add(new MazeCell(rowData[c]));
      }
    }

    grid = new MazeCell[cols][rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j] = newGrid.get(j).get(i);
      }
    }
    start = grid[0][0];
    end = grid[cols-1][rows-1];
  }

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
    // select random cells for start and end positions
    //start = grid[(int) random(cols)][0];
    //end = grid[(int) random(cols)][rows-1];

    // Start upper left, end lower right
    start = grid[0][0];
    end = grid[cols-1][rows-1];

    // remove walls to create openings
    start.setWall(Wall.NORTH, false);
    end.setWall(Wall.SOUTH, false);
    System.out.println("Generating Maze...");
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

  private void generateMaze() {
    Stack<MazeCell> mazeStack;
    mazeStack = new Stack<MazeCell>();
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

  public String toString() {
    StringBuffer b = new StringBuffer();

    boolean newLine = false;
    for (int r = 0; r < rows; r++) {
      if(newLine) b.append("\n");
      newLine = true;
      boolean comma = false;
      for (int c = 0; c < cols; c++) {
        if (comma) b.append(",");
        b.append(getCell(c, r));
        comma = true;
      }
    }
    return b.toString();
  }
}

static class MazeInstance {
  private static List<Maze> instances = new ArrayList<Maze>();

  public static Maze getInstance() {
    assert instances.size() > 0 :
    String.format("No maze was initialized");
    return instances.get(0);
  }

  public static Maze getInstance(NeuronGames n, String[] s) {
    if (instances.size() == 0) {
      instances.add(n.new Maze(s));
    }
    return instances.get(0);
  }
  
  public static Maze getInstance(NeuronGames n, int c, int r) {
    if (instances.size() == 0) {
      instances.add(n.new Maze(c, r));
    }
    return instances.get(0);
  }
  
  public static void reset(){
    instances.clear();
  }
}
