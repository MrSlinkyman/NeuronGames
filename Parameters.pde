import java.util.EnumSet;
/**
 * Parameters is currently the only way to configure the simulation.
 * TODO modify this method to use a configuration file similar to how biosim4 does it, with generation specific
 * configs.  Might need to segregate "configurable" paramters from "static" parameters into two enums.
 */
public enum Parameters {
  AGENT_SIZE(4), // Sets the Creature size diameter for circle creatures, default 4
    SIZE_X(128), // > AGENT_SIZE * sqrt(POPULATION) so the creatures have somewhere to go, default 128
    SIZE_Y(128), // > AGENT_SIZE * sqrt(POPULATION) so the creatures have somewhere to go, default 128
    POPULATION(1000), // >= 0, default 3000
    STEPS_PER_GENERATION(300), // > 0, default 300
    MAX_GENERATIONS(200000), // >= 0, default 200000
    STEPS_PER_FRAME(3), // a frame is equivalent to a call to the draw() method

    NUM_THREADS(4), // > 0, NOT USED

    SIGNAL_LAYERS(1), // >= 0
    MAX_NUMBER_NEURONS(10), // > 0
    POPULATION_SENSOR_RADIUS(2.5d), // > 0.0
    SIGNAL_SENSOR_RADIUS(2.0d), // > 0
    RESPONSIVENESS(0.5d), // >= 0.0
    RESPONSIVENESS_CURVE_K_FACTOR(2.0d), // 1, 2, 3, or 4
    LONG_PROBE_DISTANCE(16), // > 0
    SHORT_PROBE_BARRIER_DISTANCE(4), // > 0
    VALENCE_SATURATION_MAG(0.5d),
    OSC_PERIOD(34),

    POINT_MUTATION_RATE(0.001d), // 0.0..1.0, default 0.001d
    GENE_INSERTION_DELETION_RATE(0.0d), // 0.0..1.0, default 0.0d
    DELETION_RATIO(0.5d), // 0.0..1.0, default 0.5d
    SEXUAL_REPRODUCTION(true), // default true, determines if the sim should use 1 or 2 parents
    CHOOSE_PARENTS_BY_FITNESS(true), // default true
    CHALLENGE(Challenge.RADIOACTIVE_WALLS), // one of Challenge, default CORNER_WEIGHTED, fitness challenge
    BARRIER_TYPE(BarrierType.SPOTS), // one of BarrierType, default NONE
    INITIAL_NEURON_OUTPUT(0.5d), // default Neuron output, default 0.5d
    BOUNDARY_TYPE(BoundaryType.BOUNDED), // one of BoundaryType, default BOUNDED, INFINITE currently NOT SUPPORTED

    KILL_ENABLE(false), // determine if creatures kill each other, default false

    GENOME_ANALYSIS_STRIDE(25), // > 0, default 25, when to output a random selection of genomes
    DISPLAY_SAMPLE_GENOMES(5), // >= 0, default 5, how many genomes to sample for analysis
    GENOME_SAVE_STRIDE(100), // > 0, default 100, when to save the population
    GENOME_COMPARISON_METHOD(0), // 0 = Jaro-Winkler; 1 = Hamming, TODO: should be 1 but that isn't implemented
    UPDATE_GRAPH_LOG(true), // boolean, default true, NOT USED
    UPDATE_GRAPH_LOG_STRIDE(25), // > 0, default 25, NOT USED
    DETERMINISTIC(false), // boolean, default fale, NOT USED
    RNG_SEED(12345678), // >= 0, default 12345678, NOT USED

    GENOME_MAX_LENGTH(300), // > 0, default 300, number of genes max per creature
    GENOME_INITIAL_LENGTH_MIN(24), // > 0 and < GENOME_MAX_LENGTH, default GENOME_MAX_LENGTH, typically equal to MAX
    GENOME_INITIAL_LENGTH_MAX(24), // > 0 and < GENOME_MAX_LENGTH, default GENOME_MAX_LENGTH, typically equal to MIN

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
    ALTRUISM_SACRIFICE(.25); // radius factor

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
    SPOTS(5, 5); // numLocations, radius

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
