class NeuralNet {
  Gene[] connections;
  Neuron[] neurons;
  NeuralNetwork neuralNetwork;

  NeuralNet(Genome genome, Environment environment) {
    connections = new Gene[genome.getGenome().length];
    neurons = new Neuron[]{};

    for (int i = 0; i < genome.getGenome().length; i++) {
      Gene gene = genome.getGenome()[i];
      connections[i] = new Gene(gene.getBlueprint());
    }
  }
  
//  private void makeRenumberedConnectionList(Gene[] connections, Genome genome)
//{
//    connectionList.clear();
//    for (auto const &gene : genome) {
//        connectionList.push_back(gene);
//        auto &conn = connectionList.back();

//        if (conn.sourceType == NEURON) {
//            conn.sourceNum %= p.maxNumberNeurons;
//        } else {
//            conn.sourceNum %= Sensor::NUM_SENSES;
//        }

//        if (conn.sinkType == NEURON) {
//            conn.sinkNum %= p.maxNumberNeurons;
//        } else {
//            conn.sinkNum %= Action::NUM_ACTIONS;
//        }
//    }
//}

}
