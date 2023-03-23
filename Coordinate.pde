import java.util.Random;
import java.util.function.Consumer;

class Coordinate {
  private int x, y;
  private final int gridWidth=(int)Parameters.SIZE_X.getValue();
  private final int gridHeight = (int)Parameters.SIZE_Y.getValue();
  private final BoundaryType boundaryType = (BoundaryType)Parameters.BOUNDARY_TYPE.getValue();

  Coordinate(int x, int y) {
    this.x = x;
    this.y = y;
    // check if the environment is infinite
    // if so, then just automatically update the coodinate to be "inBounds"
    // TODO this doesn't work, sometimes we use Coordinate to keep track of normalized coordinates (-1, 0) as an example
    //if (BoundaryType.INFINITE == boundaryType) {
    //  if (this.x < 0) this.x =gridWidth+this.x;
    //  if (this.x >= gridWidth) this.x = gridWidth-this.x;
    //  if (this.y < 0) this.y =gridHeight+this.y;
    //  if (this.y >= gridHeight) this.y = gridHeight-this.y;
    //}
  }

  // for testing
  Coordinate() {
  }

  public Coordinate clone() {
    return new Coordinate(x, y);
  }

  @Override
    public boolean equals(Object obj) {
    if (obj == this) return true;
    if (!(obj instanceof Coordinate)) return false;
    Coordinate other = (Coordinate) obj;
    return this.x == other.x && this.y == other.y;
  }

  public int length() {
    return (int)Math.sqrt(x*x + y*y);
  }

  public int getX() {
    return this.x;
  }

  public int getY() {
    return this.y;
  }

  public Coordinate add(Direction right) {
    return add(right.asNormalizedCoordinate());
  }

  public Coordinate add(Coordinate right) {
    return new Coordinate(this.x + right.getX(), this.y + right.getY());
  }

  public Coordinate subtract(Coordinate right) {
    return new Coordinate(this.x - right.getX(), this.y - right.getY());
  }

  public Coordinate subtract(Direction right) {
    return subtract(right.asNormalizedCoordinate());
  }

  public Coordinate randomize(int maxWidth, int maxHeight) {
    this.x = new Random().ints(1, 0, maxWidth).toArray()[0];
    this.y = new Random().ints(1, 0, maxHeight).toArray()[0];
    return this;
  }

  // This is a utility function used when inspecting a local neighborhood around
  // some location. This function feeds each valid (in-bounds) location in the specified
  // neighborhood to the specified function. Locations include self (center of the neighborhood).
  public void visitNeighborhood(final double radius, Consumer<Coordinate> f) {
    int xBound[] = new int[]{
      -(int)((boundaryType == BoundaryType.INFINITE)?radius:Math.min((int)radius, getX())),
      (int)((boundaryType == BoundaryType.INFINITE)?radius:Math.min((int)radius, (gridWidth - getX()) - 1))
    };
    for (int dx = xBound[0]; dx <= xBound[1]; ++dx) {
      int x = getX() + dx;
      int extentY = (int)Math.sqrt(radius * radius - dx * dx);
      int yBound[] = new int[]{
        -(int)((boundaryType == BoundaryType.INFINITE)?extentY:Math.min(extentY, getY())),
        (int)((boundaryType == BoundaryType.INFINITE)?extentY:Math.min(extentY, (gridHeight - getY())-1))
      };
      for (int dy = yBound[0]; dy <= yBound[1]; ++dy) {
        int y = getY() + dy;
        //assert y >= 0 && y < gridHeight :
        //  y;
        
        // TODO if x,y are negative, need to first adjust if BoundaryType.INFINITE, can't rely on the constructor
        f.accept(new Coordinate(x, y));
      }
    }
  }

  public String toString() {
    return String.format("(%s,%s)", x, y);
  }

