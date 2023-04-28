import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.time.Instant;

public class ParamManager {
  private Params params;
  private Configurations configs;
  private File configFile;
  private Instant lastModifiedTime;

  public Configurations getConfigs() {
    return configs;
  }

  public Params getParams() {
    return params;
  }

  public ParamManager() {
    params = new Params();
    configs = new Configurations();
    configFile = new File("simulator.ini");

    this.setDefaults();
  }
  public void setDefaults() {
    //Immutable, set by Configuration enum only
    configs.agentSize = (Integer)Configuration.AGENT_SIZE.getValue();
    configs.sizeX = (Integer)Configuration.SIZE_X.getValue();
    configs.sizeY = (Integer)Configuration.SIZE_Y.getValue(); // 2..0x10000

    // Can be set by configuration values
    configs.population = (Integer)Configuration.POPULATION.getValue(); // >= 0
    //configs.numThreads; // > 0
    configs.signalLayers = (Integer)Configuration.SIGNAL_LAYERS.getValue(); // >= 0
    configs.genomeMaxLength = (Integer)Configuration.GENOME_MAX_LENGTH.getValue(); // > 0
    configs.maxNumberNeurons = (Integer)Configuration.MAX_NUMBER_NEURONS.getValue(); // > 0
    configs.genomeInitialLengthMin = (Integer)Configuration.GENOME_INITIAL_LENGTH_MIN.getValue(); // > 0 and < genomeInitialLengthMax
    configs.genomeInitialLengthMax = (Integer)Configuration.GENOME_INITIAL_LENGTH_MAX.getValue(); // > 0 and < genomeInitialLengthMin
    //configs.logDir;
    //configs.imageDir;
    //configs.graphLogUpdateCommand;
    configs.RNGSeed = (Long)Configuration.RNG_SEED.getValue(); // >= 0
    configs.deterministic = (Boolean)Configuration.DETERMINISTIC.getValue();

    // Can change during simulation run
    params.stepsPerGeneration = (Integer) Parameters.STEPS_PER_GENERATION.getValue();
    params.maxGenerations = (Integer) Parameters.MAX_GENERATIONS.getValue();
    params.populationSensorRadius = (Double) Parameters.POPULATION_SENSOR_RADIUS.getValue();
    params.signalSensorRadius = (Double) Parameters.SIGNAL_SENSOR_RADIUS.getValue();
    params.responsiveness = (Double) Parameters.RESPONSIVENESS.getValue();
    params.responsivenessCurveKFactor = (Double) Parameters.RESPONSIVENESS_CURVE_K_FACTOR.getValue();
    params.longProbeDistance = (Integer) Parameters.LONG_PROBE_DISTANCE.getValue();
    params.shortProbeBarrierDistance = (Integer) Parameters.SHORT_PROBE_BARRIER_DISTANCE.getValue();
    params.valenceSaturationMag = (Double) Parameters.VALENCE_SATURATION_MAG.getValue();
    params.pointMutationRate = (Double) Parameters.POINT_MUTATION_RATE.getValue();
    params.geneInsertionDeletionRate = (Double) Parameters.GENE_INSERTION_DELETION_RATE.getValue();
    params.deletionRatio = (Double) Parameters.DELETION_RATIO.getValue();
    params.sexualReproduction = (Boolean) Parameters.SEXUAL_REPRODUCTION.getValue();
    params.chooseParentsByFitness = (Boolean) Parameters.CHOOSE_PARENTS_BY_FITNESS.getValue();
    params.challenge = (Challenge) Parameters.CHALLENGE.getValue();
    params.barrierType = (BarrierType) Parameters.BARRIER_TYPE.getValue();
    params.killEnable = (Boolean) Parameters.KILL_ENABLE.getValue();
    params.genomeAnalysisStride = (Integer) Parameters.GENOME_ANALYSIS_STRIDE.getValue();
    params.displaySampleGenomes = (Integer) Parameters.DISPLAY_SAMPLE_GENOMES.getValue();
    params.genomeComparisonMethod = (ComparisonMethod) Parameters.GENOME_COMPARISON_METHOD.getValue();
    params.updateGraphLog = (Boolean) Parameters.UPDATE_GRAPH_LOG.getValue();
    params.updateGraphLogStride = (Integer) Parameters.UPDATE_GRAPH_LOG_STRIDE.getValue();
    params.saveVideo = (Boolean) Parameters.SAVE_VIDEO.getValue();
    params.videoStride = (Integer) Parameters.VIDEO_STRIDE.getValue();
    params.videoSaveFirstFrames = (Integer) Parameters.VIDEO_SAVE_FIRST_FRAMES.getValue();
    params.displayScale = (Integer) Parameters.DISPLAY_SCALE.getValue();
  }

