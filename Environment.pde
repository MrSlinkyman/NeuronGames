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

  // TODO: refactor to a getter/setter
  public int[] genomeInitialRange = new int[]{(int)Parameters.GENOME_INITIAL_LENGTH_MIN.getValue(), (int)Parameters.GENOME_INITIAL_LENGTH_MAX.getValue()};

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
    //  Coordinate location = new Coordinate().randomize((int)Parameters.SIZE_X.getValue(), (int)Parameters.SIZE_Y.getValue());
    //  Genome genome = new Genome(0, this).randomize();
    //  Creature c = new Creature(i, location, genome, this);
    //  creatures.add(c);
    //}
    //return creatures.subList(1, creatures.size());
  }

  public void initializeGeneration0(String fileToLoad) {
    grid.zeroFill();
    grid.createBarrier();
    signals.zeroFill();
    creatures.clear();

    // Add an empty creature at position 0 TODO is this right?
    creatures.add(null);

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

    // Add an empty creature at position 0 TODO is this right?
    creatures.add(null);

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
      for (int i = 0; i < populationSize(); i++) {
        addCreature(new Creature(i, grid.findEmptyLocation(), new Genome(parents), this));
      }
    } else {
      System.out.printf("No parents at generation%d\n", generation);
    }
  }

  private void addCreature(Creature c) {
    if (c.getIndex()+1 > populationSize()) {
      creatures.add(c);
    } else {
      creatures.set(c.getIndex()+1, c);
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
      int radioactiveX = (simStep < (int)Parameters.STEPS_PER_GENERATION.getValue() * Challenge.RADIOACTIVE_WALLS.getParameter(0)) ? 0 : (int)Parameters.SIZE_X.getValue() - 1;

      IntStream.range(0, populationSize()).parallel().forEach(index -> {
        Creature indiv = at(index);
        if (indiv.isAlive()) {
          int distanceFromRadioactiveWall = Math.abs(indiv.getLocation().getX() - radioactiveX);
          if (distanceFromRadioactiveWall < (int)Parameters.SIZE_X.getValue() *Challenge.RADIOACTIVE_WALLS.getParameter(1)) {
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
        if (indiv.getLocation().getX() == 0 || indiv.getLocation().getX() == (int)Parameters.SIZE_X.getValue() - 1
          || indiv.getLocation().getY() == 0 || indiv.getLocation().getY() == (int)Parameters.SIZE_Y.getValue() - 1) {
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
  public int endOfGeneration(int generation) {
    // TODO: Save video0
    Parameters.debugOutput("End of Generation %d\n", generation);
    // TODO: Save stats to console or somewhere

    int numberSurvivors = spawnNewGeneration(generations, murderCount.get());
    if (numberSurvivors > 0 && (generation % (int)Parameters.GENOME_ANALYSIS_STRIDE.getValue() == 0)) {
      displaySampleGenomes((int)Parameters.DISPLAY_SAMPLE_GENOMES.getValue());
    }
    return numberSurvivors;
  }

  // At this point, the deferred death queue and move queue have been processed
  // and we are left with zero or more individuals who will repopulate the
  // world grid.
  // In order to redistribute the new population randomly, we will save all the
  // surviving genomes in a container, then clear the grid of indexes and generate
  // new individuals. This is inefficient when there are lots of survivors because
  // we could have reused (with mutations) the survivors' genomes and neural
  // nets instead of rebuilding them.
  // Returns number of survivor-reproducers.
  // Must be called in single-thread mode between generations.
  public int spawnNewGeneration(int generation, int murderCount) {
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
        // ToDo: if the parents no longer need their genome record, we could
        // possibly do a move here instead of copy, although it's doubtful that
        // the optimization would be noticeable.
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

    // Sort the indexes of the parents by their fitness scores
    List<Map.Entry<Integer, Double>> sortedParents = new ArrayList<Map.Entry<Integer, Double>>(parents.entrySet());
    Collections.sort(sortedParents, new Comparator<Map.Entry<Integer, Double>>() {
      public int compare(Map.Entry<Integer, Double> parent1, Map.Entry<Integer, Double> parent2) {
        return Double.compare(parent2.getValue(), parent1.getValue());
      }
    }
    );

    for (Map.Entry<Integer, Double> parent : sortedParents) {
      parentGenomes.add(at(parent.getKey()).getGenome());
    }

    if (!parentGenomes.isEmpty()) {
      initializeNewGeneration(parentGenomes, generation + 1);
    } else {
      initializeGeneration0(populationSize());
    }

    return parentGenomes.size();
  }

  /**
   * For informational purposes only, not the full creature datastructure
   */
  public List<Creature> getCreatures() {
    return populationSize()> 0?creatures.subList(1, creatures.size()): new ArrayList<Creature>();
  }

  public void queueForDeath(Creature deadCreature) {
    assert deadCreature.isAlive() :
    deadCreature;
    deathQueue.add(deadCreature);
  }
  public void drainDeathQueue() {
    for (Creature ghost : deathQueue) {
      grid.set(ghost.getLocation(), GridState.EMPTY);
      ghost.setAlive(false);
    }

    deathQueue.clear();
  }
  public void queueForMove(Creature creature, Coordinate newLocation) {
    assert creature.isAlive() :
    creature;

    moveQueue.add(new Object[]{creature, newLocation});
  }
  public void drainMoveQueue() {

    for (Object[] record : moveQueue) {
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
    return creatures.size()-1;
  }
  // Direct access:
  public Creature at(int index) {
    return creatures.get(index+1);
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
        System.out.printf("Individual:%s\niGraph:\n%s\n", c,c.toIGraph());
        --count;
      }
    }
    System.out.printf("---------------------------\n");

    displaySensorActionReferenceCounts();
  }

  void displaySensorActionReferenceCounts() {
    int[] sensorCounts = new int[Sensor.values().length];
    int[] actionCounts = new int[CreatureAction.values().length];

    for (int index = 0; index < populationSize(); ++index) {
      Creature creature = at(index);
      if (creature.isAlive()) {
        for (Gene gene : creature.getBrain().getConnections()) {
          if (gene.getSensor() == NeuronType.SENSOR) {
            assert gene.getSensorSource() >= 0 && gene.getSensorSource() < Sensor.values().length :
            String.format("large or negative sensorSource:%d", gene.getSensorSource());
            ++sensorCounts[gene.getSensorSource()];
          }
          if (gene.getTarget() == NeuronType.ACTION) {
            assert gene.getTargetSource() >= 0 && gene.getTargetSource() < CreatureAction.values().length :
            String.format("large or negative targetSource:%d", gene.getTargetSource());
            ++actionCounts[gene.getTargetSource()];
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
