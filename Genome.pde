import java.util.Random;
import java.util.Optional;
import java.util.Arrays;
import java.util.function.BiConsumer;

/**
 * Genome
 * Structure: 8 hexadecimal digits
 * bits structure:
 * [from][to][weight]
 * * from/to = byte
 *          0 = source (input/internal or internal/output)
 *          1-7 = location (unsigned int mod # neurons)
 * * weight = short (divide to get small float around -4.0/4.0
 *
 * May use this only for testing, not for actual computation
 *
 */
class Genome {
  // TODO: Refactor with getter/setter
  Gene[] genes;

  Genome(int theLength) {
    this.genes = new Gene[theLength];
  }

  /**
   * Uses parents to intialize this child genome
   // This generates a child genome from one or two parent genomes.
   // If the parameter p.sexualReproduction is true, two parents contribute
   // genes to the offspring. The new genome may undergo mutation.
   // Must be called in single-thread mode between generations
   */
  Genome(List<Genome> parents) {
    assert parents.size()>1:
    String.format("Parents size:%d", parents.size());
    // random parent (or parents if sexual reproduction) with random
    // mutations
    Genome genome = new Genome(0);
    Random rando = new Random();
    int parent1Idx;
    int parent2Idx;

    // Choose two parents randomly from the candidates. If the parameter
    // p.chooseParentsByFitness is false, then we choose at random from
    // all the candidate parents with equal preference. If the parameter is
    // true, then we give preference to candidate parents according to their
    // score. Their score was computed by the survival/selection algorithm
    // in survival-criteria.cpp.
    if ((boolean)Parameters.CHOOSE_PARENTS_BY_FITNESS.getValue() && parents.size() > 1) {
      parent1Idx = rando.ints(1, 1, parents.size()).toArray()[0];
      parent2Idx = rando.nextInt(parent1Idx);
    } else {
      parent1Idx = rando.nextInt(parents.size());
      parent2Idx = rando.nextInt(parents.size());
    }

    assert parent1Idx < parents.size() :
    String.format("parent1Idx:%d, parents:%d", parent1Idx, parents.size());
    assert parent2Idx < parents.size() :
    String.format("parent2Idx:%d, parents:%d", parent2Idx, parents.size());

    final Genome g1 = parents.get(parent1Idx);
    final Genome g2 = parents.get(parent2Idx);

    assert !(g1.isEmpty() || g2.isEmpty()) :
    String.format("1 or both parents are empty: parent1:%s, parent2:%s", g1, g2);

    BiConsumer<Genome, Genome> overlayWithSliceOf = (Genome shorter, Genome longer) -> {
      int index0 = rando.nextInt(shorter.size()-1);
      int index1 = rando.nextInt(shorter.size());
      if (index0 > index1) {
        int temp = index0;
        index0 = index1;
        index1 = temp;
      }
      // TODO: find a better way to do this array copy
      // std::copy(gShorter.begin() + index0, gShorter.begin() + index1, genome.begin() + index0);
      /*
      This line is copying a subsequence of Genome shorter Genes to the Genome longer Genes, starting at index index0 and ending at index index1 - 1.
       
       Here's a breakdown of the arguments passed to System.arraycopy() function:
       
       shorter.genes, index0: The array to copy from starting at index0
       gShorter.begin() + index1: a pointer to the end of the subsequence in gShorter that we want to copy.
       genome.begin() + index0: a pointer to the location in genome where we want to start copying the subsequence.
       Overall, this line of code is used to overlay a random slice of one of the parent genomes onto the other genome during sexual reproduction.
       */
      System.arraycopy(shorter.genes, index0, longer.genes, index0, index1 - index0);
    };

    if ((boolean)Parameters.SEXUAL_REPRODUCTION.getValue()) {
      Genome shorter = new Genome((g1.size() > g2.size()?g2:g1).getGenome());
      genome = new Genome((g1.size() > g2.size()?g1:g2).getGenome());
      overlayWithSliceOf.accept(shorter, genome);
      assert !genome.isEmpty() :
      String.format("new sliced genome is empty source genomes: s:%s, l:%s", shorter, genome);

      int newGenomeLength = g1.size() + g2.size();
      newGenomeLength = newGenomeLength / 2 + ((newGenomeLength % 2 != 0 && rando.nextBoolean())? 1:0);
      genome.cropLength(newGenomeLength);
      assert !genome.isEmpty() :
      String.format("cropped genome is empty: desired length:%d", newGenomeLength);
    } else {
      genome = g2;
      assert !genome.isEmpty() :
      String.format("2nd parent was empty: 1st:%s", g1);
    }

    genome.randomInsertDeletion();
    assert !genome.isEmpty() :
    String.format("random insert/delete created an empty genome");
    genome.applyPointMutations();
    assert !genome.isEmpty() :
    String.format("Mutations produced empty genome");
    assert genome.size() <= (int)Parameters.GENOME_MAX_LENGTH.getValue() :
    String.format("new genome is too big:%d", genome.size());

    copyGenes(genome.genes);
  }