  public void registerConfigFile(File file) {
    configFile = (file == null)?configFile:file;
  }

  public void updateFromConfigFile(int generationNumber) {
    String[] lines = loadStrings(configFile.getAbsolutePath());
    if (lines == null) return;

    for (String line : lines) {
      String config = line.trim();
      if (config.startsWith("#") || config.isEmpty()) continue;

      String[] nameValue = config.split("=");
      String name = nameValue[0].trim();
      String value = nameValue[1].trim();
      String[] nameGeneration = name.split("@");
      if (nameGeneration.length > 1) {
        try {
          int generationSpecifier = Integer.parseInt(nameGeneration[1].trim());
          if (generationSpecifier > generationNumber) continue;
          else if (generationSpecifier == generationNumber) params.parameterChangeGenerationNumber = generationNumber;
          name = nameGeneration[0];
        }
        catch (NumberFormatException e) {
          System.out.printf("invalid specifier in configs: %s\n", line);
        }
      }

      String[] valueComment = value.split("#");
      value = valueComment[0].trim();
      ingestParameter(name, value);
    }
  }

  private void ingestParameter(String name, String stringValue) {
    name = name.toLowerCase();
    Object value = decodeValue(stringValue);

    switch (name) {
    case "challenge":
      params.challenge = (Challenge)value;
      break;
    case "genomeinitiallengthmin":
      configs.genomeInitialLengthMin = (Integer)value;
      break;
    case "genomeinitiallengthmax":
      configs.genomeInitialLengthMax = (Integer)value;
      break;
    case "population":
      configs.population = (Integer)value;
      break;
    case "stepspergeneration":
      params.stepsPerGeneration = (Integer)value;
      break;
    case "maxgenerations":
      params.maxGenerations = (Integer)value;
      break;
    case "barriertype":
      params.barrierType = (BarrierType)value;
      break;
      //case "numthreads":
      //    params.numThreads = uVal;
      //    break;
    case "signallayers":
      configs.signalLayers = (Integer)value;
      break;
    case "genomemaxlength":
      configs.genomeMaxLength = (Integer)value;
      break;
    case "maxnumberneurons":
      configs.maxNumberNeurons = (Integer)value;
      break;
    case "pointmutationrate":
      params.pointMutationRate = (Double)value;
      break;
    case "geneinsertiondeletionrate":
      params.geneInsertionDeletionRate = (Double)value;
      break;
    case "deletionratio":
      params.deletionRatio = (Double)value;
      break;
    case "killenable":
      params.killEnable = (Boolean)value;
      break;
    case "sexualreproduction":
      params.sexualReproduction = (Boolean)value;
      break;
    case "chooseparentsbyfitness":
      params.chooseParentsByFitness = (Boolean)value;
      break;
    case "populationsensorradius":
      params.populationSensorRadius = (Double)value;
      break;
    case "signalsensorradius":
      params.signalSensorRadius = (Double)value;
      break;
    case "responsiveness":
      params.responsiveness = (Double)value;
      break;
    case "responsivenesscurvekfactor":
      params.responsivenessCurveKFactor = (Double)value;
      break;
    case "longprobedistance":
      params.longProbeDistance = (Integer)value;
      break;
    case "shortprobebarrierdistance":
      params.shortProbeBarrierDistance = (Integer)value;
      break;
    case "valencesaturationmag":
      params.valenceSaturationMag = (Double)value;
      break;
    case "savevideo":
      params.saveVideo = (Boolean)value;
      break;
    case "videostride":
      params.videoStride = (Integer)value;
      break;
    case "videosavefirstframes":
      params.videoSaveFirstFrames = (Integer)value;
      break;
    case "displayscale":
      params.displayScale = (Integer)value;
      break;
    case "genomeanalysisstride":
      params.genomeAnalysisStride = (Integer)value;
      break;
    case "displaysamplegenomes":
      params.displaySampleGenomes = (Integer)value;
      break;
    case "genomecomparisonmethod":
      params.genomeComparisonMethod = (ComparisonMethod)value;
      break;
    case "updategraphlog":
      params.updateGraphLog = (Boolean)value;
      break;
    case "updategraphlogstride":
      params.updateGraphLogStride = (Integer)value;
      break;
    case "deterministic":
      configs.deterministic = (Boolean)value;
      break;
    case "rngseed":
      configs.RNGSeed = (Long)value;
      break;
    default:
      System.out.printf("Invalid param: %s = %s\n", name, value);
    }
  }

