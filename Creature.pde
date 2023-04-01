import java.util.EnumSet;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;

class Creature {
  private int index;
  private Coordinate location;
  private Coordinate birthLocation;
  private Genome genome;
  private boolean alive;
  private int size;
  private int age;
  private int oscPeriod; // 2..4*p.stepsPerGeneration (TBD, see executeActions())
  private int longProbeDistance; // This should be set at the main level
  private int challengeBits;
  private double responsiveness;
  private Direction lastMoveDirection;
  private NeuralNet brain;
  private Grid grid;
  private Environment environment;

  Creature(int index, Coordinate location, Genome genome, Environment environment) {
    this.environment = environment;

    this.age = 0;
    this.challengeBits = 0;
    this.alive = true;
    this.index = index;
    this.location = location.clone();
    this.birthLocation = location.clone();
    this.grid = environment.getGrid();
    this.lastMoveDirection = randomAxis();
    this.responsiveness = (double)Parameters.RESPONSIVENESS.getValue();
    this.oscPeriod = (int)Parameters.OSC_PERIOD.getValue();
    this.longProbeDistance = (int)Parameters.LONG_PROBE_DISTANCE.getValue();
    this.size = (int)Configuration.AGENT_SIZE.getValue();

    initializeBrain(genome);
  }

  private void initializeBrain(Genome genome) {
    this.genome = genome;
    this.brain = new NeuralNet(this);
  }

  private Direction randomAxis() {
    Random rand = new Random();
    Direction d = new Direction(Compass.values()[rand.nextInt(Compass.values().length)]);
    if (d.direction == Compass.CENTER) d = randomAxis();
    return d;
  }
  public int getChallengeBits() {
    return challengeBits;
  }

  public void addChallengeBit(int b) {
    challengeBits |= b;
  }

  public void setChallengeBits(int b) {
    challengeBits = b;
  }

  public int getLongProbeDistance() {
    return longProbeDistance;
  }

  public NeuralNet getBrain() {
    return brain;
  }

  public int getAge() {
    return age;
  }

  public Genome getGenome() {
    return genome;
  }

  public boolean isAlive() {
    return alive;
  }

  public void setAlive(boolean alive) {
    this.alive = alive;
  }

  public int getIndex() {
    return index;
  }

  public int getOscPeriod() {
    return oscPeriod;
  }

  public Coordinate getLocation() {
    return location;
  }

  public void setLocation(Coordinate newLocation) {
    location = newLocation;
  }

  public void setLastMoveDirection(Direction direction) {
    this.lastMoveDirection = direction;
  }

  public Direction getLastMoveDirection() {
    return lastMoveDirection;
  }

