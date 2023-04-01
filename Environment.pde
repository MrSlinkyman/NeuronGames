import java.util.Objects;
import java.util.List;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

class Environment {
  private List<Creature> deathQueue;
  private List<Object[]> moveQueue;
  private List<Creature> creatures;
  private Grid grid;
  private Signals signals;
  private int generationsWithNoSurvivors;

  // TODO: refactor to a getter/setter
  public int[] genomeInitialRange = new int[]{(int)Configuration.GENOME_INITIAL_LENGTH_MIN.getValue(), (int)Configuration.GENOME_INITIAL_LENGTH_MAX.getValue()};

  Environment(int[] genomeRange) {
    this();
    this.genomeInitialRange = genomeRange;
  }

  Environment() {
    grid = new Grid(this);
    signals = new Signals();
    creatures = new ArrayList<Creature>();
    deathQueue = new ArrayList<Creature>();
    moveQueue = new ArrayList<Object[]>();
  }

  /**
   * TODO need to determine if any initialization should happen here
   */
  public void initialize() {
    // Index == 0 is a special case
    //creatures = new ArrayList<Creature>(population+1);
    //for (int i = 0; i < population+1; i++) creatures.add(null);
    //creatures.add(null);
    //for (int i = 0; i < population; i++) {
    //  Coordinate location = new Coordinate().randomize((int)Configuration.SIZE_X.getValue(), (int)Configuration.SIZE_Y.getValue());
    //  Genome genome = new Genome(0, this).randomize();
    //  Creature c = new Creature(i, location, genome, this);
    //  creatures.add(c);
    //}
    //return creatures.subList(1, creatures.size());
    generationsWithNoSurvivors = 0;
  }

  public void initializeGeneration0(String fileToLoad) {
    grid.zeroFill();
    grid.createBarrier();
    signals.zeroFill();
    creatures.clear();
    generationsWithNoSurvivors = 0;

    String[] generationData = loadStrings(fileToLoad);
    for (String population : generationData) {
      String[] populationArray = population.split("\\|");
      generations = Integer.parseInt(populationArray[0]);
      String[] creatureCandidates = populationArray[1].split("\\]");
      int index = 0;
      for (String creatureCandidate : creatureCandidates) {
        if (creatureCandidate != null && !creatureCandidate.isBlank()) {
          String geneStrings = creatureCandidate.substring(1);
          String[] geneSequence = geneStrings.split(",");
          Genome genome = new Genome(geneSequence);
          Creature c = new Creature(index++, grid.findEmptyLocation(), genome, this);
          addCreature(c);
        }
      }
    }
  }

  public void initializeGeneration0(int population) {
    grid.zeroFill();
    grid.createBarrier();
    signals.zeroFill();
    creatures.clear();
    generationsWithNoSurvivors = 0;

    // Add the rest of the creatures, initialized new
    for (int i = 0; i < population; i++) {
      addCreature(new Creature(i, grid.findEmptyLocation(), new Genome(0).randomize(genomeInitialRange[0], genomeInitialRange[1]), this));
    }
  }

  public void initializeNewGeneration(List<Genome> parents, int generation) {
    grid.zeroFill();
    grid.createBarrier();
    signals.zeroFill();

    if (parents.size() > 1) {
      generationsWithNoSurvivors = 0;
      for (int i = 0; i < populationSize(); i++) {
        addCreature(new Creature(i, grid.findEmptyLocation(), new Genome(parents), this));
      }
    } else {
      System.out.printf("No parents at generation:%d\n", generation);
    }
  }

  private void addCreature(Creature c) {
    if (c.getIndex() >= populationSize()) {
      creatures.add(c);
    } else {
      creatures.set(c.getIndex(), c);
    }
    grid.set(c.getLocation(), c.getIndex());
  }