  Genome(Gene[] genes) {
    copyGenes(genes);
  }

  Genome (String[] strGenes) {
    genes = new Gene[strGenes.length];
    for (int i = 0; i < strGenes.length; i++) {
      genes[i] = new Gene(strGenes[i]);
    }
  }

  private void copyGenes(Gene[] genes) {
    this.genes = new Gene[genes.length];
    for (int i = 0; i < genes.length; i++) {
      this.genes[i] = new Gene(genes[i].getBlueprint());
    }
  }

  private void randomBitFlip() {
    int method = 1;
    Random rando = new Random();

    int byteIndex = rando.nextInt(genes[0].getBlueprint().length );
    int elementIndex = rando.nextInt(genes.length);
    byte[] randoBytes = new byte[1];
    rando.nextBytes(randoBytes);
    byte bitIndex8 = (byte)(1 << randoBytes[0]);

    if (method == 0) {
      genes[0].getBlueprint()[byteIndex] ^= bitIndex8;
      genes[0] = new Gene(genes[0].getBlueprint());
    } else if (method == 1) {
      double chance = rando.nextDouble();
      Gene targetGene = genes[elementIndex];
      if (chance < 0.2) { // sourceType
        targetGene.setSensor(targetGene.getSensor() == NeuronType.SENSOR?NeuronType.NEURON:NeuronType.SENSOR);
      } else if (chance < 0.4) { // sinkType
        targetGene.setTarget(targetGene.target == NeuronType.NEURON?NeuronType.ACTION:NeuronType.NEURON);
      } else if (chance < 0.6) { // sourceNum
        targetGene.setSensorSource((short)Math.abs(targetGene.getSensorSource() ^ bitIndex8));
      } else if (chance < 0.8) { // sinkNum
        targetGene.setTargetSource((short)Math.abs(targetGene.getTargetSource() ^ bitIndex8));
      } else { // weight

        targetGene.weight ^= (1 << rando.ints(1, 1, 15).toArray()[0]);
      }
    } else {
    assert false :
      String.format("Method specified is invalid:%d", method);
    }
  }

  void cropLength(int newGeneLength) {
  assert newGeneLength > 0 :
    String.format("Cripping to a bad length:%d, original length", newGeneLength, size());
    if (genes.length > newGeneLength) {
      genes = (new Random().nextBoolean())?
        Arrays.copyOfRange(genes, genes.length - newGeneLength, genes.length) :
        Arrays.copyOfRange(genes, 0, newGeneLength);
    }
  }

