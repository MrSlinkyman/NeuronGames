import java.util.List; //<>// //<>//
import java.util.Iterator;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import java.util.Collections;
//import org.neuroph.core.data.DataSet;
//import org.neuroph.core.data.DataSetRow;
//import org.neuroph.core.learning.IterativeLearning;
//import org.neuroph.core.Neuron;
//import org.neuroph.nnet.comp.neuron.InputOutputNeuron;
//import org.neuroph.core.input.Sum;
//import org.neuroph.core.transfer.Tanh;


class NeuralNet {
  List<Gene> connections;
  List<CreatureNeuron> neurons;
  Creature creature;

  NeuralNet() {
    // for testing
  }

  NeuralNet(Creature creature) {
    this.neurons = new ArrayList<CreatureNeuron>();
    this.connections = new ArrayList<Gene>();
    this.creature = creature;
    createWiringFromGenome(creature.getGenome());
  }

  public String toString() {
    String r = "Network:\n";
    for (Gene connection : connections) {
      r+=String.format("\t%s\n",connection);
    }
    for (CreatureNeuron neuron : neurons) {
      r+=String.format("\t%s\n",neuron);
    }
    return r;
  }

  public List<Gene> getConnections() {
    return connections;
  }
  /**
    * This function does a neural net feed-forward operation, from sensor (input) neurons
    * through internal neurons to action (output) neurons. The feed-forward
    * calculations are evaluated once each simulator step (simStep).
    * 
    * There is no back-propagation in this simulator. Once an individual's neural net
    * brain is wired at birth, the weights and topology do not change during the
    * individual's lifetime.
    * 
    * The neurons list contains internal neurons, and the connections list
    * holds the connections between the neurons.
    * 
    * We have three types of neurons:
    * 
    * input sensors - each gives a value in the range (0.0..1.0).
    * Values are obtained from getSensor().
    * 
    * internal neurons - each takes inputs from sensors or other internal neurons;
    * each has output value in the range (-1.0..1.0). The output value for each neuron
    * is stored in the neurons list and survives from one simStep to the next. 
    * (For example, a neuron that feeds itself will use its output value that was
    * latched from the previous simStep.) Inputs to the neurons are summed each simStep
    * in a temporary container and then discarded after the neurons' outputs are computed.
    * 
    * action (output) neurons - each takes inputs from sensors or other internal
    * neurons; In this function, each has an output value in an arbitrary range
    * (because they are the raw sums of zero or more weighted inputs).
    * The values of the action neurons are saved in local container
    * actionLevels[] which is returned to the caller by value (thanks RVO).
    */
  public double[] feedForward(int simStep)
  {
    // This container is used to return values for all the action outputs. This array
    // contains one value per action neuron, which is the sum of all its weighted
    // input connections. The sum has an arbitrary range. Return by value assumes compiler
    // return value optimization.
    double[] actionLevels = new double[CreatureAction.values().length];
    Arrays.fill(actionLevels, 0.0);


    // Weighted inputs to each neuron are summed in neuronAccumulators[]
    double[] neuronAccumulators = new double[neurons.size()];
    Arrays.fill(neuronAccumulators, 0.0);

    // Connections were ordered at birth so that all connections to neurons get
    // processed here before any connections to actions. As soon as we encounter the
    // first connection to an action, we'll pass all the neuron input accumulators
    // through a transfer function and update the neuron outputs in the indiv,
    // except for undriven neurons which act as bias feeds and don't change. The
    // transfer function will leave each neuron's output in the range -1.0..1.0.
    boolean neuronOutputsComputed = false;
    for (Gene conn : connections) {
      if (conn.getTarget() == NeuronType.ACTION && !neuronOutputsComputed) {
        // We've handled all the connections from sensors and now we are about to
        // start on the connections to the action outputs, so now it's time to
        // update and latch all the neuron outputs to their proper range (-1.0..1.0)
        for (int neuronIndex = 0; neuronIndex < neurons.size(); neuronIndex++) {
          if (neurons.get(neuronIndex).isDriven()) {
            neurons.get(neuronIndex).setOutput((double)Math.tanh(neuronAccumulators[neuronIndex]));
          }
        }
        neuronOutputsComputed = true;
      }

      // Obtain the connection's input value from a sensor neuron or other neuron
      // The values are summed for now, later passed through a transfer function
      double inputVal;
      if (conn.getSensor() == NeuronType.SENSOR) {
        inputVal = creature.getSensor(Sensor.values()[conn.getSensorSource()], simStep);
      } else {
        assert conn.getSensorSource() < neurons.size() :
        String.format("neurons:%d <= sensorSource:%d, connection:%s, creature:%s", neurons.size(), conn.getSensorSource(), conn, creature);
        inputVal = neurons.get(conn.getSensorSource()).getOutput();
      }

      // Weight the connection's value and add to neuron accumulator or action accumulator.
      // The action and neuron accumulators will therefore contain +- float values in
      // an arbitrary range.
      if (conn.getTarget() == NeuronType.ACTION) {
        actionLevels[conn.getTargetSource()] += inputVal * conn.getWeight();
      } else {
        assert conn.getTargetSource() < neuronAccumulators.length :
        String.format("neuronAccumulators:%d <= targetSource:%d, neurons:%d, connection:%s, creature:%s", neuronAccumulators.length, conn.getTargetSource(), neurons.size(), conn, creature);
        neuronAccumulators[conn.getTargetSource()] += (double)inputVal * conn.getWeight();
      }
    }

    return actionLevels;
  }

