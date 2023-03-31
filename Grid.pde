import java.util.List;
import java.util.ArrayList;
import java.util.function.IntConsumer;

class Grid {
  private int[][] data;
  Environment environment;
  List<Coordinate> barrierLocations;
  List<Coordinate> barrierCenters;
  PGraphics gridDisplay;
  PGraphics challengeDisplay;
  boolean displayInitialized;

  Grid(Environment e) {
    environment = e;
    barrierLocations = new ArrayList<Coordinate>();
    barrierCenters = new ArrayList<Coordinate>();
    gridDisplay = createGraphics(width, height);
    challengeDisplay = createGraphics(width, height);
    displayInitialized = false;
  }

  Grid initialize(int w, int h) {
    data = new int[w][h];
    return this;
  }

  public Grid zeroFill() {
    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        data[i][j] = 0;
      }
    }
    return this;
  }

  public int getSizeX() {
    return data.length;
  }

  public int getSizeY() {
    return data[0].length;
  }

  public boolean isEmptyAt(Coordinate coord) {
    return GridState.EMPTY.getValue()==data[coord.getX()][coord.getY()];
  }

  public int at(Coordinate coord) {
    return data[coord.getX()][coord.getY()];
  }

  public void set(Coordinate location, int value) {
    data[location.getX()][location.getY()] = value;
  }

  public void set(Coordinate location, GridState gridState) {
    data[location.getX()][location.getY()] = gridState.getValue();
  }

  public Coordinate findEmptyLocation() {
    int maxX = data.length;
    int maxY = data[0].length;
    if ((Challenge)Parameters.CHALLENGE.getValue() == Challenge.MAZE || (Challenge)Parameters.CHALLENGE.getValue() == Challenge.MAZE_FEAR) {
      // Creature should randomize near the start
      //maxX /= 2;
      //maxY /=2;
      maxX = (int)(maxX/BarrierType.MAZE.getArg(0)) - 2;
      maxY = (int)(maxY/BarrierType.MAZE.getArg(1)) - 1;
    }
    Coordinate location = new Coordinate().randomize(maxX, maxY);
    return isEmptyAt(location)?location:findEmptyLocation();
  }
  public boolean isInBounds(Coordinate loc) {
    return loc.getX() >= 0 && loc.getX() < getSizeX() && loc.getY() >= 0 && loc.getY() < getSizeY();
  }

  public boolean isBarrierAt(Coordinate loc) {
    return at(loc) == GridState.BARRIER.getValue();
  }

  public boolean isOccupiedAt(Coordinate loc) {
    return at(loc) != GridState.EMPTY.getValue() && at(loc) != GridState.BARRIER.getValue();
  }

  private void drawBox(int[] xRange, int[] yRange) {
    for (int x = xRange[0]; x <= xRange[1]; x++) {
      for (int y = yRange[0]; y <= yRange[1]; y++) {
        Coordinate location = new Coordinate(x, y);
        set(location, GridState.BARRIER);
        barrierLocations.add(location);
      }
    }
  }

  public void display() {
    if (!toggleDisplay) return;
    if (displayInitialized) {
      if (toggleChallenge) {
        image(challengeDisplay, 0, 0);
      }
      image(gridDisplay, 0, 0);
      return;
    }

    gridDisplay.beginDraw();
    challengeDisplay.beginDraw();
    Challenge challenge = (Challenge)Parameters.CHALLENGE.getValue();
    int sizeX = (int)Configuration.SIZE_X.getValue();
    int sizeY = (int)Configuration.SIZE_Y.getValue();
    int size = (int)Configuration.AGENT_SIZE.getValue();
    for (int x = 0; x < data.length; x++) {
      for (int y = 0; y < data[x].length; y++) {
        Coordinate location = new Coordinate(x, y);
        // Calculate challenge space
        boolean showChallengeCell = false;
        color challengeCellColor = color(125);
        
        if (toggleChallenge) {
          switch(challenge) {
          case CORNER_WEIGHTED:
            {
              int[] cornersX = {0, sizeX-1};
              int[] cornersY = {0, sizeY-1};
              double radius = (double)sizeX*Challenge.CORNER_WEIGHTED.getParameter(0);

              for (int xx : cornersX) {
                for (int yy : cornersY) {
                  double distance = new Coordinate(xx, yy).subtract(location).length();
                  if (!showChallengeCell && distance <= radius) {
                    challengeCellColor = color(125, (int)(255*(1.0-distance/radius)));
                    showChallengeCell = true;
                  }
                }
              }
              break;
            }
          case CIRCLE_WEIGHTED:
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CIRCLE_WEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CIRCLE_WEIGHTED.getParameter(0)));
              double radius = sizeX*Challenge.CIRCLE_WEIGHTED.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              if (distance <= radius) {
                challengeCellColor = color(125, (int)(255*(1.0-distance/radius)));
                showChallengeCell = true;
              }
              break;
            }
          case CIRCLE_UNWEIGHTED:
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CIRCLE_UNWEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CIRCLE_UNWEIGHTED.getParameter(0)));
              double radius = sizeX*Challenge.CIRCLE_UNWEIGHTED.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              showChallengeCell = (distance <= radius);
              break;
            }
          case RIGHT_HALF:
            // Survivors are all those on the right side of the arena
            showChallengeCell = (location.getX() > sizeX*Challenge.RIGHT_HALF.getParameter(0));
            break;
          case RIGHT_QUARTER:
            // Survivors are all those on the right quarter of the arena
            showChallengeCell = (location.getX() > (sizeX*Challenge.RIGHT_QUARTER.getParameter(0)));
            break;
          case LEFT:
            // Survivors are all those on the left eighth of the arena (or however configured)
            showChallengeCell = (location.getX() < sizeX*Challenge.LEFT.getParameter(0));
            break;
          case STRING:
            // Survivors are those not touching the border and with exactly the number
            // of neighbors defined by neighbors and radius, where neighbors includes self
            {
              showChallengeCell = (!isBorder(location));
              break;
            }
          case CENTER_WEIGHTED:
            // Survivors are those within the specified radius of the center. The score
            // is linearly weighted by distance from the center.
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_WEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CENTER_WEIGHTED.getParameter(0)));
              double radius = sizeX*Challenge.CENTER_WEIGHTED.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              if (distance<=radius) {
                challengeCellColor = color(125, (int)(255*(1.0-distance/radius)));
                showChallengeCell = true;
              }
              break;
            }
          case CENTER_UNWEIGHTED:
            // Survivors are those within the specified radius of the center
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_UNWEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CENTER_UNWEIGHTED.getParameter(0)));
              double radius = sizeX*Challenge.CENTER_UNWEIGHTED.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              showChallengeCell = (distance<=radius) ;
              break;
            }
          case CORNER:
            // Survivors are those within the specified radius of any corner.
            // Assumes square arena.
            {
            assert sizeX == sizeY :
              String.format("Grid is not square (%d, %d)", sizeX, sizeY );
              int[] cornersX = {0, sizeX-1};
              int[] cornersY = {0, sizeY-1};
              double radius = (double)sizeX*Challenge.CORNER.getParameter(0);

              for (int xx : cornersX) {
                for (int yy : cornersY) {
                  double distance = new Coordinate(xx, yy).subtract(location).length();
                  if (!showChallengeCell && distance <= radius) {
                    showChallengeCell = true;
                  }
                }
              }
              break;
            }
          case MIGRATE_DISTANCE:
            // Everybody survives and are candidate parents, but scored by how far
            // they migrated from their birth location.
            break;
          case CENTER_SPARSE:
            // Survivors are those within the specified outer radius of the center and with
            // the specified number of neighbors in the specified inner radius.
            // For the grid visualization we will just show the center circle, unweighted
            // The score is not weighted by distance from the center.
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_SPARSE.getParameter(0)), (int)(sizeY*Challenge.CENTER_SPARSE.getParameter(0)));
              double outerRadius = sizeX*Challenge.CENTER_SPARSE.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              showChallengeCell = (distance <= outerRadius);
              break;
            }
          case RADIOACTIVE_WALLS:
            {
              // This challenge is handled in endOfSimStep(), where individuals may die
              // at the end of any sim step. There is nothing else to do here at the
              // end of a generation. All remaining alive become parents.
              int radioactiveX = (simStep < (int)Parameters.STEPS_PER_GENERATION.getValue() * Challenge.RADIOACTIVE_WALLS.getParameter(0)) ? 0 : (int)Configuration.SIZE_X.getValue() - 1;

              int distanceFromRadioactiveWall = Math.abs(location.getX() - radioactiveX);
              if (distanceFromRadioactiveWall < (int)Configuration.SIZE_X.getValue() *Challenge.RADIOACTIVE_WALLS.getParameter(1)) {
                double dropoff = 1.0 / distanceFromRadioactiveWall;
                challengeCellColor = color(200, 10, 10, (int)(255.0*dropoff));
                showChallengeCell = true;
              }

              break;
            }
          case TOUCH_ANY_WALL:
            // This challenge is partially handled in endOfSimStep(), where individuals
            // that are touching a wall are flagged in their Creature record. They are
            // allowed to continue living. Here at the end of the generation, any that
            // never touch a wall will die. All that touched a wall at any time during
            // their life will become parents.
          case AGAINST_ANY_WALL:
            // Survivors are those touching any wall at the end of the generation

            showChallengeCell = (isBorder(location));
            break;
          case EAST_WEST:
            // Survivors are all those on the left or right eighths of the arena (or whatever the config says)
            showChallengeCell = ( location.getX() < (int)(sizeX*Challenge.EAST_WEST.getParameter(0)) || location.getX() >= (sizeX - (int)(sizeX*Challenge.EAST_WEST.getParameter(0))));
            break;
          case NEAR_BARRIER:
            // Survivors are those within radius of any barrier center. Weighted by distance.
            // TODO check the rest of these
            {
              double radius = sizeX * Challenge.NEAR_BARRIER.getParameter(0);
              double minDistance = 1e8;

              for (Coordinate center : barrierCenters) {
                double distance = location.subtract(center).length();
                if (distance < minDistance) minDistance = distance;
              }

              if (minDistance <= radius) {
                challengeCellColor = color(125, (int)(255*(1.0-minDistance/radius)));
                showChallengeCell = true;
              }
              break;
            }
          case PAIRS:
            // Survivors are those not touching a border and with exactly one neighbor which has no other neighbor
            {
              showChallengeCell = (!isBorder(location));
              break;
            }
          case LOCATION_SEQUENCE:
            // Survivors are those that contacted one or more specified locations in a sequence,
            // ranked by the number of locations contacted. There will be a bit set in their
            // challengeBits member for each location contacted.
            {
              break;
            }
          case ALTRUISM:
            // Survivors are those inside the circular area defined by
            // safeCenter and radius
            {
              Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.ALTRUISM.getParameter(0)), (int)(sizeY*Challenge.ALTRUISM.getParameter(0)));
              double radius = sizeX*Challenge.ALTRUISM.getParameter(1);

              Coordinate offset = safeCenter.subtract(location);
              double distance = offset.length();
              if (distance<=radius) {
                challengeCellColor = color(125, (int)(255*(1.0-distance/radius)));
                showChallengeCell = true;
              }
              break;
            }
          case ALTRUISM_SACRIFICE:
            // Survivors are all those within the specified radius of the NE corner
            {
              double radius = sizeX*Challenge.ALTRUISM_SACRIFICE.getParameter(0);

              double distance = new Coordinate((int)(sizeX - radius), (int)(sizeY - radius)).subtract(location).length();
              if (distance <= radius) {
                challengeCellColor = color(125, (int)(255*(1.0-distance/radius)));
                showChallengeCell = true;
              }
              break;
            }
          case MAZE_FEAR:
            {
              double radius = Challenge.MAZE_FEAR.getParameter(2);
              int cols = (int)BarrierType.MAZE.getArg(0);
              int rows = (int)BarrierType.MAZE.getArg(1);
              MazeCell endCell = MazeInstance.getInstance().getEnd();

              int cellWidth = sizeX/cols;
              int cellHeight = sizeY/rows;
              int yMin = (rows - 1) * cellHeight;
              int yMax = rows * cellHeight;
              int xMin = endCell.getCol() * cellWidth;
              int xMax = xMin + cellWidth;

              if (location.getY() >= yMin && location.getY() < yMax && location.getX() >= xMin && location.getX() < xMax) {
                // This is an end cell
                showChallengeCell = true;
              } else if (location.getX() > cellWidth && location.getY() > cellHeight) {
                // This is the portion of the map not in the start cell

                Coordinate endCoord = new Coordinate(sizeX-1, sizeY-1);
                double locationDist = location.subtract(endCoord).length();
                double maxDistance = new Coordinate(0, 0).subtract(endCoord).length();
                double locDistanceDiff = maxDistance - locationDist;

                // Check if this location is near a border
                double []minDistance = {radius+1.0};
                Consumer<Coordinate> f = (tloc) -> {
                  if (isBarrierAt(tloc)) {
                    double distance = location.subtract(tloc).length();
                    minDistance[0] = (distance < minDistance[0])? distance : minDistance[0];
                  }
                };
                location.visitNeighborhood(radius, f);
                if (minDistance[0] <= radius) {
                  // they are within radius of a wall, this is bad.  No dropoff, just bad
                  challengeCellColor = color(200, 10, 10, 255);
                } else {
                  // this location is not near a border, show how close to the end it might be
                  challengeCellColor = color(125, (int)(255.0 * (locDistanceDiff/maxDistance)));
                }
                showChallengeCell = true;
              }

              break;
            }
          case MAZE:
            {
              // TODO when a new maze is loaded using the loadBarriers method, make sure to also populate the maze
              int cols = (int)BarrierType.MAZE.getArg(0);
              int rows = (int)BarrierType.MAZE.getArg(1);
              MazeCell endCell = MazeInstance.getInstance().getEnd();

              int cellWidth = sizeX/cols;
              int cellHeight = sizeY/rows;
              int yMin = (rows - 1) * cellHeight;
              int yMax = rows * cellHeight;
              int xMin = endCell.getCol() * cellWidth;
              int xMax = xMin + cellWidth;
              // Show an end cell

              //showChallengeCell = (location.getY() >= yMin && location.getY() < yMax && location.getX() >= xMin && location.getX() < xMax);

              if (location.getY() >= yMin && location.getY() < yMax && location.getX() >= xMin && location.getX() < xMax) {
                // Are they in the end?
                showChallengeCell = true;
              } else if (location.getX() > cellWidth && location.getY() > cellHeight) {
                // Have they moved away from the start and are close to the end?
                Coordinate endCoord = new Coordinate(sizeX-1, sizeY-1);
                double locationDist = location.subtract(endCoord).length();
                double maxDistance = new Coordinate(0, 0).subtract(endCoord).length();
                double locDistanceDiff = maxDistance - locationDist;
                challengeCellColor = color(125, (int)(255.0 * (locDistanceDiff/maxDistance))

                  //(Math.max(sizeX, sizeY)-location.subtract(new Coordinate(sizeX-1, sizeY-1)).length()/Math.max(sizeX, sizeY))
                  );
                showChallengeCell = true;
              }
              break;
            }
          default:
            break;
          }

          if (showChallengeCell) {
            challengeDisplay.noStroke();
            challengeDisplay.fill(challengeCellColor);
            challengeDisplay.rect(location.getX()*size, location.getY()*size, size, size);
          }
        }
        if (isBarrierAt(location)) {
          gridDisplay.noStroke();
          gridDisplay.fill(255);
          gridDisplay.rect(location.getX()*size, location.getY()*size, size, size);
        }
      }
    }
    gridDisplay.endDraw();
    challengeDisplay.endDraw();
    image(challengeDisplay, 0, 0);
    image(gridDisplay, 0, 0);

    displayInitialized = true;
  }

  public void createBarrier() {
    BarrierType barrierType = (BarrierType)Parameters.BARRIER_TYPE.getValue();
    barrierLocations.clear();
    barrierCenters.clear();  // Used only for some barrier types

    int sizeX = (int)Configuration.SIZE_X.getValue();
    int sizeY = (int)Configuration.SIZE_Y.getValue();
    double xFactor = (barrierType.hasArgs()) ? barrierType.getArg(0) : 0;
    double yFactor = (barrierType.hasArgs()) ? barrierType.getArg(1) : 0;
    switch(barrierType) {
    case NONE:
      // code for no barrier
      break;
    case VERTICAL_BAR_CONSTANT:
      {
        // code for vertical bar with constant factors
        int minX = (int)(sizeX*xFactor);
        int maxX = minX+1;
        int minY = (int)(sizeY*yFactor);
        int maxY = minY+sizeY/2;
        for (int x = minX; x<=maxX; x++) {
          for (int y = minY; y <=maxY; y++) {
            Coordinate location = new Coordinate(x, y);
            set(location, GridState.BARRIER);
            barrierLocations.add(location);
          }
        }
        break;
      }
    case VERTICAL_BAR_RANDOM:
      {
        int minX = (int)(new Random().nextDouble()*sizeX*xFactor);
        int maxX = minX+1;
        int minY = (int)(new Random().nextDouble()*sizeY/2*yFactor);
        int maxY = minY+sizeY/2;

        // code for vertical bar with random factors
        for (int x = minX; x<=maxX; x++) {
          for (int y = minY; y <=maxY; y++) {
            Coordinate location = new Coordinate(x, y);
            set(location, GridState.BARRIER);
            barrierLocations.add(location);
          }
        }
        break;
      }
    case FIVE_BLOCKS_STAGGERED:
      {
        // code for staggered five-blocks barrier
        int blockSizeX = (int)xFactor;
        int blockSizeY = (int)(sizeX*yFactor);

        int x0 = sizeX / 4 - blockSizeX / 2;
        int y0 = sizeY / 4 - blockSizeY / 2;
        int x1 = x0 + blockSizeX;
        int y1 = y0 + blockSizeY;

        drawBox(new int[]{x0, x1}, new int[]{y0, y1});
        x0 += sizeX / 2;
        x1 = x0 + blockSizeX;
        drawBox(new int[]{x0, x1}, new int[]{y0, y1});
        y0 += sizeY / 2;
        y1 = y0 + blockSizeY;
        drawBox(new int[]{x0, x1}, new int[]{y0, y1});
        x0 -= sizeX / 2;
        x1 = x0 + blockSizeX;
        drawBox(new int[]{x0, x1}, new int[]{y0, y1});
        x0 = sizeX / 2 - blockSizeX / 2;
        x1 = x0 + blockSizeX;
        y0 = sizeY / 2 - blockSizeY / 2;
        y1 = y0 + blockSizeY;
        drawBox(new int[]{x0, x1}, new int[]{y0, y1});

        break;
      }
    case HORIZONTAL_BAR_CONSTANT:
      {
        // code for horizontal bar with constant factors
        int minX = (int)(sizeX*xFactor);
        int maxX = minX+sizeX/2;
        int minY = (int)(sizeY*yFactor);
        int maxY = minY+2;

        // code for vertical bar with random factors
        for (int x = minX; x<=maxX; x++) {
          for (int y = minY; y <=maxY; y++) {
            Coordinate location = new Coordinate(x, y);
            set(location, GridState.BARRIER);
            barrierLocations.add(location);
          }
        }

        break;
      }
    case FLOATING_ISLANDS_RANDOM:
      {
        // code for floating islands with random margin and radius
        double radius = xFactor;
        double margin = (yFactor * radius);

        Coordinate center0 = new Coordinate().randomize(sizeX, sizeY);
        Coordinate center1;
        Coordinate center2;

        do {
          center1 = new Coordinate().randomize(sizeX, sizeY);
        } while ((center0.subtract(center1)).length() < margin);

        do {
          center2 = new Coordinate().randomize(sizeX, sizeY);
        } while ((center0.subtract(center2)).length() < margin || (center1.subtract(center2)).length() < margin);

        barrierCenters.add(center0);
        //barrierCenters.add(center1);
        //barrierCenters.add(center2);

        Consumer<Coordinate> f = loc -> {
          set(loc, GridState.BARRIER);
          barrierLocations.add(loc);
        };

        center0.visitNeighborhood(radius, f);

        break;
      }
    case SPOTS:
      {
        // code for spots barrier with a given number of locations and radius
        {
          int numberOfLocations = (int)xFactor;
          double radius = yFactor;

          Consumer<Coordinate> f = loc -> {
            set(loc, GridState.BARRIER);
            barrierLocations.add(loc);
          };

          int verticalSliceSize = sizeY / (numberOfLocations + 1);

          for (int n = 1; n <= numberOfLocations; ++n) {
            Coordinate loc = new Coordinate(sizeX / 2, n * verticalSliceSize);
            loc.visitNeighborhood(radius, f);
            barrierCenters.add(loc);
          }
        }

        break;
      }
    case MAZE:
      {
        int cols = (int)xFactor;
        int rows = (int)yFactor;
        int cellWidth = sizeX / cols;
        int cellHeight = sizeY / rows;
        /*
        Build the maze and create barriers according to the maze information
         */
        Maze maze = MazeInstance.getInstance(NeuronGames.this, cols, rows);
        for (int i = 0; i < maze.getCols(); i++) {
          for (int j = 0; j < maze.getRows(); j++) {
            MazeCell cell = maze.getCell(i, j);

            if (cell.getWall(Wall.NORTH)) {
              //line(i * cellWidth, j * cellHeight, (i+1) * cellWidth, j * cellHeight);
              for (int x = i * cellWidth; x < i * cellWidth + cellWidth; x++) {
                Coordinate location = new Coordinate(x, j*cellHeight);
                set(location, GridState.BARRIER);
                barrierLocations.add(location);
              }
            }
            if (cell.getWall(Wall.SOUTH)) {
              //line(i * cellWidth, (j+1) * cellHeight, (i+1) * cellWidth, (j+1) * cellHeight);
              for (int x = i * cellWidth; x < i * cellWidth + cellWidth; x++) {
                Coordinate location = new Coordinate(x, j*cellHeight + cellHeight-1);
                set(location, GridState.BARRIER);
                barrierLocations.add(location);
              }
            }
            if (cell.getWall(Wall.WEST)) {
              //line(i * cellWidth, j * cellHeight, i * cellWidth, (j+1) * cellHeight);
              for (int y = j * cellHeight; y < j * cellHeight + cellHeight; y++) {
                Coordinate location = new Coordinate(i*cellWidth, y);
                set(location, GridState.BARRIER);
                barrierLocations.add(location);
              }
            }
            if (cell.getWall(Wall.EAST)) {
              //line((i+1) * cellWidth, j * cellHeight, (i+1) * cellWidth, (j+1) * cellHeight);
              for (int y = j * cellHeight; y < j * cellHeight + cellHeight; y++) {
                Coordinate location = new Coordinate(i*cellWidth+cellWidth-1, y);
                set(location, GridState.BARRIER);
                barrierLocations.add(location);
              }
            }
          }
        }

        break;
      }

    default:
      throw new IllegalArgumentException("Unknown barrier type: " + barrierType);
    }
  }

  // Returns the number of locations to the next agent in the specified
  // direction, not including loc. If the probe encounters a boundary or a
  // barrier before reaching the longProbeDist distance, returns longProbeDist.
  // Returns 0..longProbeDist.
  public int longProbePopulationFwd(Coordinate location, Direction dir, int longProbeDist)
  {
  assert longProbeDist > 0 :
    longProbeDist;

    int count = 0;
    Coordinate loc = location.add(dir);
    int numLocsToTest = longProbeDist;
    while (numLocsToTest > 0 && isInBounds(loc) && isEmptyAt(loc)) {
      ++count;
      loc = loc.add(dir);
      --numLocsToTest;
    }
    if (numLocsToTest > 0 && (!isInBounds(loc) || isBarrierAt(loc))) {
      return longProbeDist;
    }
    return count;
  }

  // Returns the number of locations to the next barrier in the
  // specified direction, not including loc. Ignores agents in the way.
  // If the distance to the border is less than the longProbeDist distance
  // and no barriers are found, returns longProbeDist.
  // Returns 0..longProbeDist.
  public int longProbeBarrierFwd(Coordinate location, Direction dir, int longProbeDist)
  {
  assert longProbeDist > 0 :
    longProbeDist;
    int count = 0;
    Coordinate loc = location.add(dir);
    int numLocsToTest = longProbeDist;
    while (numLocsToTest > 0 && isInBounds(loc) && !isBarrierAt(loc)) {
      ++count;
      loc = loc.add(dir);
      --numLocsToTest;
    }
    if (numLocsToTest > 0 && !isInBounds(loc)) {
      return longProbeDist;
    }

    return count;
  }

  public boolean isBorder(Coordinate loc) {
    return
      loc.getX() == 0 || loc.getX() == (int)Configuration.SIZE_X.getValue() - 1 ||
      loc.getY() == 0 || loc.getY() == (int)Configuration.SIZE_Y.getValue() - 1;
  }

  /**
   * Loads barriers, good for mazes, to the current grid.
   * Note: This does not care about creatures that are currently loaded (yet),
   *       so it's good to reset creatures to a saved set of creatures if loading barriers
   * Note: This will also probably fail if the barriers are bigger than the current grid
   */
  public boolean loadBarriers(String filename) {
    String[] barrierData = loadStrings(filename);
    for (int y = 0; y < barrierData.length; y++) {
      byte[] entries = barrierData[y].getBytes();
      for (int x = 0; x < entries.length; x++) {
        Coordinate location = new Coordinate(x, y);
        char value = (char)entries[x];
        if (isOccupiedAt(location)) {
          // TODO there is a creature in this spot, make sure to kill it properly before just overwriting the value
          // pseudo: tell environment that this creature is now gone
        }
        set(location, (value == '1')?GridState.BARRIER:GridState.EMPTY);
      }
    }
    return true;
  }

  public boolean saveBarrierState() {
    String fileName = String.format("barriers-%1$tF-%1$ts.bin", Calendar.getInstance());
    System.out.printf("Saving barrier state to %s...", fileName);
    PrintWriter output = createWriter(fileName);

    // We have a maze, just need to save the barriers
    for (int y = 0; y < data[0].length; y++) {
      StringBuffer line = new StringBuffer();
      for (int x = 0; x < data.length; x++) {
        Coordinate gridLocation = new Coordinate(x, y);
        line.append( isBarrierAt(gridLocation)?'1':'0');
      }
      output.println(line);
    }

    output.flush();
    output.close();
    System.out.println("...done");
    return true;
  }

  /**
   Converts the population along the specified axis to the sensor range. The
   locations of neighbors are scaled by the inverse of their distance times
   the positive absolute cosine of the difference of their angle and the
   specified axis. The maximum positive or negative magnitude of the sum is
   about 2*radius. We don't adjust for being close to a border, so populations
   along borders and in corners are commonly sparser than away from borders.
   An empty neighborhood results in a sensor value exactly midrange; below
   midrange if the population density is greatest in the reverse direction,
   above midrange if density is greatest in forward direction.
   */
  public double getPopulationDensityAlongAxis(Coordinate loc, Direction dir) {
    assert !dir.equals(new Direction(Compass.CENTER)) :
    String.format("Direction is CENTER:%s", dir); // require a defined axis

    double sensorRadius = (double)Parameters.POPULATION_SENSOR_RADIUS.getValue();
    final double[] sum = {0.0};
    Coordinate dirVec = dir.asNormalizedCoordinate();
    double len = Math.sqrt(dirVec.getX() * dirVec.getX() + dirVec.getY() * dirVec.getY());
    double dirVecX = dirVec.getX() / len;
    double dirVecY = dirVec.getY() / len; // Unit vector components along dir

    Consumer<Coordinate> f = tloc -> {
      if (!tloc.equals(loc) && isOccupiedAt(tloc)) {
        Coordinate offset = tloc.subtract(loc);
        double proj = dirVecX * offset.getX() + dirVecY * offset.getY(); // Magnitude of projection along dir
        double contrib = proj / (offset.getX() * offset.getX() + offset.getY() * offset.getY());
        sum[0] += contrib;
      }
    };

    loc.visitNeighborhood(sensorRadius, f);

    double maxSumMag = 6.0 * sensorRadius;
  assert sum[0] >= -maxSumMag && sum[0] <= maxSumMag :
    String.format("Sum of projections too big:%f", sum[0]);

    double sensorVal = sum[0] / maxSumMag; // convert to -1.0..1.0
    sensorVal = (sensorVal + 1.0) / 2.0; // convert to 0.0..1.0

    return sensorVal;
  }

  // Converts the number of locations (not including loc) to the next barrier location
  // along opposite directions of the specified axis to the sensor range. If no barriers
  // are found, the result is sensor mid-range. Ignores agents in the path.
  public double getShortProbeBarrierDistance(Coordinate loc0, Direction dir, int probeDistance) {
    int countFwd = 0;
    int countRev = 0;
    Coordinate loc = loc0.add(dir);

    int numLocsToTest = probeDistance;

    // Scan positive direction
    while (numLocsToTest > 0 && isInBounds(loc) && !isBarrierAt(loc)) {
      ++countFwd;
      loc = loc.add(dir);
      --numLocsToTest;
    }

    if (numLocsToTest > 0 && !isInBounds(loc)) {
      countFwd = probeDistance;
    }

    // Scan negative direction
    numLocsToTest = probeDistance;
    loc = loc0.subtract(dir);

    while (numLocsToTest > 0 && isInBounds(loc) && !isBarrierAt(loc)) {
      ++countRev;
      loc = loc.subtract(dir);
      --numLocsToTest;
    }

    if (numLocsToTest > 0 && !isInBounds(loc)) {
      countRev = probeDistance;
    }

    double sensorVal = ((countFwd - countRev) + probeDistance); // convert to 0..2*probeDistance
    sensorVal = (sensorVal / 2.0) / probeDistance; // convert to 0.0..1.0

    return sensorVal;
  }
}

enum GridState {
  EMPTY(0),
    BARRIER(Integer.MAX_VALUE);

  private int value;

  GridState(int value) {
    this.value = value;
  }

  public GridState findByValue(int value) {
    for (GridState item : GridState.values()) {
      if (item.value == value) return item;
    }
    return null;
  }

  public int getValue() {
    return value;
  }
}
