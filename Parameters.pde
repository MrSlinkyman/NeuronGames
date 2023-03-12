import java.util.EnumSet;

public enum Parameters {
  //POPULATION(3000), // >= 0
  POPULATION(200), // >= 0
    STEPS_PER_GENERATION(300), // > 0
    //STEPS_PER_GENERATION(10), // > 0
    MAX_GENERATIONS(200000), // >= 0
    //MAX_GENERATIONS(20), // >= 0
    NUM_THREADS(4), // > 0
    SIGNAL_LAYERS(1), // >= 0
    GENOME_MAX_LENGTH(300), // > 0
    MAX_NUMBER_NEURONS(5), // > 0
    POINT_MUTATION_RATE(0.001d), // 0.0..1.0
    GENE_INSERTION_DELETION_RATE(0.0d), // 0.0..1.0
    DELETION_RATIO(0.5d), // 0.0..1.0
    KILL_ENABLE(false),
    SEXUAL_REPRODUCTION(true),
    CHOOSE_PARENTS_BY_FITNESS(true),
    POPULATION_SENSOR_RADIUS(2.5d), // > 0.0
    SIGNAL_SENSOR_RADIUS(2.0d), // > 0
    RESPONSIVENESS(0.5d), // >= 0.0
    RESPONSIVENESS_CURVE_K_FACTOR(2.0d), // 1, 2, 3, or 4
    LONG_PROBE_DISTANCE(16), // > 0
    SHORT_PROBE_BARRIER_DISTANCE(4), // > 0
    VALENCE_SATURATION_MAG(0.5d),
    SAVE_VIDEO(true),
    VIDEO_STRIDE(25), // > 0
    VIDEO_SAVE_FIRST_FRAMES(2), // >= 0, overrides videoStride
    DISPLAY_SCALE(8),
    GENOME_ANALYSIS_STRIDE(25), // > 0
    GENOME_SAVE_STRIDE(100), // > 0
    DISPLAY_SAMPLE_GENOMES(5), // >= 0
    GENOME_COMPARISON_METHOD(0), // 0 = Jaro-Winkler; 1 = Hamming, TODO: should be 1 but that isn't implemented
    UPDATE_GRAPH_LOG(true),
    UPDATE_GRAPH_LOG_STRIDE(25), // > 0
    CHALLENGE(Challenge.CENTER_WEIGHTED), // default "6", CORNER_WEIGHTED
    BARRIER_TYPE(BarrierType.VERTICAL_BAR_CONSTANT), // >= 0
    DETERMINISTIC(false),
    RNG_SEED(12345678), // >= 0
    INITIAL_NEURON_OUTPUT(0.5d),
    OSC_PERIOD(34),

    // These must not change after initialization
    SIZE_X(150), // 2..0x10000
    SIZE_Y(150), // 2..0x10000
    BOUNDARY_TYPE(BoundaryType.BOUNDED),
    //BOUNDARY_TYPE(BoundaryType.INFINITE),
    AGENT_SIZE(3),
    GENOME_INITIAL_LENGTH_MIN(12), // > 0 and < genomeInitialLengthMax
    GENOME_INITIAL_LENGTH_MAX(24), // > 0 and < genomeInitialLengthMin
    LOG_DIR("./logs/"),
    IMAGE_DIR("./images/"),
    GRAPH_LOG_UPDATE_COMMAND("/usr/bin/gnuplot --persist ./tools/graphlog.gp"),
    FULL_OUTPUT(false),

    // These are updated automatically and not set via the parameter file
    PARAMETER_CHANGE_GENERATION_NUMBER(0); // the most recent generation number that an automatic parameter change occurred at

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

public enum BoundaryType {
  BOUNDED,
    INFINITE;
}
