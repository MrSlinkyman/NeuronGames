
void setup() {
  size(200,200);

  System.out.println( System.getProperty("java.version"));

  int population = 10;
  int[] world = new int[]{width, height};
  int steps = 300;
  int genome = 4;
  int innerNeurons = 1;

  Genome g = new Genome(population);
  g.allTests();

  Direction d = new Direction();
  d.allTests();
  

}
