import java.util.EnumSet;
/**
 * Configuration is used to se the simulation's running environment.
 * Not changeable for the duration of the Simulation
 */
public enum Configuration {
  AGENT_SIZE(4), // Sets the Creature size diameter for circle creatures, default 4
    SIZE_X(140), // > AGENT_SIZE * sqrt(POPULATION) so the creatures have somewhere to go, default 128
    SIZE_Y(140), // > AGENT_SIZE * sqrt(POPULATION) so the creatures have somewhere to go, default 128

    POPULATION(320), // >= 0, default 3000

    NUM_THREADS(4), // > 0, NOT USED

    // MAX_NUMBER_NEURONS is the maximum number of internal neurons that may
    // be addressed by genes in the genome. Range 1..INT_MAX.
    MAX_NUMBER_NEURONS(15), // > 0
    SIGNAL_LAYERS(1), // >= 0, the number of pheromone layers. Must be 1 for now. Values > 1 are for future use. Cannot be changed after a simulation starts.

    GENOME_MAX_LENGTH(300), // > 0, default 300, number of genes max per creature
    GENOME_INITIAL_LENGTH_MIN(50), // > 0 and < GENOME_MAX_LENGTH, default GENOME_MAX_LENGTH, typically equal to MAX
    GENOME_INITIAL_LENGTH_MAX(50), // > 0 and < GENOME_MAX_LENGTH, default GENOME_MAX_LENGTH, typically equal to MIN

    DETERMINISTIC(false), // boolean, default false, used to initialize the random number generators with RNG_SEED NOT USED
    RNG_SEED(12345678), // >= 0, default 12345678, NOT USED
    ;
  private Object value;

  Configuration(Object v) {
    this.value = v;
  }

  public Object getValue() {
    return value;
  }
}
/**
 * Parameters is used to alter the running state of the simulation.
 * Currently not changeable during the simulation, but
 *    TODO modify to use a configuration file similar to how biosim4 does it, with generation specific configs.
 * TODO for the NOT USED params, determine if we can/should use them and then either remove or use them
 */
public enum Parameters {
  STEPS_PER_GENERATION(400), // > 0, default 300
    MAX_GENERATIONS(200000), // >= 0, default 200000
    STEPS_PER_FRAME(3), // a frame is equivalent to a call to the draw() method

    POPULATION_SENSOR_RADIUS(2.5d), // > 0.0
    SIGNAL_SENSOR_RADIUS(2.0d), // > 0
    RESPONSIVENESS(0.5d), // >= 0.0
    RESPONSIVENESS_CURVE_K_FACTOR(2.0d), // 1, 2, 3, or 4
    LONG_PROBE_DISTANCE(16), // > 0
    SHORT_PROBE_BARRIER_DISTANCE(4), // > 0
    VALENCE_SATURATION_MAG(0.5d),
    OSC_PERIOD(34),

    POINT_MUTATION_RATE(0.001d), // 0.0..1.0, default 0.001d
    GENE_INSERTION_DELETION_RATE(0.001d), // 0.0..1.0, default b0.001d
    DELETION_RATIO(0.5d), // 0.0..1.0, default 0.5d
    SEXUAL_REPRODUCTION(true), // default true, determines if the sim should use 1 or 2 parents
    CHOOSE_PARENTS_BY_FITNESS(true), // default true
    CHALLENGE(Challenge.MAZE), // one of Challenge, default CORNER_WEIGHTED, fitness challenge
    BARRIER_TYPE(BarrierType.MAZE), // one of BarrierType, default NONE
    INITIAL_NEURON_OUTPUT(0.5d), // default Neuron output, default 0.5d
    BOUNDARY_TYPE(BoundaryType.BOUNDED), // one of BoundaryType, default BOUNDED, INFINITE currently NOT SUPPORTED

    KILL_ENABLE(false), // determine if creatures kill each other, default false

    GENOME_ANALYSIS_STRIDE(25), // > 0, default 25, when to output a random selection of genomes
    DISPLAY_SAMPLE_GENOMES(5), // >= 0, default 5, how many genomes to sample for analysis
    GENOME_SAVE_STRIDE(100), // > 0, default 100, when to save the population
    GENOME_COMPARISON_METHOD(ComparisonMethod.JARO_WINKLER), // ComparisonMethod, default JARO_WINKLER
    UPDATE_GRAPH_LOG(true), // boolean, default true, NOT USED
    UPDATE_GRAPH_LOG_STRIDE(25), // > 0, default 25, NOT USED

    SAVE_VIDEO(true), // boolean, default true, NOT USED, saves frames to make a video
    VIDEO_STRIDE(25), // > 0, default 25, NOT USED
    VIDEO_SAVE_FIRST_FRAMES(2), // >= 0, overrides videoStride, default 2, NOT USED
    DISPLAY_SCALE(8), // default 8, used for scaling the movie, NOT USED