  void executeActions(double[] actionLevels) {

    // Responsiveness action - convert neuron action level from arbitrary double range
    // to the range 0.0..1.0. If this action neuron is enabled but not driven, will
    // default to mid-level 0.5.
    if (CreatureAction.SET_RESPONSIVENESS.isEnabled()) {
      double level = actionLevels[CreatureAction.SET_RESPONSIVENESS.ordinal()]; // default 0.0
      level = (Math.tanh(level) + 1.0) / 2.0; // convert to 0.0..1.0
      responsiveness = level;
    }

    // For the rest of the action outputs, we'll apply an adjusted responsiveness
    // factor (see responseCurve() for more info). Range 0.0..1.0.
    double responsivenessAdjusted = responseCurve(responsiveness);

    // Oscillator period action - convert action level nonlinearly to
    // 2..4*p.stepsPerGeneration. If this action neuron is enabled but not driven,
    // will default to 1.5 + e^(3.5) = a period of 34 simSteps.
    if (CreatureAction.SET_OSCILLATOR_PERIOD.isEnabled()) {
      double periodf = actionLevels[CreatureAction.SET_OSCILLATOR_PERIOD.ordinal()];
      double newPeriodf01 = (double) ((Math.tanh(periodf) + 1.0) / 2.0); // convert to 0.0..1.0
      int newPeriod = 1 + (int)(1.5 + Math.exp(7.0 * newPeriodf01));
    assert newPeriod >= 2 && newPeriod <= 2048 :
      newPeriod;
      oscPeriod = newPeriod;
    }

    // Set longProbeDistance - convert action level to 1..maxLongProbeDistance.
    // If this action neuron is enabled but not driven, will default to
    // mid-level period of 17 simSteps.
    if (CreatureAction.SET_LONGPROBE_DIST.isEnabled()) {
      final int maxLongProbeDistance = 32;
      double level = actionLevels[CreatureAction.SET_LONGPROBE_DIST.ordinal()];
      level = (Math.tanh(level) + 1.0d) / 2.0d; // convert to 0.0..1.0
      level = 1 + level * maxLongProbeDistance;
      longProbeDistance = (int) level;
    }

    // Emit signal0 - if this action value is below a threshold, nothing emitted.
    // Otherwise convert the action value to a probability of emitting one unit of
    // signal (pheromone).
    // Pheromones may be emitted immediately (see signals.cpp). If this action neuron
    // is enabled but not driven, nothing will be emitted.
    if (CreatureAction.EMIT_SIGNAL0.isEnabled()) {
      final double emitThreshold = 0.5;  // 0.0..1.0; 0.5 is midlevel
      double level = actionLevels[CreatureAction.EMIT_SIGNAL0.ordinal()];
      level = (Math.tanh(level) + 1.0) / 2.0; // convert to 0.0..1.0
      level *= responsivenessAdjusted;
      if (level > emitThreshold && prob2bool(level)) {
        environment.signals.increment(0, location);
      }
    }

    // Kill forward -- if this action value is > threshold, value is converted to probability
    // of an attempted murder. Probabilities under the threshold are considered 0.0.
    // If this action neuron is enabled but not driven, the neighbors are safe.
    if (CreatureAction.KILL_FORWARD.isEnabled() && (boolean)Parameters.KILL_ENABLE.getValue()) {
      final double killThreshold = 0.5;  // 0.0..1.0; 0.5 is midlevel
      double level = actionLevels[CreatureAction.KILL_FORWARD.ordinal()];
      level = (Math.tanh(level) + 1.0) / 2.0; // convert to 0.0..1.0
      level *= responsivenessAdjusted;
      //if (level > killThreshold && prob2bool((level - ACTION_MIN) / ACTION_RANGE)) {
      if (level > killThreshold && prob2bool(level)) {
        Coordinate otherLoc = location.add(lastMoveDirection);
        if (grid.isInBounds(otherLoc) && grid.isOccupiedAt(otherLoc)) {
          Creature indiv2 = environment.findCreature(otherLoc);
          assert location.subtract(indiv2.getLocation()).length() == 1 :
          String.format("location subtraction is not 1:\nlocation:%s\notherLoc:%s\ncreature location:%s\ndiff:%d", location, otherLoc, indiv2.getLocation(), location.subtract(indiv2.getLocation()).length());
          environment.queueForDeath(indiv2);
        }
      }
    }

    executeMoveActions(actionLevels, responsivenessAdjusted);
  }

