import java.util.Random;
import java.util.Optional;

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
  int genomeSize;
  Gene[] genes;

  Genome(int theLength) {
    this.genomeSize = theLength;
    this.genes = new Gene[genomeSize];
  }

  Genome(Gene[] genes) {
    this.genomeSize = genes.length;
    this.genes = genes;
  }

  Genome (String[] strGenes) {
    genes = new Gene[strGenes.length];
    for (int i = 0; i < strGenes.length; i++) {
      genes[i] = new Gene(strGenes[i]);
    }
  }

  public void randomize(Environment e) {
    genomeSize = (genomeSize == 0)?new Random().ints(1, e.genomeInitialRange[0], e.genomeInitialRange[1]).toArray()[0]:genomeSize;
    genes = new Gene[genomeSize];
    for (int i = 0; i< genomeSize; i++) {
      genes[i] = new Gene();
    }
  }

  public Gene[] getGenome() {
    return genes;
  }


  private void printGenome(Gene[] myGenome) {
    System.out.print("Genome = [");
    boolean sep = false;
    for (int i = 0; i < myGenome.length; i++) {
      System.out.print((sep?",":""));
      for (byte gene : myGenome[i].getBlueprint()) {
        System.out.print(String.format("%02X", gene));
      }
      sep = true;
    }
    System.out.println("]");
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
    System.out.println(getMethod());

    //testRandomGenome();
    //testOneGene();
    //testGetBits();
    testGene();
  }

  private void testGene() {
    //System.out.printf("Genome#%s\n", getMethod());
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


  private void testRandomGenome() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize);
    g.randomize(new Environment());
    Gene[] myGenome = g.getGenome();
    printGenome(myGenome);
  }

  private void testOneGene() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize);
    g.randomize(new Environment());
    Gene[] myGenome = g.getGenome();
    printGenome(myGenome);
    System.out.print("Gene = [");
    Gene gene = myGenome[0];
    for (byte thisGene : gene.getBlueprint()) {
      System.out.print(String.format("%02X", thisGene));
    }
    System.out.println("]");
  }

  private void testGetBits() {
    System.out.println(getMethod());
    int theSize = 10;
    Genome g = new Genome(theSize);
    g.randomize(new Environment());
    Gene[] myGenome = g.getGenome();
    printGenome(myGenome);
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

  private String byteToBinary(byte geneSlice) {
    return String.format("%8s", Integer.toBinaryString(geneSlice & 0xff)).replace(' ', '0');
  }
}