  public void printFirst(String text, Object... values) {
    if (creature.getIndex() == 0) {
      Parameters.debugOutput(text, values);
    }
  }

  public void renumberNeurons(Map<Short, Node> nodeMap) {
    assert nodeMap.size() <= (int)Configuration.MAX_NUMBER_NEURONS.getValue() :
    String.format("NodeMap is too big: %d > %d", nodeMap.size(), (int)Configuration.MAX_NUMBER_NEURONS.getValue());
    int newNumber = 0;
    for (Map.Entry<Short, Node> entrySet : nodeMap.entrySet()) {
      Node node = entrySet.getValue();
      printFirst("in renumberNeurons: node:%s at:%d,", node, entrySet.getKey());
    assert node.numOutputs != 0 :
      String.format("this node has too many outputs:%d, node:%s at:%d", node.numOutputs, node, entrySet.getKey());
      node.remappedNumber = newNumber++;
      printFirst("newNode:%s\n", node);
    }
  }

  public List<CreatureNeuron> createNeurons(Map<Short, Node> nodeMap) {
    // Create the indiv's neural node list
    List<CreatureNeuron> newNeurons = new ArrayList<CreatureNeuron>(nodeMap.size());

    for (Map.Entry<Short, Node> mapItem : nodeMap.entrySet()) {
      Node node = mapItem.getValue();
      printFirst("Adding node:%s at%d to neurons\n", node, mapItem.getKey());
      CreatureNeuron newNneuron =new CreatureNeuron(mapItem.getKey(),
        (node.numInputsFromSensorsOrOtherNeurons != 0),
        (double)Parameters.INITIAL_NEURON_OUTPUT.getValue());
      newNeurons.add(newNneuron);
      printFirst("Created neuron:%s to neurons:%d\n", newNneuron, newNeurons.size());
    }
    return newNeurons;
  }

  // Create the indiv's connection list in two passes:
  // First the connections to neurons, then the connections to actions.
  // This ordering optimizes the feed-forward function in feedForward.cpp.
  public List<Gene> createConnections(List<Gene> connectionList, Map<Short, Node> nodeMap) {
    List<Gene> newConnections = new ArrayList<Gene>(connectionList.size());

    // First, the connections from sensor or neuron to a neuron
    for (Gene conn : connectionList) {
      if (conn.target == NeuronType.NEURON) {
        newConnections.add(conn);
        printFirst("in createConnections, adding conn target:NEURON:%s\n", conn);
        // fix the destination neuron number
        conn.setTargetSource((short)nodeMap.get(conn.getTargetSource()).remappedNumber);
        // if the source is a neuron, fix its number too
        if (conn.sensor == NeuronType.NEURON) {
          conn.setSensorSource((short)nodeMap.get(conn.getSensorSource()).remappedNumber);
        }
        printFirst("in createConnections, fixed conn:%s\n", conn);
      }
    }

    // Last, the connections from sensor or neuron to an action
    for (Gene conn : connectionList) {
      if (conn.target == NeuronType.ACTION) {
        newConnections.add(conn);
        printFirst("in createConnections, added conn target:ACTION:%s\n", conn);

        // if the source is a neuron, fix its number
        if (conn.sensor == NeuronType.NEURON) {
          Node n = nodeMap.get(conn.getSensorSource());
        assert n!= null:
          String.format("null sensor:%d", conn.getSensorSource());
          conn.setSensorSource((short)n.remappedNumber);
        }
        printFirst("in createConnections, fixed conn:%s\n", conn);
      }
    }

    return newConnections;
  }