  public Coordinate testAll() {
    if (BoundaryType.BOUNDED == (BoundaryType)Parameters.BOUNDARY_TYPE.getValue()) {
      System.out.println("testNeighborhoodInBoundary");
      testNeighborhoodInBoundary();
      System.out.println("testNeighborhoodOnBoundary");
      testNeighborhoodOnBoundary();
    } else {
      System.out.println("testNeighborhoodInBoundaryINF");
      testNeighborhoodInBoundaryINF();
      System.out.println("testNeighborhoodOnBoundaryINF");
      testNeighborhoodOnBoundaryINF();
    }
    return this;
  }

  public void testNeighborhoodInBoundary() {
    Coordinate c = new Coordinate(2, 2);
    List<Coordinate> visitedLocations = new ArrayList<Coordinate>();
    Consumer<Coordinate> f = loc -> {
      visitedLocations.add(loc);
    };
    c.visitNeighborhood(2, f);
    Coordinate[] assertLocations = new Coordinate[]{
      new Coordinate(0, 2),
      new Coordinate(1, 1),
      new Coordinate(1, 2),
      new Coordinate(1, 3),
      new Coordinate(2, 0),
      new Coordinate(2, 1),
      new Coordinate(2, 2),
      new Coordinate(2, 3),
      new Coordinate(2, 4),
      new Coordinate(3, 1),
      new Coordinate(3, 2),
      new Coordinate(3, 3),
      new Coordinate(4, 2)
    };
    assertLocations(assertLocations, visitedLocations);
  }

  private void assertLocations(Coordinate[] expected, List<Coordinate> calculated) {
    assert !calculated.isEmpty();
    for (int i = 0; i < expected.length; i++) {
      assert expected[i].equals(calculated.get(i)) :
      String.format("expected:%s, got:%s", expected[i], calculated.get(i));
    }
  }
  public void testNeighborhoodOnBoundary() {
    Coordinate c = new Coordinate(0, 0);
    List<Coordinate> visitedLocations = new ArrayList<Coordinate>();
    Consumer<Coordinate> f = loc -> {
      visitedLocations.add(loc);
    };
    c.visitNeighborhood(2, f);
    Coordinate[] assertLocations = new Coordinate[]{
      new Coordinate(0, 0),
      new Coordinate(0, 1),
      new Coordinate(0, 2),
      new Coordinate(1, 0),
      new Coordinate(1, 1),
      new Coordinate(2, 0)
    };
    assertLocations(assertLocations, visitedLocations);
  }
  public void testNeighborhoodInBoundaryINF() {
    List<Coordinate> visitedLocations = new ArrayList<Coordinate>();
    Coordinate c = new Coordinate(2, 2);
    Consumer<Coordinate> f = loc -> {
      visitedLocations.add(loc);
    };
    c.visitNeighborhood(2, f);
    Coordinate[] assertLocations = new Coordinate[]{
      new Coordinate(0, 2),
      new Coordinate(1, 1),
      new Coordinate(1, 2),
      new Coordinate(1, 3),
      new Coordinate(2, 0),
      new Coordinate(2, 1),
      new Coordinate(2, 2),
      new Coordinate(2, 3),
      new Coordinate(2, 4),
      new Coordinate(3, 1),
      new Coordinate(3, 2),
      new Coordinate(3, 3),
      new Coordinate(4, 2)
    };
    assertLocations(assertLocations, visitedLocations);
  }
  public  void testNeighborhoodOnBoundaryINF() {
    List<Coordinate> visitedLocations = new ArrayList<Coordinate>();
    Coordinate c = new Coordinate(0, 0);
    Consumer<Coordinate> f = loc -> {
      visitedLocations.add(loc);
    };
    c.visitNeighborhood(2, f);
    Coordinate[] assertLocations = new Coordinate[]{
      new Coordinate(3, 0),
      new Coordinate(4, 4),
      new Coordinate(4, 0),
      new Coordinate(4, 1),
      new Coordinate(0, 3),
      new Coordinate(0, 4),
      new Coordinate(0, 0),
      new Coordinate(0, 1),
      new Coordinate(0, 2),
      new Coordinate(1, 4),
      new Coordinate(1, 0),
      new Coordinate(1, 1),
      new Coordinate(2, 0)
    };
    assertLocations(assertLocations, visitedLocations);
  }
}
