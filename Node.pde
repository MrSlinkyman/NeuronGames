class Node {
  int remappedNumber;
  int numOutputs;
  int numSelfInputs;
  int numInputsFromSensorsOrOtherNeurons;

  Node() {
    remappedNumber = 0;
    numOutputs = 0;
    numSelfInputs = 0;
    numInputsFromSensorsOrOtherNeurons = 0;
  }

  public String toString() {
    return String.format("Node(remapped:%d, #out:%d, #selfIn:%d, #otherIn:%d)", remappedNumber, numOutputs, numSelfInputs, numInputsFromSensorsOrOtherNeurons);
  }
}
