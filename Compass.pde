enum Compass {
  SOUTHWEST("SW",  3, 1, -1, -1),
    SOUTH("S", 0, 2, 0, -1),
    SOUTHEAST("SE",  1, 5, 1, -1),
    WEST("W", 6, 0, -1, 0),
    CENTER("C", 4, 4, 0, 0),
    EAST("E", 2, 8, 1, 0),
    NORTHWEST("NW", 7, 3, -1, -1),
    NORTH("N", 8, 6, 0, 1),
    NORTHEAST("NE", 5, 7, 1, 1);

  private final String acronym;
  private final int right;
  private final int left;
  private final int x;
  private final int y;

  Compass(String acronym, int right, int left, int x, int y) {
    this.acronym = acronym;
    this.right = right;
    this.left = left;
    this.x = x;
    this.y = y;
  }

  Compass findByAcronynm(String acronym) {
    for (Compass c : Compass.values()) {
      if (c.acronym == acronym) return c;
    }
    return null;
  }

  Compass CW() {
    return values()[right];
  }

  Compass CCW() {
    return values()[left];
  }

  int[] normalized() {
    return new int[]{x, y};
  }
}
