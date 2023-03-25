import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

public class Signals {
  final int SIGNAL_MAX = 255; // UINT8_MAX is equal to 255
  final int SIGNAL_MIN = 0;

  public class Column {
    private List<Byte> data;

    public Column(int numRows) {
      data = new ArrayList<Byte>(Collections.nCopies(numRows, (byte) 0));
    }

    public byte get(int rowNum) {
      return data.get(rowNum);
    }

    public void set(int rowNum, byte value) {
      data.set(rowNum, value);
    }

    public void zeroFill() {
      Collections.fill(data, (byte) 0);
    }

    public String toString() {
      String r = "col(";
      boolean s = false;
      for (byte d : data) {
        r+= (s)?",":"";
        r+= String.format("%02x", d);
        s=true;
      }
      r+=")";
      r = String.format("col(%d)", data.size());
      return r;
    }
  }

  public class Layer {
    private List<Column> data;

    public Layer(int numCols, int numRows) {
      data = new ArrayList<Column>(Collections.nCopies(numCols, new Column(numRows)));
    }

    public Column get(int colNum) {
      return data.get(colNum);
    }

    public String toString() {
      String r = "layer(";
      boolean s = false;
      for (Column c : data) {
        r+= (s)?",":"";
        r+= String.format("%s", c);
        s=true;
      }
      r+=")";

      return r;
    }

    public void zeroFill() {
      for (Column col : data) {
        col.zeroFill();
      }
    }
  }

  private List<Layer> data;

  public String toString() {
    String r = "Signal(";
    for (Layer l : data) {
      r+= String.format("%s\n", l);
    }
    r+=")";
    return r;
  }

  public double getSignalDensity(int layerNum, Coordinate loc) {
    // returns magnitude of the specified signal layer in a neighborhood, with
    // 0.0..maxSignalSum converted to the sensor range.

    double signalSensorRadius = (double)Parameters.SIGNAL_SENSOR_RADIUS.getValue();
    int[] countLocs = {0};
    long[] sum = {0};
    Coordinate center = loc;

    Consumer<Coordinate> f = (tloc) -> {
      ++countLocs[0];
      sum[0] += getMagnitude(layerNum, tloc);
    };

    center.visitNeighborhood(signalSensorRadius, f);
    double maxSum = countLocs[0] * SIGNAL_MAX;
    double sensorVal = sum[0] / maxSum; // convert to 0.0..1.0

    return sensorVal;
  }

  public Signals initialize(int layers, int sizeX, int sizeY) {
    data = new ArrayList<Layer>(Collections.nCopies(layers, new Layer(sizeX, sizeY)));
    return this;
  }

  public Layer get(int layerNum) {
    return data.get(layerNum);
  }

  public byte getMagnitude(int layerNum, Coordinate loc) {
    return get(layerNum).get(loc.getX()).get(loc.getY());
  }

  public void increment(int layerNum, Coordinate loc) {
    final double radius = 1.5;
    final int centerIncreaseAmount = 2;
    final int neighborIncreaseAmount = 1;

    synchronized (this) {
      loc.visitNeighborhood(radius, (Coordinate coord) -> {
        if (data.get(layerNum).get(coord.getX()).get(coord.getY()) < SIGNAL_MAX) {
          data.get(layerNum).get(coord.getX()).set(coord.getY(),
            (byte)(Math.min(SIGNAL_MAX, data.get(layerNum).get(coord.getX()).get(coord.getY()) + neighborIncreaseAmount)));
        }
      }
      );

      if (data.get(layerNum).get(loc.getX()).get(loc.getY()) < SIGNAL_MAX) {
        data.get(layerNum).get(loc.getX()).set(loc.getY(),
          (byte)(Math.min(SIGNAL_MAX, data.get(layerNum).get(loc.getX()).get(loc.getY()) + centerIncreaseAmount)));
      }
    }
  }

  /** 
    *  Converts the signal density along the specified axis to sensor range. The
    * values of cell signal levels are scaled by the inverse of their distance times
    * the positive absolute cosine of the difference of their angle and the
    * specified axis. The maximum positive or negative magnitude of the sum is
    * about 2*radius*SIGNAL_MAX (?). We don't adjust for being close to a border,
    * so signal densities along borders and in corners are commonly sparser than
    * away from borders.
  */
  public double getSignalDensityAlongAxis(int layerNum, Coordinate loc, Direction dir) {

    assert !dir.equals(new Direction(Compass.CENTER)) :
    dir; // require a defined axis

    double signalSensorRadius = (double)Parameters.SIGNAL_SENSOR_RADIUS.getValue();
    double[] sum = {0.0};
    Coordinate dirVec = dir.asNormalizedCoordinate();
    double len = Math.sqrt(dirVec.getX() * dirVec.getX() + dirVec.getY() * dirVec.getY());
    double dirVecX = dirVec.getX() / len;
    double dirVecY = dirVec.getY() / len; // Unit vector components along dir

    Consumer<Coordinate> f = (tloc) -> {
      if (!tloc.equals(loc)) {
        Coordinate offset = tloc.subtract(loc);
        double proj = (dirVecX * offset.getX() + dirVecY * offset.getY()); // Magnitude of projection along dir
        double contrib = (proj * getMagnitude(layerNum, tloc)) /
          (offset.getX() * offset.getX() + offset.getY() * offset.getY());
        sum[0] += contrib;
      }
    };

    loc.visitNeighborhood(signalSensorRadius, f);

    double maxSumMag = 6.0 * signalSensorRadius * SIGNAL_MAX;
  assert sum[0] >= -maxSumMag && sum[0] <= maxSumMag :
    sum;
    double sensorVal = sum[0] / maxSumMag; // convert to -1.0..1.0
    sensorVal = (sensorVal + 1.0) / 2.0; // convert to 0.0..1.0

    return sensorVal;
  }


  public void zeroFill() {
    for (Layer layer : data) {
      layer.zeroFill();
    }
  }

  public void fade(int layerNum) {
    byte fadeAmount = 1;
    Layer layer = get(layerNum);
    for (int x = 0; x < (int)Configuration.SIZE_X.getValue(); x++) {
      for (int y = 0; y < (int)Configuration.SIZE_Y.getValue(); y++) {
        if (layer.get(x).get(y) >= fadeAmount) {
          layer.get(x).set(y, (byte)(layer.get(x).get(y)-fadeAmount));
        } else {
          layer.get(x).set(y, (byte)0);
        }
      }
    }
  }
}