  // There are multiple action neurons for movement. Each type of movement neuron
  // urges the individual to move in some specific direction. We sum up all the
  // X and Y components of all the movement urges, then pass the X and Y sums through
  // a transfer function (tanh()) to get a range -1.0..1.0. The absolute values of the
  // X and Y values are passed through prob2bool() to convert to -1, 0, or 1, then
  // multiplied by the component's signum. This results in the x and y components of
  // a normalized movement offset. I.e., the probability of movement in either
  // dimension is the absolute value of tanh of the action level X,Y components and
  // the direction is the sign of the X, Y components. For example, for a particular
  // action neuron:
  //     X, Y == -5.9, +0.3 as raw action levels received here
  //     X, Y == -0.999, +0.29 after passing raw values through tanh()
  //     Xprob, Yprob == 99.9%, 29% probability of X and Y becoming 1 (or -1)
  //     X, Y == -1, 0 after applying the sign and probability
  //     The agent will then be moved West (an offset of -1, 0) if it's a legal move.
  public void executeMoveActions(double[] actionLevels, double responsivenessAdjusted) {
    double level;
    Coordinate offset;
    Coordinate lastMoveOffset = lastMoveDirection.asNormalizedCoordinate();

    // moveX,moveY will be the accumulators that will hold the sum of all the
    // urges to move along each axis. (+- floating values of arbitrary range)
    double moveX = CreatureAction.MOVE_X.isEnabled() ? actionLevels[CreatureAction.MOVE_X.ordinal()] : 0.0;
    double moveY = CreatureAction.MOVE_Y.isEnabled() ? actionLevels[CreatureAction.MOVE_Y.ordinal()] : 0.0;

    if (CreatureAction.MOVE_EAST.isEnabled()) moveX += actionLevels[CreatureAction.MOVE_EAST.ordinal()];
    if (CreatureAction.MOVE_WEST.isEnabled()) moveX -= actionLevels[CreatureAction.MOVE_WEST.ordinal()];
    if (CreatureAction.MOVE_NORTH.isEnabled()) moveY += actionLevels[CreatureAction.MOVE_NORTH.ordinal()];
    if (CreatureAction.MOVE_SOUTH.isEnabled()) moveY -= actionLevels[CreatureAction.MOVE_SOUTH.ordinal()];

    if (CreatureAction.MOVE_FORWARD.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_FORWARD.ordinal()];
      moveX += lastMoveOffset.x * level;
      moveY += lastMoveOffset.y * level;
    }
    if (CreatureAction.MOVE_REVERSE.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_REVERSE.ordinal()];
      moveX -= lastMoveOffset.x * level;
      moveY -= lastMoveOffset.y * level;
    }
    if (CreatureAction.MOVE_LEFT.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_LEFT.ordinal()];
      offset = lastMoveDirection.rotate90CCW().asNormalizedCoordinate();
      moveX += offset.x * level;
      moveY += offset.y * level;
    }
    if (CreatureAction.MOVE_RIGHT.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_RIGHT.ordinal()];
      offset = lastMoveDirection.rotate90CW().asNormalizedCoordinate();
      moveX += offset.x * level;
      moveY += offset.y * level;
    }
    if (CreatureAction.MOVE_RL.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_RL.ordinal()];
      offset = lastMoveDirection.rotate90CW().asNormalizedCoordinate();
      moveX += offset.x * level;
      moveY += offset.y * level;
    }

    if (CreatureAction.MOVE_RANDOM.isEnabled()) {
      level = actionLevels[CreatureAction.MOVE_RANDOM.ordinal()];
      offset = new Direction(new Coordinate().randomize(grid.getSizeX(), grid.getSizeY())).asNormalizedCoordinate();
      moveX += offset.x * level;
      moveY += offset.y * level;
    }

    // Convert the accumulated X, Y sums to the range -1.0..1.0 and scale by the
    // individual's responsiveness (0.0..1.0) (adjusted by a curve)
    moveX = Math.tanh(moveX);
    moveY = Math.tanh(moveY);
    moveX *= responsivenessAdjusted;
    moveY *= responsivenessAdjusted;

    // The probability of movement along each axis is the absolute value
    int probX = prob2bool(Math.abs(moveX))? 1: 0; // convert abs(level) to 0 or 1
    int probY = prob2bool(Math.abs(moveY))? 1: 0; // convert abs(level) to 0 or 1

    // The direction of movement (if any) along each axis is the sign
    int signumX = moveX < 0.0 ? -1 : 1;
    int signumY = moveY < 0.0 ? -1 : 1;

    // Generate a normalized movement offset, where each component is -1, 0, or 1
    Coordinate movementOffset = new Coordinate(probX * signumX, probY * signumY);

    // Move there if it's a valid location
    Coordinate newLoc = location.add(movementOffset);
    if (grid.isInBounds(newLoc) && grid.isEmptyAt(newLoc)) {
      environment.queueForMove(this, newLoc);
    }
  }

  /**
   Given a factor in the range 0.0..1.0, returns a boolean with the
   probability of it being true proportional to factor. For example, if
   factor == 0.2, then there is a 20% chance this function will
   return true.
   @param factor a double value in the range 0.0..1.0 representing the factor
   @return a boolean with the probability of it being true proportional to factor
   */
  public boolean prob2bool(double factor) {
  assert factor >= 0.0 && factor <= 1.0 :
    String.format("In prob2bool, factor(%f) is not correct", factor);
    return (new Random().nextDouble() < factor);
  }
  // This takes a probability from 0.0..1.0 and adjusts it according to an
  // exponential curve. The steepness of the curve is determined by the K factor
  // which is a small positive integer. This tends to reduce the activity level
  // a bit (makes the peeps less reactive and jittery).
  double responseCurve(double r) {
    final double k = (double)Parameters.RESPONSIVENESS_CURVE_K_FACTOR.getValue();
    return Math.pow((r - 2.0), -2.0 * k) - Math.pow(2.0, -2.0 * k) * (1.0 - r);
  }

  public String toString() {
    int[] c = makeGeneticColor();
    //int c = makeGeneticColorHex();
    return String.format(
      "#%03d:%s,%9s:[#%6s]:%d,\n%s\n%s",
      index,
      (isAlive()?"O":"X"),
      location,
      hex(color(c[0], c[1], c[2]), 6),
      //hex(color(c), 6),
      age,
      genome,
      brain
      );
  }

  // This prints a neural net in a form that can be processed with
  // graph-nnet.py to produce a graphic illustration of the net.
  public String toIGraph()
  {
    String iGraph = "";
    for (Gene conn : brain.getConnections()) {
      iGraph += conn.toIGraph()+"\n";
    }
    return iGraph;
  }

  public void display (color c) {
    if (toggleDisplay) {
      noStroke();
      fill(c);
      circle(location.getX()*size+size/2, location.getY()*size+size/2, size);
    }
  }
  public void display () {
    if (toggleDisplay) {
      int myColor[] = makeGeneticColor();
      int compositeColor = color(myColor[0], myColor[1], myColor[2]);
      display(compositeColor);
    }
  }

  private int[] makeGeneticColor()
  {
    Gene[] genes = genome.getGenome();
    int colors[] = new int[]{0, 0, 0};

    for (int i = 0; i < genes.length; i++) {
      byte[] data = genes[i].getBlueprint();
      for (int ii = 0; ii<2; ii++) {
        int colorValue = data[ii] << (8 * (1 - ii));
        colors[0] += (colorValue >> 16) & 0xFF;
        colors[1] += (colorValue >> 8) & 0xFF;
      }
      colors[2] += ((data[1] << 8 & 0xFF) | (data[0] & 0xFF)) & 0xFFFF;
    }
    for (int i = 0; i < colors.length; i++) {
      colors[i] /= genes.length;
      colors[i] %= 255;
      colors[i] += 127;
    }

    return colors;
  }

  private int makeGeneticColorHex() {
    Gene[] genes = genome.getGenome();

    String allGenes = "";
    for (int i = 0; i < genes.length; i++) {
      byte[] data = genes[i].getBlueprint();
      String hexValue = "";
      for (int ii = 0; ii<2; ii++) {
        hexValue += String.format("%02X", data[ii]);
      }
      allGenes += hexValue;
    }
    String colorHex = "";
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] encodedhash = digest.digest(allGenes.getBytes(StandardCharsets.UTF_8));
      for (int i = 0; i < 3; i++) {
        colorHex += String.format("%02X", encodedhash[i]);
      }
    }
    catch(Exception e) {
      colorHex = "AABBCC";
    }

    return unhex(colorHex);
  }

  /**
   * Execute one simStep for one individual.
   *
   * This executes in its own thread, invoked from the main simulator thread. First we execute
   * indiv.feedForward() which computes action values to be executed here. Some actions such as
   * signal emission(s) (pheromones), agent movement, or deaths will have been queued for
   * later execution at the end of the generation in single-threaded mode (the deferred queues
   * allow the main data structures (e.g., grid, signals) to be freely accessed read-only in all threads).
   *
   * In order to be thread-safe, the main simulator-wide data structures and their
   * accessibility are:
   *
   *     grid - read-only
   *     signals - (pheromones) read-write for the location where our agent lives
   *         using signals.increment(), read-only for other locations
   *     peeps - for other individuals, we can only read their index and genome.
   *         We have read-write access to our individual through the indiv argument.
   *
   * The other important variables are:
   *
   *     simStep - the current age of our agent, reset to 0 at the start of each generation.
   *          For many simulation scenarios, this matches our indiv.age member.
   *     randomUint - global random number generator, a private instance is given to each thread
   *
   * @param indiv the individual to execute a simStep for
   * @param simStep the current simulation step
   */
  public void simStepOneIndiv(int simStep) {
    age++; // for this implementation, tracks simStep
    double[] actions = getBrain().feedForward(simStep); // 1049

    executeActions(actions);
  }

  /**
   * in the C++ version of this, it returns a pair representing the success or failure along with a score.
   * in this version, this returns -1.0 on failure, and a score of 0.0..1.0 if passed
   */
  public double passedSurvivalCriterion(Challenge challenge) {
    int sizeX = (int)Configuration.SIZE_X.getValue();
    int sizeY = (int)Configuration.SIZE_Y.getValue();

    final double failure = -1.0;
    final double success = 1.0;

    if (!isAlive()) return failure;

    switch(challenge) {
    case CIRCLE_WEIGHTED:
      // Survivors are those inside the circular area defined by
      // safeCenter and radius
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CIRCLE_WEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CIRCLE_WEIGHTED.getParameter(0)));
        double radius = sizeX*Challenge.CIRCLE_WEIGHTED.getParameter(1);

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        return (distance <= radius) ?  success - distance/radius : failure;
      }
    case CIRCLE_UNWEIGHTED:
      // Survivors are those inside the circular area defined by
      // safeCenter and radius
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CIRCLE_UNWEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CIRCLE_UNWEIGHTED.getParameter(0)));
        double radius = sizeX*Challenge.CIRCLE_UNWEIGHTED.getParameter(1);

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        return (distance <= radius) ?  success : failure;
      }
    case RIGHT_HALF:
      // Survivors are all those on the right side of the arena
      return (location.getX() > sizeX*Challenge.RIGHT_HALF.getParameter(0)) ? success : failure;
    case RIGHT_QUARTER:
      // Survivors are all those on the right quarter of the arena
      return location.getX() > (sizeX*Challenge.RIGHT_QUARTER.getParameter(0)) ? success : failure;
    case LEFT:
      // Survivors are all those on the left eighth of the arena (or however configured)
      return location.getX() < sizeX*Challenge.LEFT.getParameter(0) ? success : failure;
    case STRING:
      // Survivors are those not touching the border and with exactly the number
      // of neighbors defined by neighbors and radius, where neighbors includes self
      {
        int minNeighbors = (int)Challenge.STRING.getParameter(0);
        int maxNeighbors = (int)Challenge.STRING.getParameter(1);
        double radius = Challenge.STRING.getParameter(2);

        if (grid.isBorder(location)) {
          return failure;
        }

        int[] count = {0};
        Consumer<Coordinate> f = loc -> {
          if (grid.isOccupiedAt(loc)) ++count[0];
        };

        location.visitNeighborhood(radius, f);
        return (count[0] >= minNeighbors && count[0] <= maxNeighbors)? success : failure;
      }
    case CENTER_WEIGHTED:
      // Survivors are those within the specified radius of the center. The score
      // is linearly weighted by distance from the center.
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_WEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CENTER_WEIGHTED.getParameter(0)));
        double radius = sizeX*Challenge.CENTER_WEIGHTED.getParameter(1);

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        return (distance<=radius)? success - distance/radius : failure;
      }
    case CENTER_UNWEIGHTED:
      // Survivors are those within the specified radius of the center
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_UNWEIGHTED.getParameter(0)), (int)(sizeY*Challenge.CENTER_UNWEIGHTED.getParameter(0)));
        double radius = sizeX*Challenge.CENTER_UNWEIGHTED.getParameter(1);

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        return (distance<=radius)? success : failure;
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

        for (int x : cornersX) {
          for (int y : cornersY) {
            double distance = new Coordinate(x, y).subtract(location).length();
            if (distance <= radius) return success;
          }
        }

        return failure;
      }
    case CORNER_WEIGHTED:
      // Survivors are those within the specified radius of any corner. The score
      // is linearly weighted by distance from the corner point.
      {
      assert sizeX == sizeY :
        String.format("Grid is not square (%d, %d)", sizeX, sizeY );
        int[] cornersX = {0, sizeX-1};
        int[] cornersY = {0, sizeY-1};
        double radius = sizeX*Challenge.CORNER_WEIGHTED.getParameter(0);

        for (int x : cornersX) {
          for (int y : cornersY) {
            double distance = new Coordinate(x, y).subtract(location).length();
            if (distance <= radius) return success - distance/radius;
          }
        }

        return failure;
      }
    case MIGRATE_DISTANCE:
      // Everybody survives and are candidate parents, but scored by how far
      // they migrated from their birth location.
      return location.subtract(birthLocation).length()/Math.max(sizeX, sizeY);
    case CENTER_SPARSE:
      // Survivors are those within the specified outer radius of the center and with
      // the specified number of neighbors in the specified inner radius.
      // The score is not weighted by distance from the center.
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.CENTER_SPARSE.getParameter(0)), (int)(sizeY*Challenge.CENTER_SPARSE.getParameter(0)));
        double outerRadius = sizeX*Challenge.CENTER_SPARSE.getParameter(1);
        double innerRadius = Challenge.CENTER_SPARSE.getParameter(2);
        int[] neighborRange = new int[]{5, 8};

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        if (distance <= outerRadius) {
          int[] count = {0};
          Consumer<Coordinate> f = loc -> {
            if (grid.isOccupiedAt(loc)) ++count[0];
          };
          location.visitNeighborhood(innerRadius, f);
          if (count[0] >= neighborRange[0] && count[0] <= neighborRange[1]) {
            return success;
          }
        }
        return failure;
      }
    case RADIOACTIVE_WALLS:
      // This challenge is handled in endOfSimStep(), where individuals may die
      // at the end of any sim step. There is nothing else to do here at the
      // end of a generation. All remaining alive become parents.
      return 1.0;
    case AGAINST_ANY_WALL:
      // Survivors are those touching any wall at the end of the generation
      return onBorder() ? success : failure;
    case TOUCH_ANY_WALL:
      // This challenge is partially handled in endOfSimStep(), where individuals
      // that are touching a wall are flagged in their Indiv record. They are
      // allowed to continue living. Here at the end of the generation, any that
      // never touch a wall will die. All that touched a wall at any time during
      // their life will become parents.
      return getChallengeBits() != 0 ? success : failure;
    case EAST_WEST:
      // Survivors are all those on the left or right eighths of the arena (or whatever the config says)
      return location.getX() < (int)(sizeX*Challenge.EAST_WEST.getParameter(0)) || location.getX() >= (sizeX - (int)(sizeX*Challenge.EAST_WEST.getParameter(0))) ?
        success :
        failure;
    case NEAR_BARRIER:
      // Survivors are those within radius of any barrier center. Weighted by distance.
      {
        double radius = sizeX * Challenge.NEAR_BARRIER.getParameter(0);
        double minDistance = 1e8;

        for (Coordinate center : grid.barrierCenters) {
          double distance = location.subtract(center).length();
          if (distance < minDistance) minDistance = distance;
        }

        return (minDistance <= radius)? success - minDistance/radius: failure;
      }
    case PAIRS:
      // Survivors are those not touching a border and with exactly one neighbor which has no other neighbor
      {
        if (onBorder()) return failure;

        List<Creature> neighbors = neighbors();
        if (neighbors.size() == 1) {
          List<Creature> otherNeighbors = neighbors.get(0).neighbors();
          if (otherNeighbors.size() == 1) return success;
        }

        return failure;
      }
    case LOCATION_SEQUENCE:
      // Survivors are those that contacted one or more specified locations in a sequence,
      // ranked by the number of locations contacted. There will be a bit set in their
      // challengeBits member for each location contacted.
      {
        int count = Integer.bitCount(challengeBits);
        int maxNumberOfBits = Integer.SIZE - Integer.numberOfLeadingZeros(challengeBits);
        return (count > 0)? (double)count/(double)maxNumberOfBits : failure;
      }
    case ALTRUISM:
      // Survivors are those inside the circular area defined by
      // safeCenter and radius
      {
        Coordinate safeCenter = new Coordinate((int)(sizeX*Challenge.ALTRUISM.getParameter(0)), (int)(sizeY*Challenge.ALTRUISM.getParameter(0)));
        double radius = sizeX*Challenge.ALTRUISM.getParameter(1);

        Coordinate offset = safeCenter.subtract(location);
        double distance = offset.length();
        return (distance<=radius)? success - distance/radius : failure;
      }
    case ALTRUISM_SACRIFICE:
      // Survivors are all those within the specified radius of the NE corner
      {
        double radius = sizeX*Challenge.ALTRUISM_SACRIFICE.getParameter(0);

        double distance = new Coordinate((int)(sizeX - radius), (int)(sizeY - radius)).subtract(location).length();
        return (distance <= radius)? success - distance/radius : failure;
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
          // They made it to the end!
          return success;
        } else if (location.getX() > cellWidth && location.getY() > cellHeight) {
          // They moved away from the start, how close are they to the end?
          Coordinate endCoord = new Coordinate(sizeX-1, sizeY-1);
          double locationDist = location.subtract(endCoord).length();
          double maxDistance = new Coordinate(0, 0).subtract(endCoord).length();
          double locDistanceDiff = maxDistance - locationDist;

          // Are they near a border?
          double []minDistance = {radius+1.0};
          Consumer<Coordinate> f = (tloc) -> {
            if (grid.isBarrierAt(tloc)) {
              double distance = location.subtract(tloc).length();
              minDistance[0] = (distance < minDistance[0])? distance : minDistance[0];
            }
          };
          location.visitNeighborhood(radius, f);

          return (minDistance[0] <= radius)? failure: success*(locDistanceDiff/maxDistance);
        }
        return failure;
      }
    case MAZE:
      {
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
          // They made it to the end!
          return success;
        } else if (location.getX() > cellWidth && location.getY() > cellHeight) {
          // They moved away from the start, are they near the end?
          Coordinate endCoord = new Coordinate(sizeX-1, sizeY-1);
          double locationDist = location.subtract(endCoord).length();
          double maxDistance = new Coordinate(0, 0).subtract(endCoord).length();
          double locDistanceDiff = maxDistance - locationDist;
          return success*(locDistanceDiff/maxDistance);
        }
        return failure;
      }
    default:
      // Handle unknown challenge
    assert false :
      "Uknown Challenge";
    }
    return failure;
  }

  // Returned sensor values range SENSOR_MIN..SENSOR_MAX
  public double getSource(Sensor sensor, int simStep)
  {
    int sizeX = (int)Configuration.SIZE_X.getValue();
    int sizeY = (int)Configuration.SIZE_Y.getValue();
    int steps = (int)Parameters.STEPS_PER_GENERATION.getValue();
    double sensorRadius = (double)Parameters.POPULATION_SENSOR_RADIUS.getValue();
    int barrierDistance = (int)Parameters.SHORT_PROBE_BARRIER_DISTANCE.getValue();

    double sensorVal = 0.0;

    switch (sensor) {
    case AGE:
      // Converts age (units of simSteps compared to life expectancy)
      // linearly to normalized sensor range 0.0..1.0
      sensorVal = ((double)getAge() / (double)steps);
      break;
    case BOUNDARY_DIST:
      {
        // Finds closest boundary, compares that to the max possible dist
        // to a boundary from the center, and converts that linearly to the
        // sensor range 0.0..1.0
        int distX = Math.min(getLocation().getX(), (sizeX - getLocation().getX()) - 1);
        int distY = Math.min(getLocation().getY(), (sizeY - getLocation().getY()) - 1);
        int closest = Math.min(distX, distY);
        double maxPossible = Math.max(sizeX/2.0 - 1.0, sizeY/2.0 - 11.0);
        sensorVal = (double)closest / maxPossible;
        break;
      }
    case BOUNDARY_DIST_X:
      {
        // Measures the distance to nearest boundary in the east-west axis,
        // max distance is half the grid width; scaled to sensor range 0.0..1.0.
        int distX = Math.min(getLocation().getX(), (sizeX - getLocation().getX()) - 1);
        sensorVal = distX / (sizeX / 2.0);
        break;
      }
    case BOUNDARY_DIST_Y:
      {
        // Measures the distance to nearest boundary in the south-north axis,
        // max distance is half the grid height; scaled to sensor range 0.0..1.0.
        int distY = Math.min(getLocation().getY(), (sizeY - getLocation().getY()) - 1);
        sensorVal = distY / (sizeY / 2.0);
        break;
      }
    case LAST_MOVE_DIR_X:
      {
        // X component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
        int lastX = getLastMoveDirection().asNormalizedCoordinate().getX();
        sensorVal = (lastX == 0) ? 0.5 : ((lastX == -1) ? 0.0 : 1.0);
        break;
      }
    case LAST_MOVE_DIR_Y:
      {
        // Y component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
        int lastY = getLastMoveDirection().asNormalizedCoordinate().getY();
        sensorVal = lastY == 0 ? 0.5 : (lastY == -1 ? 0.0 : 1.0);
        break;
      }
    case LOC_X:
      // Maps current X location 0..p.sizeX-1 to sensor range 0.0..1.0
      sensorVal = (double)getLocation().getX() / (sizeX - 1);
      break;
    case LOC_Y:
      // Maps current Y location 0..p.sizeY-1 to sensor range 0.0..1.0
      sensorVal = (double)getLocation().getY() / (sizeY - 1);
      break;
    case OSC1:
      {
        // Maps the oscillator sine wave to sensor range 0.0..1.0;
        // cycles starts at simStep 0 for everbody.
        double phase = (simStep % getOscPeriod()) / getOscPeriod(); // 0.0..1.0
        double factor = -Math.cos(phase * 2.0 * Math.PI);
      assert factor >= -1.0 && factor <= 1.0 :
        factor;
        factor += 1.0;    // convert to 0.0..2.0
        factor /= 2.0;     // convert to 0.0..1.0
        // Clip any round-off error
        sensorVal = Math.min(1.0, Math.max(0.0, factor));
        break;
      }
    case LONGPROBE_POP_FWD:
      {
        // Measures the distance to the nearest other individual in the
        // forward direction. If non found, returns the maximum sensor value.
        // Maps the result to the sensor range 0.0..1.0.
        sensorVal = grid.longProbePopulationFwd(getLocation(), getLastMoveDirection(), getLongProbeDistance()) / (double)getLongProbeDistance(); // 0..1
        break;
      }
    case LONGPROBE_BAR_FWD:
      {
        // Measures the distance to the nearest barrier in the forward
        // direction. If non found, returns the maximum sensor value.
        // Maps the result to the sensor range 0.0..1.0.
        sensorVal = grid.longProbeBarrierFwd(getLocation(), getLastMoveDirection(), getLongProbeDistance()) / (double)getLongProbeDistance(); // 0..1
        break;
      }
    case POPULATION:
      {
        // Returns population density in neighborhood converted linearly from
        // 0..100% to sensor range
        final int[] countLocs = {0};
        final int[] countOccupied = {0};
        Coordinate center = getLocation();

        Consumer<Coordinate> f = (tloc) -> {
          ++countLocs[0];
          if (grid.isOccupiedAt(tloc)) {
            ++countOccupied[0];
          }
        };

        center.visitNeighborhood(sensorRadius, f);
        sensorVal = (double)countOccupied[0] / countLocs[0];
        break;
      }
    case POPULATION_FWD:
      // Sense population density along axis of last movement direction, mapped
      // to sensor range 0.0..1.0
      sensorVal = grid.getPopulationDensityAlongAxis(getLocation(), getLastMoveDirection());
      break;
    case POPULATION_LR:
      // Sense population density along an axis 90 degrees from last movement direction
      sensorVal = grid.getPopulationDensityAlongAxis(getLocation(), getLastMoveDirection().rotate90CW());
      break;
    case BARRIER_FWD:
      // Sense the nearest barrier along axis of last movement direction, mapped
      // to sensor range 0.0..1.0
      sensorVal = grid.getShortProbeBarrierDistance(getLocation(), getLastMoveDirection(), barrierDistance);
      break;
    case BARRIER_LR:
      // Sense the nearest barrier along axis perpendicular to last movement direction, mapped
      // to sensor range 0.0..1.0
      sensorVal = grid.getShortProbeBarrierDistance(getLocation(), getLastMoveDirection().rotate90CW(), barrierDistance);
      break;
    case RANDOM:
      // Returns a random sensor value in the range 0.0..1.0.
      sensorVal = new Random().nextDouble();
      break;
    case SIGNAL0:
      // Returns magnitude of signal0 in the local neighborhood, with
      // 0.0..maxSignalSum converted to sensorRange 0.0..1.0
      sensorVal = environment.getSignals().getSignalDensity(0, getLocation());
      break;
    case SIGNAL0_FWD:
      // Sense signal0 density along axis of last movement direction
      sensorVal =  environment.getSignals().getSignalDensityAlongAxis(0, getLocation(), getLastMoveDirection());
      break;
    case SIGNAL0_LR:
      // Sense signal0 density along an axis perpendicular to last movement direction
      sensorVal =  environment.getSignals().getSignalDensityAlongAxis(0, getLocation(), getLastMoveDirection().rotate90CW());
      break;
    case GENETIC_SIM_FWD:
      {
        // Return minimum sensor value if nobody is alive in the forward adjacent location,
        // else returns a similarity match in the sensor range 0.0..1.0
        Coordinate loc2 = getLocation().add(getLastMoveDirection());
        if (grid.isInBounds(loc2) && grid.isOccupiedAt(loc2)) {
          Creature creature2 = environment.findCreature(loc2);
          if (creature2.isAlive()) {
            sensorVal = getGenome().similarity(creature2.getGenome()); // 0.0..1.0
          }
        }
        break;
      }
    default:
      assert(false);
      break;
    }

    if (Double.isNaN(sensorVal) || sensorVal < -0.01 || sensorVal > 1.01) {
      sensorVal = Math.max(0.0, Math.min(sensorVal, 1.0)); // clip
    }

    assert !Double.isNaN(sensorVal) && sensorVal >= -0.01 && sensorVal <= 1.01 :
    sensorVal;

    return sensorVal;
  }

  public List<Creature> neighbors() {
    List<Creature> neighbors = new ArrayList<Creature>();
    Consumer<Coordinate> f = loc -> {
      if (grid.isOccupiedAt(loc)) {
        neighbors.add(environment.at(grid.at(loc)));
      }
    };
    location.visitNeighborhood(1, f);

    return neighbors;
  }

  public boolean onBorder() {
    return grid.isBorder(location);
  }
}
