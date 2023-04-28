import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.List;
import java.util.ArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.IntStream;
import java.util.Calendar;
import java.util.Random;

ParamManager paramManager;
Random globalRandom;

void settings() {
  size((int)Configuration.SIZE_X.getValue() * (int)Configuration.AGENT_SIZE.getValue(), (int)Configuration.SIZE_Y.getValue() * (int)Configuration.AGENT_SIZE.getValue());
}

final static int BACKGROUND = 0;
boolean toggleDisplay = true; // true to show the display, false to let the sim run without updating the display
boolean toggleChallenge = true;
RunMode runMode = RunMode.STOP;
int generations = 0;
int simStep = 0;
int mouseNumber = 0;
AtomicInteger murderCount = new AtomicInteger();
Environment theEnvironment;
//List<List<Genome>> historyOfTheWorld = new ArrayList<List<Genome>>();
long genTimer;
String optionPrompt =
  "A or a - Load config file (default 'simulator.ini')\n"+
  "B or b - Start Simulation\n"+
  "C or c - Toggle Challenge display\n"+
  "L or l - Load creatures\n"+
  "M or m - m:Save barriers, M:Load barriers\n"+
  "P or p - pause/unpause\n"+
  "S or s - Save Creatures to file\n"+
  "T or t - Toggle display\nX or x - exit";
PrintWriter epochLog;

void setup() {
  paramManager = new ParamManager();
  String fileName = String.format("simulation-%1$tF-%1$ts_%2$s", Calendar.getInstance(), (String)Parameters.EPOCH_FILE_POST.getValue());
  epochLog = createWriter(fileName);
  theEnvironment = new Environment();
  globalRandom = (paramManager.getConfigs().deterministic)?new Random(paramManager.getConfigs().RNGSeed):new Random();

  colorMode(RGB, 255);
  background(255);
  fill(0);
  textSize(26);
  text(optionPrompt, 50, 50);
  println(optionPrompt);

  //Genome g = new Genome(0,theEnvironment);
  //g.allTests();

  //Direction d = new Direction();
  //d.allTests();

  //NeuralNet nn = new NeuralNet();
  //nn.allTests();

  //Coordinate c = new Coordinate().testAll();
  //Gene g = new Gene();
  //g.allTests();

  /* TODO:
   *  Modify to record a full history and then animate when finished (might speed up and smooth out animation)
   *  Between generations, visually show which ones survived (became parents) and which ones died
   *  Figure out how to introduce energy consumption and production
   *  Figure out how to give creatures an independent lifetime vs. 300 cycles for everyone all at once
   *  Figure out if a random spawn should be a configuration item
   */
}

/**
 * takes care of all the looping, just need to check where we are for each "step"
 */
void draw() {
  // are we in a generation?
  if (runMode == RunMode.RUN && generations < paramManager.getParams().maxGenerations) {
    // are we in a simulation step?
    int tempSteps = 0;
    if (simStep < paramManager.getParams().stepsPerGeneration) {
      while (tempSteps++ < (int)Parameters.STEPS_PER_FRAME.getValue() && simStep < paramManager.getParams().stepsPerGeneration) {
        // Loop through each individual in parallel
        IntStream.range(0, theEnvironment.populationSize()).parallel().forEach(indivIndex -> {
          //for (int indivIndex = 0; indivIndex < theEnvironment.populationSize(); indivIndex++) {
          //if (indivIndex < theEnvironment.populationSize()) {
          if (theEnvironment.at(indivIndex) != null && theEnvironment.at(indivIndex).isAlive()) {
            theEnvironment.at(indivIndex).simStepOneIndiv(simStep);
          }
        }
        );
        display();
        //} else {
        //  indivIndex = 0;
        //);
        //).join();

        // Single-threaded section: execute deferred deaths and movements,
        // update signal layers (pheromone), etc.
        murderCount.addAndGet(theEnvironment.deathQueueSize());
        theEnvironment.endOfSimStep(simStep, generations);
        simStep++;
      }
      display();
    } else {
      simStep = 0;
      List<Creature> survivors = theEnvironment.endOfGeneration(generations); 
      int numberSurvivors = survivors.size();
      System.out.printf("Generation:%d: ", generations);

      String genTime = getGenTime();
      if (numberSurvivors == 0) {
        System.out.printf("No survivors, resetting generation! timeElapsed:%s", genTime);
        generations = 0;  // start over
      } else {
        ++generations;
        System.out.printf("%d survivors(%.1f%%), timeElapsed:%s", numberSurvivors, 100.0*numberSurvivors/theEnvironment.populationSize(), genTime);
      }
      println();

      storeHistory();
      display();
      for(Creature c : survivors){
        c.display(color(10, 250, 10));
      }
      if (generations > 0 && generations % (int)Parameters.GENOME_SAVE_STRIDE.getValue() == 0) saveGeneration(generations, String.format("autosave-generation-%2$d-%1$tF-%1$ts.bin", Calendar.getInstance(), generations));
    }
  } else {
    runMode = RunMode.STOP;
  }
}