  void endOfSimStep(int simStep, int generation) {
    Random rando = new Random();
    if ((Challenge)Parameters.CHALLENGE.getValue() == Challenge.RADIOACTIVE_WALLS) {
      // During the first half of the generation, the west wall is radioactive,
      // where X == 0. In the last half of the generation, the east wall is
      // radioactive, where X = the area width - 1. There's an exponential
      // falloff of the danger, falling off to zero at the arena half line.
      int radioactiveX = (simStep < (int)Parameters.STEPS_PER_GENERATION.getValue() * Challenge.RADIOACTIVE_WALLS.getParameter(0)) ? 0 : (int)Configuration.SIZE_X.getValue() - 1;

      IntStream.range(0, populationSize()).parallel().forEach(index -> {
        Creature indiv = at(index);
        if (indiv.isAlive()) {
          int distanceFromRadioactiveWall = Math.abs(indiv.getLocation().getX() - radioactiveX);
          if (distanceFromRadioactiveWall < (int)Configuration.SIZE_X.getValue() *Challenge.RADIOACTIVE_WALLS.getParameter(1)) {
            double chanceOfDeath = 1.0 / distanceFromRadioactiveWall;
            if (rando.nextDouble() < chanceOfDeath) {
              queueForDeath(indiv);
            }
          }
        }
      }
      );
    }

    // If the individual is touching any wall, we set its challengeFlag to true.
    // At the end of the generation, all those with the flag true will reproduce.
    if ((Challenge)Parameters.CHALLENGE.getValue() == Challenge.TOUCH_ANY_WALL) {
      for (int index = 0; index < populationSize(); index++) {
        Creature indiv = at(index);
        if (indiv.getLocation().getX() == 0 || indiv.getLocation().getX() == (int)Configuration.SIZE_X.getValue() - 1
          || indiv.getLocation().getY() == 0 || indiv.getLocation().getY() == (int)Configuration.SIZE_Y.getValue() - 1) {
          indiv.setChallengeBits(1);
        }
      }
    }

    // If this challenge is enabled, the individual gets a bit set in their challengeBits
    // member if they are within a specified radius of a barrier center. They have to
    // visit the barriers in sequential order.
    if ((Challenge)Parameters.CHALLENGE.getValue() == Challenge.LOCATION_SEQUENCE) {
      double radius = 9.0;
      for (int index = 0; index < populationSize(); ++index) {
        Creature indiv = at(index);
        for (int n = 0; n < grid.barrierCenters.size(); ++n) {
          int bit = 1 << n;
          if ((indiv.getChallengeBits() & bit) == 0) {
            if ((indiv.getLocation().subtract(grid.barrierCenters.get(n)).length()) <= radius) {
              indiv.addChallengeBit(bit);
            }
            break;
          }
        }
      }
    }

    drainDeathQueue();
    drainMoveQueue();
    signals.fade(0); // takes layerNum  todo!!!
  }

  // At the end of each generation, we save a video file (if p.saveVideo is true) and
  // print some genomic statistics to stdout (if p.updateGraphLog is true).
  public List<Creature> endOfGeneration(int generation) {
    // TODO: Save video0
    Parameters.debugOutput("End of Generation %d\n", generation);
    // TODO: Save stats to console or somewhere

    List<Creature> survivors = spawnNewGeneration(generations, murderCount.get());
    
    int numberSurvivors = survivors.size();
    if (numberSurvivors > 0){
      if(generation % (int)Parameters.GENOME_ANALYSIS_STRIDE.getValue() == 0) {
      displaySampleGenomes((int)Parameters.DISPLAY_SAMPLE_GENOMES.getValue());
      }
      
    }
    return survivors;
  }