  public void applyPointMutations() {
    Random rando = new Random();
    int numberOfGenes = genes.length;
    while (numberOfGenes-- > 0) {
      if (rando.nextDouble() < (double)Parameters.POINT_MUTATION_RATE.getValue()) {
        randomBitFlip();
      }
    }
  }
  void randomInsertDeletion() {
    Random rando = new Random();
    double probability = (double)Parameters.GENE_INSERTION_DELETION_RATE.getValue();
    if (rando.nextDouble() < probability) {
      if (rando.nextDouble() < (double)Parameters.DELETION_RATIO.getValue()) {
        // deletion
        if (genes.length > 1) {
          int indexToRemove = rando.nextInt(genes.length);
          Gene[] newGenes = new Gene[genes.length - 1];
          for (int i = 0, newIndex = 0; i < genes.length; i++) {
            if (i != indexToRemove) {
              newGenes[newIndex++] = genes[i];
            }
          }
          genes = newGenes;
        }
      } else if (genes.length < (int)Parameters.GENOME_MAX_LENGTH.getValue()) {
        // insertion
        int indexToInsert = rando.nextInt(genes.length);
        Gene[] newGenes = new Gene[genes.length + 1];
        int newIndex = 0;
        for (int i = 0; i < genes.length; i++) {
          if (i == indexToInsert) {
            newGenes[newIndex++] = new Gene();
          }
          newGenes[newIndex++] = genes[i];
        }
        if (indexToInsert == genes.length) {
          newGenes[newIndex] = new Gene();
        }
        genes = newGenes;
      }
    }
  }

  public int size() {
    return (genes == null) ? 0 : genes.length;
  }

  public boolean isEmpty() {
    return genes == null || genes.length == 0;
  }

  public Genome randomize(int minGenomeSize, int maxGenomeSize) {
    // we add 1 to the max side of the genome range since the random ints used here is inclusize min, exclusive max
    int genomeSize = (genes == null || genes.length == 0)?new Random().ints(1, minGenomeSize, maxGenomeSize+1).toArray()[0]:genes.length;
    genes = new Gene[genomeSize];
    for (int i = 0; i< genomeSize; i++) {
      genes[i] = new Gene();
    }
    return this;
  }

  public Gene[] getGenome() {
    return genes;
  }

  public String toString() {
    String str = "Genome:[";
    boolean sep = false;
    if (genes != null) {
      for (int i = 0; i < genes.length; i++) {
        str += (sep?",":"");
        for (byte gene : genes[i].getBlueprint()) {
          str += String.format("%02X", gene);
        }
        sep = true;
      }
    }
    str +="]";
    return str;
  }

  /**
   * @return 0.0 ... 1.0 where 0.0 is most similar, 1.0 is least similar.
   */
  public double similarity(Genome comparison) {
    switch ((int)Parameters.GENOME_COMPARISON_METHOD.getValue()) {
    case 0:
      return jaroWinklerDistance(comparison);
      //case 1:
      //    return hammingDistanceBits(comparison);
      //case 2:
      //    return hammingDistanceBytes(comparison);
    default:
      throw new AssertionError("Invalid genome comparison method");
    }
  }

  private void printGenome() {
    System.out.print(toString());
  }