  /**
   * makeRenumberedConnectionList creates a new List<Gene> from the given Genome.
   */
  private List<Gene> makeRenumberedConnectionList(Genome genome)
  {
    assert genome != null && genome.size() > 0 :
    String.format("trying to renumber empty genome");
    printFirst("in makeRenumberedConnectionList with genome:%s\n", genome);

    List<Gene> connectionList = new ArrayList<Gene>(genome.size());

    for (Gene gene : genome.genes) {
      Gene connection = new Gene(gene.getBlueprint());
      printFirst("in makeRenumberedConnectionList#orig gene:%s\n", connection);

      connectionList.add(connection);
      int origSensorSource = connection.getSensorSource();
      int origTargetSource = connection.getTargetSource();
      connection.setSensorSource((short)(connection.getSensorSource() % ((NeuronType.NEURON == connection.getSensor()) ?
        (int)Configuration.MAX_NUMBER_NEURONS.getValue() :
        Sensor.values().length)));

      connection.setTargetSource((short)(connection.getTargetSource() % ((NeuronType.NEURON == connection.getTarget())?
        (int)Configuration.MAX_NUMBER_NEURONS.getValue() :
        CreatureAction.values().length)));

      if (origSensorSource != connection.getSensorSource())
        Parameters.debugOutput("Had to renumber sensor connection:%s, (%d > %d)\n", connection, origSensorSource, connection.getSensorSource());
      if (origTargetSource != connection.getTargetSource())
        Parameters.debugOutput("Had to renumber target connection:%s, (%d > %d)\n", connection, origTargetSource, connection.getTargetSource());

      printFirst("in makeRenumberedConnectionList#mods gene:%s\n", connection);
    }
    return connectionList;
  }

  //private void makeNodeList(Gene[] theseConnections) {
  public Map<Short, Node> makeNodeList(List<Gene> connectionList) {
    printFirst("in makeNodeList with connections:%d\n", connectionList.size());
    Map<Short, Node> nodeMap = new HashMap<Short, Node>();

    for (Gene gene : connectionList) {
      Gene connection = new Gene(gene.getBlueprint());
      printFirst("  connection:%s\n", connection);
      if (NeuronType.NEURON == connection.getTarget()) {
        Node node = nodeMap.get(connection.getTargetSource());
        printFirst("    target:NEURON at%d node:%s\n", connection.getTargetSource(), node);
        if (node == null) {
          assert connection.getTargetSource()>=0 && connection.getTargetSource() < (int)Configuration.MAX_NUMBER_NEURONS.getValue():
          String.format("  targetSource negative or too big:%d", connection.getTargetSource());
          node = new Node();
          nodeMap.put(connection.getTargetSource(), node);
          printFirst("      NEW target:NEURON at:%d node:%s\n", connection.getTargetSource(), node);
        }

        if (NeuronType.NEURON == connection.getSensor() && connection.getSensorSource() == connection.getTargetSource()) {
          ++node.numSelfInputs;
        } else {
          ++node.numInputsFromSensorsOrOtherNeurons;
        }
        printFirst("    FINAL target:NEURON at:%d node:%s\n", connection.getTargetSource(), node);
      }

      if (NeuronType.NEURON == connection.getSensor()) {
        Node node = nodeMap.get(connection.getSensorSource());
        printFirst("    sensor:NEURON at:%d node:%s\n", connection.getSensorSource(), node);
        if (node == null) {
          assert connection.getSensorSource()>= 0 && connection.getSensorSource() < (int)Configuration.MAX_NUMBER_NEURONS.getValue():
          String.format("negative or large sensorSource:%d", connection.getSensorSource());
          node = new Node();
          nodeMap.put(connection.getSensorSource(), node);
          printFirst("      NEW sensor:NEURON at:%d node:%s\n", connection.getSensorSource(), node);
        }

        ++node.numOutputs;
        printFirst("    FINAL sensor:NEURON at:%d node:%s\n", connection.getSensorSource(), node);
      }
    }
    return nodeMap;
  }