    LOG_DIR("./logs/"), // default ./logs/, NOT USED
    IMAGE_DIR("./images/"), // default ./images/, NOT USED
    GRAPH_LOG_UPDATE_COMMAND("/usr/bin/gnuplot --persist ./tools/graphlog.gp"), // NOT USED
    FULL_OUTPUT(false), // boolean, default false, NOT USED
    EPOCH_FILE_POST("eopch-log.txt"), // file name, default "epoch-log.txt", generational stats

    // These are updated automatically and not set via the parameter file
    PARAMETER_CHANGE_GENERATION_NUMBER(0); // the most recent generation number that an automatic parameter change occurred at, NOT USED

  private final Object value;

  private Parameters(Object value) {
    this.value = value;
  }

  public Object getValue() {
    return value;
  }

  public static void debugOutput(String t, Object... o) {
    if ((boolean)FULL_OUTPUT.getValue())
      System.out.printf(t, o);
  }
}

/**
 * Challenge enum determines how the creatures are judged at the end of each generation.
 * Each challenge has 1 or more values that are used in the challenge to configure it's criteria.
 * This is also used to mark how the challenge would be seen by the creatures on the display wondow.
 */
public enum Challenge {
  CIRCLE_WEIGHTED(.25, .25),
    CIRCLE_UNWEIGHTED(.25, .25),
    RIGHT_HALF(.5),
    RIGHT_QUARTER(.75),
    STRING(22, 2, 1.5),
    CENTER_WEIGHTED(.5, 1.0/3.0),
    CENTER_UNWEIGHTED(.5, 1.0/3.0),
    CORNER(1.0/8.0),
    CORNER_WEIGHTED(1.0/4.0),
    MIGRATE_DISTANCE,
    CENTER_SPARSE(.5, .25, 1.5),
    LEFT(1.0/8.0),
    RADIOACTIVE_WALLS(.5, .5), // (time factor before radioactive switch, width factor of radioactivity)
    AGAINST_ANY_WALL,
    TOUCH_ANY_WALL,
    EAST_WEST(1.0/8.0), // (wall size)
    NEAR_BARRIER(1.0/2.0), // (radius factor)
    PAIRS,
    LOCATION_SEQUENCE,
    ALTRUISM(.25, .25), // (circle location factor, radius factor)
    ALTRUISM_SACRIFICE(.25), // radius factor
    MAZE(-1.0, -1.0); // Used in conjunction with BarrierType.MAZE, sets up (begin, end) challenge areas. (random start/end within maze[<0.0], set start [0.0...SIZE_X], end [0.0...SIZE_Y])

  double[] parameters;

  public static final EnumSet<Challenge> ALL_CHALLENGES = EnumSet.allOf(Challenge.class);

  Challenge() {
    parameters = new double[]{};
  }

  Challenge(double... parameters) {
    this.parameters = parameters;
  }

  public double[] getParameters() {
    return parameters;
  }
  public double getParameter(int i) {
    return parameters[i];
  }
}

/**
 * BarrirType is used to define the various barriers that the creatures might face.
 * Each barrier takes 2 configuration values that help to define the barrier.
 */
public enum BarrierType {
  NONE(),
    VERTICAL_BAR_CONSTANT(.5, .25), // x-Factor, y-factor
    VERTICAL_BAR_RANDOM(.8, .8), // x-factor, y-factor
    FIVE_BLOCKS_STAGGERED(2.0, 1.0/3.0), // blockSizeX, y-factor
    HORIZONTAL_BAR_CONSTANT(1.0/4.0, 3.0/4.0), // X-factor,Y-factor
    FLOATING_ISLANDS_RANDOM(3, 6), // margin, radius
    SPOTS(5, 5), // numLocations, radius
    MAZE(7.0, 7.0); // (cols, rows)

  private final double[] args;

  BarrierType(double... args) {
    this.args = args;
  }

  public boolean hasArgs() {
    return args.length > 0;
  }
  public double getArg(int index) {
  assert index < args.length :
    index;
    return args[index];
  }
}

public enum  RunMode {
  STOP,
    RUN,
    PAUSE,
    ABORT
}

/**
 * BoundaryType defines how the creatures view the world, whether or not they are surrounded by walls (flat earth)
 * or if their world is infinite (round earth).
 */
public enum BoundaryType {
  BOUNDED,
    INFINITE; // INFINITE is currently not support
}

public enum ComparisonMethod {
  JARO_WINKLER,
    HAMMING_BITS,
    HAMMING_BYTES;
}