  public void checkParameters() {
    // implementation code
  }

  private Object decodeValue(String input) {
    Object value = null;

    try {
      // Try to parse as integer
      value = Integer.parseInt(input);
    }
    catch (NumberFormatException e1) {
      try {
        // Try to parse as integer
        value = Double.parseDouble(input);
      }
      catch (NumberFormatException e5) {
        try {
          // Try to parse as integer
          value = Long.parseLong(input);
        }
        catch (NumberFormatException e7) {
          try {
            // Try to parse as boolean
            value = Boolean.parseBoolean(input);
          }
          catch (IllegalArgumentException e2) {
            try {
              // Try to get enum by name
              value = Enum.valueOf(Challenge.class, input);
            }
            catch (IllegalArgumentException e3) {
              try {
                // Try to get enum by name
                value = Enum.valueOf(BarrierType.class, input);
              }
              catch (IllegalArgumentException e4) {
                try {
                  // Try to get enum by name
                  value = Enum.valueOf(ComparisonMethod.class, input);
                }
                catch (IllegalArgumentException e6) {
                  // Could not parse as any of the above
                  System.err.println("Unable to parse input string: " + input);
                }
              }
            }
          }
        }
      }
    }

    return value;
  }
}

public class Params {
  public int stepsPerGeneration; // > 0
  public int maxGenerations; // >= 0
  public double pointMutationRate; // 0.0..1.0
  public double geneInsertionDeletionRate; // 0.0..1.0
  public double deletionRatio; // 0.0..1.0
  public boolean killEnable;
  public boolean sexualReproduction;
  public boolean chooseParentsByFitness;
  public double populationSensorRadius; // > 0.0
  public double signalSensorRadius; // > 0
  public double responsiveness; // >= 0.0
  public double responsivenessCurveKFactor; // 1, 2, 3, or 4
  public long longProbeDistance; // > 0
  public int shortProbeBarrierDistance; // > 0
  public double valenceSaturationMag;
  public boolean saveVideo;
  public int videoStride; // > 0
  public int videoSaveFirstFrames; // >= 0, overrides videoStride
  public int displayScale;
  public int genomeAnalysisStride; // > 0
  public int displaySampleGenomes; // >= 0
  public ComparisonMethod genomeComparisonMethod; // 0 = Jaro-Winkler; 1 = Hamming
  public boolean updateGraphLog;
  public int updateGraphLogStride; // > 0
  public Challenge challenge;
  public BarrierType barrierType; // >= 0

  // These are updated automatically and not set via the parameter file
  public int parameterChangeGenerationNumber; // the most recent generation number that an automatic parameter change occurred at
}

public class Configurations {
  public int agentSize;
  public int sizeX; // 2..0x10000
  public int sizeY; // 2..0x10000
  public int population; // >= 0
  public int numThreads; // > 0
  public int signalLayers; // >= 0
  public int genomeMaxLength; // > 0
  public int maxNumberNeurons; // > 0
  public int genomeInitialLengthMin; // > 0 and < genomeInitialLengthMax
  public int genomeInitialLengthMax; // > 0 and < genomeInitialLengthMin
  public String logDir;
  public String imageDir;
  public String graphLogUpdateCommand;
  public long RNGSeed; // >= 0
  public boolean deterministic;
}