private void storeHistory() {
  List<Genome> creatureGenomes = new ArrayList<Genome>();
  for (Creature c : theEnvironment.getCreatures()) {
    creatureGenomes.add(new Genome(c.getGenome().getGenome()));
  }
}

private String getGenTime() {
  long endTime = System.currentTimeMillis() - genTimer;
  genTimer = System.currentTimeMillis();

  long hours = TimeUnit.MILLISECONDS.toHours(endTime);
  long minutes = TimeUnit.MILLISECONDS.toMinutes(endTime) % 60;
  long seconds = TimeUnit.MILLISECONDS.toSeconds(endTime) % 60;
  long millis = endTime % 1000;

  String timeDiffStr = String.format("%d:%02d:%02d.%03d", hours, minutes, seconds, millis);
  return timeDiffStr;
}

public void display() {
  if (!toggleDisplay) return;

  background(BACKGROUND);
  theEnvironment.getGrid().display();
  for (Creature c : theEnvironment.getCreatures()) {
    if (c != null && c.isAlive()) {
      c.display();
    }
  }
}

// Leaving this here to remind me not to do this
//public void display() {
//  background(BACKGROUND);
//  grid.display();
//  creatures.parallelStream()
//    .filter(Objects::nonNull)
//    .filter(Creature::isAlive)
//    .forEach(Creature::display);
//}

void keyPressed() {
  switch(key) {
  case 'a':
  case 'A':
      if (runMode != RunMode.STOP && runMode != RunMode.PAUSE) break;
      selectInput("Select the configuration file to load", "configFileSelected");
      break;
  case 'b':
  case 'B':
    // Start the show with a random set of guys
    System.out.printf("Starting simulation...");
    runMode = startSimulator();
    System.out.printf("...Started");
    break;
  case 'c':
  case 'C':
    {
      toggleChallenge = !toggleChallenge;
      break;
    }
  case 'p':
  case 'P':
    {
      // pause
      runMode = (runMode == RunMode.RUN)?RunMode.PAUSE:RunMode.RUN;
      if (runMode == RunMode.RUN) loop();
      else noLoop();
      break;
    }
  case 's':
  case 'S':
    {
      if (runMode != RunMode.PAUSE) break;
      saveGeneration(generations, String.format("generation-%2$d-%1$tF-%1$ts.bin", Calendar.getInstance(), generations));
      break;
    }
  case 'l':
  case 'L':
    {
      if (runMode != RunMode.STOP && runMode != RunMode.PAUSE) break;
      selectInput("Select a file with the creatures to load", "fileSelected");
      break;
    }
  case 't':
  case 'T':
    {
      // use this to toggle the display to allow the sim to run in the background without an update or run real time
      if (runMode != RunMode.RUN) break;
      toggleDisplay = !toggleDisplay;
      background(255);
      fill(0);
      textSize(20);
      text("Simulating in the background...\n\n"+optionPrompt, 50, 50);
      break;
    }
  case 'm':
    {
      if (runMode != RunMode.PAUSE) break;
      // Save the barriers!
      theEnvironment.getGrid().saveBarrierState();
      break;
    }
  case 'M':
    {
      selectInput("Select a file with barriers to load", "barrierFileSelected");
      break;
    }
  case 'x':
  case 'X':
    // shut down the simulation
    exit();
  }
}

void exit() {
  epochLog.flush();
  epochLog.close();
  super.exit();
}

void saveGeneration(int generation, String fileName) {
  System.out.printf("Saving generation %d to %s...", generation, fileName);
  PrintWriter output = createWriter(fileName);
  String line = String.format("%d|", generation);
  for (Creature c : theEnvironment.getCreatures()) {
    Genome genome = c.getGenome();
    //for (Genome genome : historyOfTheWorld.get(generation)) {
    boolean comma = false;
    line += "[";
    for (Gene gene : genome.getGenome()) {
      if (comma) line += ",";
      for (byte b : gene.getBlueprint()) {
        line += String.format("%02X", b);
      }
      comma = true;
    }
    line += "]";
  }
  output.println(line);

  output.flush();
  output.close();
  System.out.println("...done");
}

void configFileSelected(File selection) {
  if (selection == null) {
    System.out.printf("No file was selected, moving on\n");
  } else {
    System.out.printf("User selected %s\n", selection.getAbsolutePath());
    paramManager.registerConfigFile(selection);
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    System.out.printf("No file was selected, moving on\n");
  } else {
    System.out.printf("User selected %s\n", selection.getAbsolutePath());
    // load the guys and start the show
    toggleDisplay = true;
    runMode = startSimulator(selection);
  }
}