  public void removeConnectionsToNeuron(List<Gene> connectionList, int neuronNumber, Map<Short, Node> nodeMap)
  {
    Iterator<Gene> iter = connectionList.iterator();
    while (iter.hasNext()) {
      Gene gene = iter.next();
      printFirst("this gene:%s\n", gene);
      if (gene.getTarget() == NeuronType.NEURON && gene.getTargetSource() == neuronNumber) {
        // Remove the connection. If the connection source is from another
        // neuron, also decrement the other neuron's numOutputs:
        if (gene.getSensor() == NeuronType.NEURON) {
          (nodeMap.get(gene.getSensorSource())).numOutputs--;
          printFirst("devrementing referenced sensor:NEURON:%d, numOutputs:%d\n", gene.getSensorSource(), (nodeMap.get(gene.getSensorSource())).numOutputs);
        }
        printFirst("removing referenced target:NEURON:%d\n", neuronNumber);
        iter.remove();
      }
    }
  }

  // If a neuron has no outputs or only outputs that feed itself, then we
  // remove it along with all connections that feed it. Reiterative, because
  // after we remove a connection to a useless neuron, it may result in a
  // different neuron having no outputs.
  public void cullUselessNeurons(List<Gene> connectionList, Map<Short, Node> nodeMap)
  {
    boolean allDone = false;
    while (!allDone) {
      allDone = true;
      Iterator<Map.Entry<Short, Node>> iter = nodeMap.entrySet().iterator();
      while (iter.hasNext()) {
        Map.Entry<Short, Node> entrySet = iter.next();
        assert entrySet.getKey() < (int)Configuration.MAX_NUMBER_NEURONS.getValue() :
        String.format("Found a node index too big:%d >= %d", entrySet.getKey(), (int)Configuration.MAX_NUMBER_NEURONS.getValue());
        // We're looking for neurons with zero outputs, or neurons that feed itself
        // and nobody else:
        if (entrySet.getValue().numOutputs == entrySet.getValue().numSelfInputs) {  // could be 0
          printFirst("found a useless neuron:(%d,%s)\n", entrySet.getKey(), entrySet.getValue());
          allDone = false;
          // Find and remove connections from sensors or other neurons
          removeConnectionsToNeuron(connectionList, entrySet.getKey(), nodeMap);
          iter.remove();
        }
      }
    }
  }

  // This function is used when an agent is spawned. This function converts the
  // agent's inherited genome into the agent's neural net brain. There is a close
  // correspondence between the genome and the neural net, but a connection
  // specified in the genome will not be represented in the neural net if the
  // connection feeds a neuron that does not itself feed anything else.
  // Neurons get renumbered in the process:
  // 1. Create a set of referenced neuron numbers where each index is in the
  //    range 0..p.genomeMaxLength-1, keeping a count of outputs for each neuron.
  // 2. Delete any referenced neuron index that has no outputs or only feeds itself.
  // 3. Renumber the remaining neurons sequentially starting at 0.
  private void createWiringFromGenome(Genome genome)
  {
    // list of neurons and their number of inputs and outputs
    //this.nodeMap = new HashMap<Short, Node>();

    //ConnectionList connectionList; // synaptic connections

    // Convert the indiv's genome to a renumbered connection list
    List<Gene> connectionList = makeRenumberedConnectionList(genome);
    printFirst("in createWiringFromGenome, after madeRenumberedConnectionList, genome:%s, connectionList:%d\n", genome, connectionList.size());

    // Make a node (neuron) list from the renumbered connection list
    Map<Short, Node> nodeMap = makeNodeList(connectionList);
    printFirst("in createWiringFromGenome, after makeNodeList, genome:%s, connectionList:%d, nodeMap:%d\n", genome, connectionList.size(), nodeMap.size());

    // Find and remove neurons that don't feed anything or only feed themself.
    // This reiteratively removes all connections to the useless neurons.
    cullUselessNeurons(connectionList, nodeMap);

    // At this point, connectionList and nodeMap have been properly sanitized
    printFirst("in createWiringFromGenome, after cullUselessNeurons, genome:%s, connectionList:%d, nodeMap:%d\n", genome, connectionList.size(), nodeMap.size());

    // The neurons map now has all the referenced neurons, their neuron numbers, and
    // the number of outputs for each neuron. Now we'll renumber the neurons
    // starting at zero.
    renumberNeurons(nodeMap);
    printFirst("in createWiringFromGenome, after renumberedNeurons, genome:%s, connectionList:%d, nodeMap:%d\n", genome, connectionList.size(), nodeMap.size());

    // Create the indiv's connection list in two passes:
    // First the connections to neurons, then the connections to actions.
    // This ordering optimizes the feed-forward function in feedForward.cpp.

    this.connections = createConnections(connectionList, nodeMap);
    printFirst("in createWiringFromGenome, after createConnections, genome:%s, connections:%d, nodeMap:%d\n", genome, connections.size(), nodeMap.size());

    this.neurons = createNeurons(nodeMap);
    printFirst("in createWiringFromGenome, after createNeurons, genome:%s, connections:%d, nodeMap:%d, neurons:%d\n", genome, connections.size(), nodeMap.size(), neurons.size());

    for (Gene gene : connections) {
      printFirst("\tgene:%s\n", gene);
    }
    for (CreatureNeuron neuron : neurons) {
      printFirst("\tneuron:%s\n", neuron);
    }
  }