  private byte[] extractBytesFromGenome() {
    List<byte[]> blueprintList = new ArrayList<>();

    for (Gene gene : genes) {
      blueprintList.add(gene.getBlueprint());
    }

    int totalLength = blueprintList.stream().mapToInt(b -> b.length).sum();
    byte[] allBytes = new byte[totalLength];

    int destPos = 0;
    for (byte[] blueprint : blueprintList) {
      System.arraycopy(blueprint, 0, allBytes, destPos, blueprint.length);
      destPos += blueprint.length;
    }

    return allBytes;
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

  /**
   * The jaro_winkler_distance() function is adapted from the C version at
   * https://github.com/miguelvps/c/blob/master/jarowinkler.c
   * under a GNU license, ver. 3. This comparison function is useful if
   * the simulator allows genomes to change length, or if genes are allowed
   * to relocate to different offsets in the genome. I.e., this function is
   * tolerant of gaps, relocations, and genomes of unequal lengths.
   * @return 0.0...1.0, where 0 is most similar, 1 is least similar.
   */
  private double jaroWinklerDistance(Genome genome2) {
    int maxNumGenesToCompare = 20;
    double distance = 0;
    double matchingGenes = 0;
    double transpositions = 0;

    double thisLength = Math.min(maxNumGenesToCompare, size());
    boolean[] thisFlags = new boolean[(int)thisLength];

    double thatLength = Math.min(maxNumGenesToCompare, genome2.size());
    boolean[] thatFlags = new boolean[(int)thatLength];

    double range = Math.max(0, Math.max(thisLength, thatLength) / 2 - 1);

    if (thisLength == 0 || thatLength == 0) {
      return 0.0;
    }

    /* calculate matching characters */
    for (int i = 0; i < thatLength; i++) {
      for (int j = (int)Math.max(i - range, 0), l = (int)Math.min(i + range + 1, thisLength); j < l; j++) {
        if (getGenome()[j].matches(genome2.getGenome()[i]) && !thisFlags[j]) {
          thisFlags[j] = true;
          thatFlags[i] = true;
          matchingGenes++;
          break;
        }
      }
    }

    if (matchingGenes == 0) {
      return 0.0;
    }

    /* calculate character transpositions */
    int l = 0, j;
    for (int i = 0; i < thatLength; i++) {
      if (thatFlags[i]) {
        for (j = l; j < thisLength; j++) {
          if (thisFlags[j]) {
            l = j + 1;
            break;
          }
        }
        if (!genome2.getGenome()[i].matches(getGenome()[j])) {
          transpositions++;
        }
      }
    }
    transpositions /= 2;

    /* Jaro distance */
    distance = ((matchingGenes / thisLength) + (matchingGenes / thatLength) + ((matchingGenes - transpositions) / matchingGenes)) / 3.0;

    return distance;
  }

  // ** TESTS **
  public void allTests() {
    System.out.println(getMethod());

    //testRandomGenome();
    //testOneGene();
    //testGetBits();
    //testGene();
    //testComparison();
    testGenomeToNN();
  }

  private void testGene() {
    System.out.println(getMethod());
    //System.out.println("Genome#testGene");
    String[] geneSequence = new String[]{"A255F53E", "8900EAB5", "C7DF9839", "2EACFE29", "248CBD38", "5C48D28C", "CAF57482", "CDDA0568", "E732A21B", "FEE9888B"};
    Genome g = new Genome(geneSequence);
    Gene[] myGenome = g.getGenome();
    //printGenome(myGenome);
    byte[] thisGene = myGenome[0].getBlueprint();
    assert String.format("%02X", thisGene[0]).equals(geneSequence[0].substring(0, 2)):
    String.format("%02X", thisGene[0]);
    assert (int)(thisGene[0] & 0xFF) == 162 :
    String.format("%02X{%s} is %d", thisGene[0], byteToBinary(thisGene[0]), thisGene[0] & 0xFF);
    assert (int)(thisGene[0] & 0x7F) == 34  :
    String.format("%s is %d", byteToBinary(thisGene[0]).substring(1, 8), thisGene[0] & 0x7F);
    assert (int)(thisGene[0] & 0x80) == 128 :
    String.format("%8s is %d", byteToBinary(thisGene[0]).substring(0, 1)+"0000000", thisGene[0] & 0x80);

    assert "10100010".equals(byteToBinary(thisGene[0])):
    byteToBinary(thisGene[0]);
    assert "01010101".equals(byteToBinary(thisGene[1])):
    byteToBinary(thisGene[1]);
    assert -2754 == (short)(((thisGene[2] & 0xFF) <<8) | (thisGene[3] & 0xFF)):
    (short)(((thisGene[2] & 0xFF) <<8) | (thisGene[3] & 0xFF));


    thisGene = myGenome[1].getBlueprint();
    assert String.format("%02X", thisGene[0]).equals(geneSequence[1].substring(0, 2));
    assert (int)(thisGene[0] & 0xFF) == 137 :
    String.format("%02X{%s} is %d", thisGene[0], byteToBinary(thisGene[0]), thisGene[0] & 0xFF);
    assert (int)(thisGene[0] & 0x7F) == 9  :
    String.format("%s is %d", byteToBinary(thisGene[0]).substring(1, 8), thisGene[0] & 0x7F);
    assert (int)(thisGene[0] & 0x80) == 128 :
    String.format("%8s is %d", byteToBinary(thisGene[0]).substring(0, 1)+"0000000", thisGene[0] & 0x80);

    assert "10001001".equals(byteToBinary(thisGene[0])):
    byteToBinary(thisGene[0]);
    assert "00000000".equals(byteToBinary(thisGene[1])):
    byteToBinary(thisGene[1]);
    assert -5451 == (short)(((thisGene[2] & 0xFF) <<8) | (thisGene[3] & 0xFF)):
    (short)(((thisGene[2] & 0xFF) <<8) | (thisGene[3] & 0xFF));
  }

  private void testComparison() {
    Genome g1 = new Genome(new String[]{"A255F53E", "8900EAB5", "C7DF9839", "2EACFE29", "248CBD38", "5C48D28C", "CAF57482", "CDDA0568", "E732A21B", "FEE9888B"});
    Genome g2 = new Genome(new String[]{"8900FAB5", "C7DF9839", "2EACFE29", "248CBD38", "5C48D28C", "CAF57482", "CDDA0568", "E732A21B", "FEE9888B"});
    double similarity = g1.similarity(g2);
  assert similarity != 0:
    similarity;
  }


  private void testRandomGenome() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize).randomize(4, 12);
    //Gene[] myGenome = g.getGenome();
    g.printGenome();
  }

  private void testOneGene() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize).randomize(4, 12);
    Gene[] myGenome = g.getGenome();
    g.printGenome();
    System.out.print("Gene = [");
    Gene gene = myGenome[0];
    for (byte thisGene : gene.getBlueprint()) {
      System.out.printf("%02X", thisGene);
    }
    System.out.println("]");
  }

  private void testGetBits() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize).randomize(4, 12);
    Gene[] myGenome = g.getGenome();
    g.printGenome();
    Gene gene = myGenome[0];
    System.out.print("Gene = [");
    for (byte thisGene : gene.getBlueprint()) {
      System.out.printf("%02X{%s}", thisGene, byteToBinary(thisGene));
    }
    System.out.println("]");

    System.out.println("Gene:");
    System.out.printf("   Source(%s)\n", byteToBinary(gene.getBlueprint()[0]));
    System.out.printf("   Target(%s)\n", byteToBinary(gene.getBlueprint()[1]));
    System.out.printf("   Weight(%8d)\n", (short)(((gene.getBlueprint()[2] & 0xFF) <<8) | (gene.getBlueprint()[3] & 0xFF) ));

    System.out.println("gene[0]:all: "+Integer.toString(gene.getBlueprint()[0] & 0xFF));
    System.out.println("gene[0]:7digits: "+Integer.toString(gene.getBlueprint()[0] & 0x7F));
    System.out.println("gene[0]:1digit: "+Integer.toString(gene.getBlueprint()[0] & 0x80));
  }

  private void testGenomeToNN() {

    String[] geneSequence = new String[]{"01081EE4", "00817024", "93811602", "010DAFB1", "8608DEE9", "008382A0"};
    Genome g = new Genome(geneSequence);
    //Gene[] myGenome = g.getGenome();
    System.out.printf("My Genome:%s\n", g);
  }

  private String byteToBinary(byte geneSlice) {
    return String.format("%8s", Integer.toBinaryString(geneSlice & 0xff)).replace(' ', '0');
  }
}