  // At this point, the deferred death queue and move queue have been processed
  // and we are left with zero or more individuals who will repopulate the
  // world grid.
  // In order to redistribute the new population randomly, we will save all the
  // surviving genomes in a container, then clear the grid of indexes and generate
  // new individuals. This is inefficient when there are lots of survivors because
  // we could have reused (with mutations) the survivors' genomes and neural
  // nets instead of rebuilding them.
  // Returns survivor-reproducers.
  // Must be called in single-thread mode between generations.
  public List<Creature> spawnNewGeneration(int generation, int murderCount) {
    int sacrificedCount = 0; // for the altruism challenge

    // This container will hold the indexes and survival scores (0.0..1.0)
    // of all the survivors, only those with a positive score will provide genomes for repopulation.
    Map<Integer, Double> parents = new HashMap<Integer, Double>(); // index of the creature with a survival score

    // This container will hold the genomes of the survivors
    List<Genome> parentGenomes = new ArrayList<Genome>();

    if ((Challenge)Parameters.CHALLENGE.getValue() != Challenge.ALTRUISM) {
      // First, make a list of all the individuals who will become parents; save
      // their scores for later sorting. Indexes start at 1.
      for (int index = 0; index < populationSize(); index++) {
        assert at(index) != null :
        String.format("Creature at %d is null (creatures size:%d)", index, populationSize());
        double score = at(index).passedSurvivalCriterion( (Challenge)Parameters.CHALLENGE.getValue());
        // Save the parent genome if it results in valid neural connections
        if (score >= 0 && !at(index).getBrain().connections.isEmpty()) {
          parents.put(index, score);
        }
      }
    } else {
      // For the altruism challenge, test if the agent is inside either the sacrificial
      // or the spawning area. We'll count the number in the sacrificial area and
      // save the genomes of the ones in the spawning area, saving their scores
      // for later sorting. Indexes start at 1.

      boolean considerKinship = true;
      Map<Integer, Double> sacrificesIndexes = new HashMap<Integer, Double>(); // those who gave their lives for the greater good

      for (int index = 0; index < populationSize(); index++) {
        // This the test for the spawning area:
        Creature creature = at(index);
        double score = creature.passedSurvivalCriterion(Challenge.ALTRUISM);
        if (score >= 0 && !creature.getBrain().connections.isEmpty()) {
          parents.put(index, score);
        } else {
          // This is the test for the sacrificial area:
          score = creature.passedSurvivalCriterion(Challenge.ALTRUISM_SACRIFICE);
          if (score >= 0 && !creature.getBrain().connections.isEmpty()) {
            if (considerKinship) {
              sacrificesIndexes.put(index, (double)-1.0);
            } else {
              ++sacrificedCount;
            }
          }
        }
      }

      int generationToApplyKinship = 10;
      final int altruismFactor = 10; // the saved:sacrificed ratio

      if (considerKinship) {
        if (generation > generationToApplyKinship) {
          // Todo: optimize!!!
          double threshold = 0.7;
          Map<Integer, Double> survivingKin = new HashMap<Integer, Double>();
          for (int passes = 0; passes < altruismFactor; ++passes) {
            for (int sacrificedIndex : sacrificesIndexes.keySet()) {
              List<Map.Entry<Integer, Double>> possibleParents = new ArrayList<Map.Entry<Integer, Double>>(parents.entrySet());
              // randomize the next loop so we don't keep using the first one repeatedly
              Collections.shuffle(possibleParents);
              for (Map.Entry<Integer, Double> possibleParent : possibleParents) {
                Genome g1 = at(sacrificedIndex).getGenome();
                Genome g2 = at(possibleParent.getKey()).getGenome();
                double similarity = g1.similarity(g2);
                if (similarity >= threshold) {
                  survivingKin.put(possibleParent.getKey(), possibleParent.getValue());
                  // mark this one so we don't use it again?
                  break;
                }
              }
            }
          }
          parents = survivingKin;
        }
      } else {
        // Limit the parent list
        int numberSaved = sacrificedCount * altruismFactor;
        if (!parents.isEmpty() && numberSaved < parents.size()) {
          List<Map.Entry<Integer, Double>> reverseParents = new ArrayList<Map.Entry<Integer, Double>>(parents.entrySet());
          Collections.reverse(reverseParents);
          int saveCount = reverseParents.size();
          for (Map.Entry<Integer, Double> parent : reverseParents) {
            if (saveCount-- < numberSaved) break;
            parents.remove(parent.getKey());
          }
        }
      }
    }


    List<Map.Entry<Integer, Double>> sortedParents = parents.entrySet().stream().sorted(new Comparator<Map.Entry<Integer, Double>>() {
      public int compare(Map.Entry<Integer, Double> parent1, Map.Entry<Integer, Double> parent2) {
        return Double.compare(parent2.getValue(), parent1.getValue());
      }}).collect(Collectors.toList()); 
    
    List<Creature> survivors = new ArrayList<Creature>();
    for (Map.Entry<Integer, Double> parent : sortedParents) {
      Creature c = at(parent.getKey());
      parentGenomes.add(c.getGenome());
      survivors.add(c);
    }

    int returnCount = 0;
    appendEpochLog(generation, parentGenomes.size(), murderCount);
    if (!parentGenomes.isEmpty()) {
      initializeNewGeneration(parentGenomes, generation + 1);
      returnCount = parentGenomes.size();
    } else if ((Challenge)Parameters.CHALLENGE.getValue() != Challenge.MAZE && (Challenge)Parameters.CHALLENGE.getValue() != Challenge.MAZE_FEAR) {
      initializeGeneration0(populationSize());
    } else {
      // in the maze challenge, just let the generation go on unless it's been too long
      System.out.printf("Maze Challenge: keep going! generationsWithNoSurvivors:%d\n", generationsWithNoSurvivors);
      if (++generationsWithNoSurvivors > (int)Parameters.STEPS_PER_GENERATION.getValue()) {
        initializeGeneration0(populationSize());
      } else {
        returnCount = populationSize();
      }
    }

    return survivors;
  }

