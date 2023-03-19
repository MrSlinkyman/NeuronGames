import java.util.List;

public class MazeCell {
  private int col;
  private int row;
  private boolean[] walls;
  boolean visited;

  public MazeCell(int col, int row) {
    this.col = col;
    this.row = row;
    this.walls = new boolean[] { true, true, true, true };
    this.visited = false;
  }

  public int getCol() {
    return col;
  }

  public int getRow() {
    return row;
  }

  public boolean getWall(Wall wall) {
    return walls[wall.ordinal()];
  }

  public void setWall(Wall wall, boolean value) {
    walls[wall.ordinal()] = value;
  }

  public boolean isVisited() {
    return visited;
  }

  public void setVisited(boolean visited) {
    this.visited = visited;
  }

  private void removeWall(MazeCell next) {
    int colDiff = next.getCol() - getCol();
    int rowDiff = next.getRow() - getRow();

    if (colDiff == 1) {
      setWall(Wall.EAST, false);
      next.setWall(Wall.WEST, false);
    } else if (colDiff == -1) {
      setWall(Wall.WEST, false);
      next.setWall(Wall.EAST, false);
    } else if (rowDiff == 1) {
      setWall(Wall.SOUTH, false);
      next.setWall(Wall.NORTH, false);
    } else if (rowDiff == -1) {
      setWall(Wall.NORTH, false);
      next.setWall(Wall.SOUTH, false);
    }
  }

  public MazeCell getRandomUnvisitedNeighbor(Maze maze) {
    ArrayList<MazeCell> neighbors = new ArrayList<MazeCell>();
    if (row > 0 && !maze.grid[col][row - 1].visited) { // top neighbor
      neighbors.add(maze.grid[col][row - 1]);
    }
    if (col < maze.cols - 1 && !maze.grid[col + 1][row].visited) { // right neighbor
      neighbors.add(maze.grid[col + 1][row]);
    }
    if (row < maze.rows - 1 && !maze.grid[col][row + 1].visited) { // bottom neighbor
      neighbors.add(maze.grid[col][row + 1]);
    }
    if (col > 0 && !maze.grid[col - 1][row].visited) { // left neighbor
      neighbors.add(maze.grid[col - 1][row]);
    }
    if (neighbors.size() > 0) {
      int r = floor(random(0, neighbors.size()));
      return neighbors.get(r);
    } else {
      return null;
    }
  }
}

enum Wall {
  NORTH,
  EAST,
  SOUTH,
  WEST;
}