  private String getMethod() {
    return String.format("%s#%s", StackWalker.getInstance().walk(frames -> frames
      .skip(1)
      .findFirst()
      .map(StackWalker.StackFrame::getClassName)).get(),
      StackWalker.getInstance().walk(frames -> frames
      .skip(1)
      .findFirst()
      .map(StackWalker.StackFrame::getMethodName)).get());
  }

  // ** TESTS **
  public void allTests() {
    testGenomeToNN();
  }

  private void testGenomeToNN() {
    Environment e = new Environment();
    String[] geneSequence = new String[]{"01081EE4", "00817024", "93811602", "010DAFB1", "8608DEE9", "008382A0"};
    Genome g = new Genome(geneSequence);
    Gene[] myGenome = g.getGenome();
    System.out.printf("My Genome:%s\n", g);
    e.getGrid().initialize((int)Configuration.SIZE_X.getValue(), (int)Configuration.SIZE_Y.getValue());
    e.getSignals().initialize((int)Configuration.SIGNAL_LAYERS.getValue(), (int)Configuration.SIZE_X.getValue(), (int)Configuration.SIZE_Y.getValue());
    e.initialize();
    e.creatures.add(null);
    Creature creature = new Creature(0, new Coordinate(3, 5), g, e);
    e.creatures.add(creature);
    System.out.printf("My Creature:%s\n", creature);
    for (int j = 0; j < 5; j++) {
      for (int i = 0; i < 300; i++) {
        creature.simStepOneIndiv(i);
        murderCount.addAndGet(e.deathQueueSize());
        e.endOfSimStep(i, 0);
        System.out.printf("done with step %d, creature:%s\n", i, creature);
      }
      // Single-threaded section: end of generation processing
      e.endOfGeneration(j);
      //paramManager.updateFromConfigFile(generation + 1);
      int numberSurvivors = e.spawnNewGeneration(j, murderCount.get());
      if (numberSurvivors > 0) {
        e.displaySampleGenomes(1);
      }

      System.out.printf("Num survivors:%d!\n", numberSurvivors);
    }
  }
}

enum NeuronType {
  SENSOR,
    ACTION,
    NEURON;
}

class CreatureNeuron {
  private int index;
  private boolean driven;
  private double output;

  CreatureNeuron (int index, boolean driven, double output) {
    this.index = index; 
    this.driven = driven;
    this.output = output;
  }

  // Getters
  public int getIndex() {
    return index;
  }

  public boolean isDriven() {
    return driven;
  }

  public double getOutput() {
    return output;
  }

  // Setters
  public void setIndex(int index) {
    this.index = index;
  }

  public void setDriven(boolean driven) {
    this.driven = driven;
  }

  public void setOutput(double output) {
    this.output = output;
  }

  public String toString() {
    return String.format("N%d: driven(%b), output(%f)", index, driven, output);
  }
}