  /**
   * The epoch log contains one line per generation in a format that can be
   * fed to graphlog.gp to produce a chart of the simulation progress.
   */
  void appendEpochLog(int generation, int numberSurvivors, int murderCount)
  {

  assert epochLog != null :
    String.format("%s is not open", epochLog);

    System.out.printf("gen:%d survivors:%d diversity:%.2f geneLength:%d murders:%d\n", generation, numberSurvivors, geneticDiversity(), averageGenomeLength(), murderCount);
    epochLog.println(String.format("%d %d %.2f %d %d", generation, numberSurvivors, geneticDiversity(), averageGenomeLength(), murderCount));
  }

  private int averageGenomeLength()
  {
    Random rando = new Random();
    int count = 100;
    int numberSamples = 0;
    int sum = 0;

    while (count-- > 0) {
      sum += at(rando.nextInt(populationSize())).getGenome().size();
      ++numberSamples;
    }

    return sum / numberSamples;
  }

  /**
   * Samples random pairs of individuals regardless if they are alive or not
   * @return 0.0..1.0,
   */
  private double geneticDiversity()
  {
    Random rando = new Random();
    if (populationSize() < 2) {
      return 0.0;
    }

    // count limits the number of genomes sampled for performance reasons.
    int count = Math.min(1000, populationSize());    // TODO: !!! p.analysisSampleSize;
    double numSamples = 0;
    double similaritySum = 0.0;

    while (count-- > 0) {
      int index0 = rando.nextInt(populationSize()-1); // skip first and last elements
      int index1 = index0 + 1;
      similaritySum += at(index0).getGenome().similarity(at(index1).getGenome());
      numSamples++;
    }

    return 1.0 - (similaritySum / numSamples);
  }

  /**
   * For informational purposes only, not the full creature datastructure
   */
  public List<Creature> getCreatures() {
    return populationSize()> 0?creatures.subList(0, creatures.size()): new ArrayList<Creature>();
  }