void barrierFileSelected(File selection) {
  if (selection == null) {
    System.out.printf("No file was selected, moving on\n");
  } else {
    System.out.printf("User selected %s for barriers\n", selection.getAbsolutePath());
    toggleDisplay = true;
    theEnvironment.getGrid().loadBarriers(selection.getAbsolutePath());
  }
}


void mousePressed() {
  switch(mouseButton) {
  case LEFT:
    {
      if (RunMode.STOP != runMode) {
        runMode = (runMode == RunMode.RUN)?RunMode.PAUSE:RunMode.RUN;
        if (runMode == RunMode.RUN) loop();
        else noLoop();
      }
      break;
    }
  case RIGHT:
    {
      Coordinate mouseLocation = new Coordinate(mouseX/(int)Configuration.AGENT_SIZE.getValue(), mouseY/(int)Configuration.AGENT_SIZE.getValue());
      System.out.printf("Gen:%d.%d, Mouse(%d, %d)==%s\n", generations, simStep, mouseX, mouseY, mouseLocation);
      if (!theEnvironment.getGrid().isOccupiedAt(mouseLocation)) return;

      int creatureIndex = theEnvironment.getGrid().at(mouseLocation);
      Creature creature = theEnvironment.at(creatureIndex);
      println(creature);
      println(creature.toIGraph());
      break;
    }
  case CENTER:
    break;
  }
}

int[] getRealLocation(Creature creature) {
  Coordinate location = creature.getLocation();
  int[] realLocation = new int[]{
    location.getX()*(int)Configuration.AGENT_SIZE.getValue()+(int)Configuration.AGENT_SIZE.getValue()/2,
    location.getY()*(int)Configuration.AGENT_SIZE.getValue()+(int)Configuration.AGENT_SIZE.getValue()/2
  };

  return realLocation;
}

/*
 * Start of simulator
 *
 * All the agents are randomly placed with random genomes at the start. The outer
 * loop is generation, the inner loop is simStep. There is a fixed number of
 * simSteps in each generation. Agents can die at any simStep and their corpses
 * remain until the end of the generation. At the end of the generation, the
 * dead corpses are removed, the survivors reproduce and then die. The newborns
 * are placed at random locations, signals (pheromones) are updated, simStep is
 * reset to 0, and a new generation proceeds.
 *
 * The paramManager manages all the simulator parameters. It starts with defaults,
 * then keeps them updated as the config file (biosim4.ini) changes.
 *
 * The main simulator-wide data structures are:
 * grid - where the agents live (identified by their non-zero index). 0 means empty.
 * signals - multiple layers overlay the grid, hold pheromones
 * peeps - an indexed set of agents of type Indiv; indexes start at 1
 *
 * The important simulator-wide variables are:
 * generation - starts at 0, then increments every time the agents die and reproduce.
 * simStep - reset to 0 at the start of each generation; fixed number per generation.
 * randomUint - global random number generator
 *
 * The threads are:
 * main thread - simulator
 * simStepOneIndiv() - child threads created by the main simulator thread
 * imageWriter - saves image frames used to make a movie (possibly not threaded
 * due to unresolved bugs when threaded)
 */
public RunMode startSimulator(File file) {
  paramManager.updateFromConfigFile(0);
  
  genTimer = System.currentTimeMillis();
  theEnvironment.getGrid().initialize((int)Configuration.SIZE_X.getValue(), (int)Configuration.SIZE_Y.getValue());
  theEnvironment.getSignals().initialize((int)Configuration.SIGNAL_LAYERS.getValue(), (int)Configuration.SIZE_X.getValue(), (int)Configuration.SIZE_Y.getValue());
  theEnvironment.initialize();
  murderCount.set(0);


  if (file == null) {
    theEnvironment.initializeGeneration0((int)Configuration.POPULATION.getValue());
  } else {
    theEnvironment.initializeGeneration0(file.getAbsolutePath());
  }

  //int index = Math.abs(new Random().nextInt(theEnvironment.populationSize()));
  //historyOfTheWorld.clear();
  //List<Genome> creatureGenomes = new ArrayList<Genome>();
  //historyOfTheWorld.add(creatureGenomes);
  //for (Creature c : theEnvironment.getCreatures()) {
  //  creatureGenomes.add(new Genome(c.getGenome().getGenome()));
  //}
  // Define atomic integer to count the number of deaths

  // Start parallel section
  //IntStream.range(0, (int)Parameters.NUM_THREADS.getValue()).parallel().forEach(threadIndex -> {
  // generation loop

  //);
  return RunMode.RUN;
}
public RunMode startSimulator() {
  return startSimulator(null);
}