  public void queueForDeath(Creature deadCreature) {
    assert deadCreature.isAlive() :
    deadCreature;
    deathQueue.add(deadCreature);
  }
  public void drainDeathQueue() {
    if (deathQueue.size() == 0) return;
    for (Creature ghost : deathQueue) {
      grid.set(ghost.getLocation(), GridState.EMPTY);
      ghost.setAlive(false);
    }

    deathQueue.clear();
  }
  public void queueForMove(Creature creature, Coordinate newLocation) {
    assert creature.isAlive() :
    String.format("Creature isn't alive! %s", creature);

    moveQueue.add(new Object[]{creature, newLocation});
  }
  public void drainMoveQueue() {
    if (moveQueue.size() == 0) return;
    int index = 0;
    for (Object[] record : moveQueue) {
      if (record == null) {
        System.out.printf("moveQueue has a null value: moveQueue Size:%d, index: %d\n", moveQueue.size(), index);
        continue;
      }
      Creature creature = (Creature)record[0];
      if (creature.isAlive()) {
        Coordinate newLocation = (Coordinate)record[1];
        Direction moveDirection = new Direction(newLocation.subtract(creature.getLocation()));
        if (grid.isEmptyAt(newLocation)) {
          grid.set(creature.getLocation(), GridState.EMPTY);
          grid.set(newLocation, creature.getIndex());
          creature.setLocation(newLocation);
          creature.setLastMoveDirection(moveDirection);
        }
      }
      index++;
    }
    moveQueue.clear();
  }

  public int deathQueueSize() {
    return deathQueue.size();
  }

  // findCreature() does no error checking -- check first that loc is occupied
  public Creature findCreature(Coordinate coord) {
    return creatures.get(grid.at(coord));
  }

  public int populationSize() {
    return creatures.size();
  }
  // Direct access:
  public Creature at(int index) {
    return creatures.get(index);
  }

  public Grid getGrid() {
    return grid;
  }

  public Signals getSignals() {
    return signals;
  }

  void displaySampleGenomes(int count) {
    Random rando = new Random();
    System.out.printf("---------------------------\n");
    for (int index = rando.nextInt(populationSize()); count > 0; index=rando.nextInt(populationSize())) {
      Creature c = at(index);
      if (c.isAlive()) {
        System.out.printf("Individual:%s\niGraph:\n%s\n", c, c.toIGraph());
        --count;
      }
    }
    System.out.printf("---------------------------\n");

    displaySensorActionReferenceCounts();
  }

  void displaySensorActionReferenceCounts() {
    int[] sensorCounts = new int[Sensor.values().length];
    int[] actionCounts = new int[CreatureAction.values().length];

    for (Creature creature : getCreatures()) {
      if (creature.isAlive()) {
        for (Gene gene : creature.getBrain().getConnections()) {
          if (gene.getSource() == NeuronType.SENSOR) {
            assert gene.getSourceNumber() >= 0 && gene.getSourceNumber() < Sensor.values().length :
            String.format("large or negative sourceNumber:%d", gene.getSourceNumber());
            ++sensorCounts[gene.getSourceNumber()];
          }
          if (gene.getTarget() == NeuronType.ACTION) {
            assert gene.getTargetNumber() >= 0 && gene.getTargetNumber() < CreatureAction.values().length :
            String.format("large or negative targetNumber:%d", gene.getTargetNumber());
            ++actionCounts[gene.getTargetNumber()];
          }
        }
      }
    }

    System.out.printf("Sensors in use:\n");
    for (int i = 0; i < sensorCounts.length; ++i) {
      if (sensorCounts[i] > 0) {
        System.out.printf("  %d - %s\n", sensorCounts[i], Sensor.values()[i].getText());
      }
    }
    System.out.printf("Actions in use:\n");
    for (int i = 0; i < actionCounts.length; ++i) {
      if (actionCounts[i] > 0) {
        System.out.printf("  %d - %s\n", actionCounts[i], CreatureAction.values()[i].getName());
      }
    }
  }
}
